local state = require("state")
local time = require("time")

describe("state.to_timesheet_csv", function()
  it("should return header for empty state", function()
    local result = state.to_timesheet_csv({})
    assert.are.equal("Workspace,Tab,Pane,Time,Breaks\n", result)
  end)

  it("should return header for nil state", function()
    local result = state.to_timesheet_csv(nil)
    assert.are.equal("Workspace,Tab,Pane,Time,Breaks\n", result)
  end)

  it("should format single pane correctly", function()
    local test_state = {
      {
        workspace = "np",
        tab = "Editor",
        name = "Editor",
        tt = 10800, -- 3 hours in seconds
        ttb = 3600, -- 1 hour in seconds
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    assert.are.equal("Workspace,Tab,Pane,Time,Breaks", lines[1])
    assert.are.equal("np,Editor,Editor,03:00,01:00", lines[2])
    assert.are.equal(",,,,", lines[3]) -- blank before tab aggregate
    assert.are.equal(",Editor,,03:00,01:00", lines[4]) -- tab aggregate
    assert.are.equal(",,,,", lines[5]) -- blank before workspace aggregate
    assert.are.equal("np,,,03:00,01:00", lines[6]) -- workspace aggregate
    assert.are.equal(",,,,", lines[7]) -- blank before grand total
    assert.are.equal("Grand Total,,,03:00,01:00", lines[8]) -- grand total
  end)

  it("should sort by workspace, tab, and name", function()
    local test_state = {
      {
        workspace = "beta",
        tab = "Tab1",
        name = "PaneB",
        tt = 3600,
        ttb = 600,
      },
      {
        workspace = "alpha",
        tab = "Tab2",
        name = "PaneA",
        tt = 7200,
        ttb = 1200,
      },
      {
        workspace = "alpha",
        tab = "Tab1",
        name = "PaneC",
        tt = 1800,
        ttb = 300,
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    -- Should be sorted: alpha/Tab1/PaneC, alpha/Tab2/PaneA, beta/Tab1/PaneB
    -- Structure: pane row, blank, tab agg, pane row (no ws), blank, tab agg, blank, ws agg, pane row, blank, tab agg, blank, ws agg, blank, grand total
    assert.are.equal("alpha,Tab1,PaneC,00:30,00:05", lines[2])
    assert.are.equal(",Tab2,PaneA,02:00,00:20", lines[5]) -- workspace suppressed
    assert.are.equal("beta,Tab1,PaneB,01:00,00:10", lines[10])
  end)

  it("should suppress repeated workspace and tab labels", function()
    local test_state = {
      {
        workspace = "np",
        tab = "Editor",
        name = "Pane1",
        tt = 3600,
        ttb = 600,
      },
      {
        workspace = "np",
        tab = "Editor",
        name = "Pane2",
        tt = 3600,
        ttb = 600,
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    -- First row shows workspace and tab
    assert.are.equal("np,Editor,Pane1,01:00,00:10", lines[2])
    -- Second row suppresses workspace and tab
    assert.are.equal(",,Pane2,01:00,00:10", lines[3])
  end)

  it("should aggregate correctly for multiple panes in same tab", function()
    local test_state = {
      {
        workspace = "np",
        tab = "Editor",
        name = "Pane1",
        tt = 3600,
        ttb = 600,
      },
      {
        workspace = "np",
        tab = "Editor",
        name = "Pane2",
        tt = 3600,
        ttb = 600,
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    -- Tab aggregate should sum both panes
    assert.are.equal(",Editor,,02:00,00:20", lines[5])
  end)

  it("should aggregate correctly for multiple tabs in same workspace", function()
    local test_state = {
      {
        workspace = "np",
        tab = "Editor",
        name = "Pane1",
        tt = 3600,
        ttb = 600,
      },
      {
        workspace = "np",
        tab = "Terminal",
        name = "Pane2",
        tt = 7200,
        ttb = 1200,
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    -- Find workspace aggregate line
    local workspace_agg = nil
    for _, line in ipairs(lines) do
      if line:match("^np,,,") then
        workspace_agg = line
        break
      end
    end

    assert.are.equal("np,,,03:00,00:30", workspace_agg)
  end)

  it("should handle panes with fallback ID fields", function()
    local test_state = {
      {
        _workspace_id = "legacy_ws",
        _tab_id = 1,
        name = "LegacyPane",
        tt = 1800,
        ttb = 300,
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    assert.are.equal("legacy_ws,1,LegacyPane,00:30,00:05", lines[2])
  end)

  it("should handle zero and nil values gracefully", function()
    local test_state = {
      {
        workspace = "test",
        tab = "tab",
        name = "pane",
        -- tt and ttb are nil
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    assert.are.equal("test,tab,pane,00:00,00:00", lines[2])
  end)

  it("should calculate grand total correctly", function()
    local test_state = {
      {
        workspace = "ws1",
        tab = "tab1",
        name = "pane1",
        tt = 3600,
        ttb = 600,
      },
      {
        workspace = "ws2",
        tab = "tab2",
        name = "pane2",
        tt = 7200,
        ttb = 1200,
      },
    }

    local result = state.to_timesheet_csv(test_state)
    local lines = {}
    for line in result:gmatch("[^\n]+") do
      table.insert(lines, line)
    end

    -- Last line should be grand total
    assert.are.equal("Grand Total,,,03:00,00:30", lines[#lines])
  end)
end)
