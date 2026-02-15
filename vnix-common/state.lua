---@class StateUtils
---@field to_timesheet_csv fun(state: PaneState[]): string
local M = {} ---@type StateUtils

local time = require("vnix-common.time")

-- ---------------------------------------
-- Helpers
-- ---------------------------------------

---@param state PaneState[]
local function sort_state(state)
  table.sort(state, function(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
      return type(a) == "table"
    end

    -- 1️⃣ Workspace (string)
    local aw, bw = a.workspace, b.workspace
    if aw ~= bw then
      if type(aw) ~= "string" then
        return false
      end
      if type(bw) ~= "string" then
        return true
      end
      return aw < bw
    end

    -- 2️⃣ Tab (string)
    local at, bt = a.tab, b.tab
    if at ~= bt then
      if type(at) ~= "string" then
        return false
      end
      if type(bt) ~= "string" then
        return true
      end
      return at < bt
    end

    -- 3️⃣ Pane name (string)
    local ap, bp = a.name, b.name
    if ap ~= bp then
      if type(ap) ~= "string" then
        return false
      end
      if type(bp) ~= "string" then
        return true
      end
      return ap < bp
    end

    return false
  end)
end

---@param state PaneState[]
---@return table<string, table<string, {tt:number, ttb:number}>>, table<string, {tt:number, ttb:number}>, {tt:number, ttb:number}
local function aggregate(state)
  ---@type table<string, table<string, {tt:number, ttb:number}>>
  local tab_totals = {}
  ---@type table<string, {tt:number, ttb:number}>
  local workspace_totals = {}
  local grand_total = { tt = 0, ttb = 0 }

  for _, pane in ipairs(state) do
    local ws = pane.workspace or pane._workspace_id
    local tab = pane.tab or pane._tab_id
    local tt = pane.tt or 0
    local ttb = pane.ttb or 0

    -- Tab total (keyed by tab name string)
    tab_totals[ws] = tab_totals[ws] or {}
    tab_totals[ws][tab] = tab_totals[ws][tab] or { tt = 0, ttb = 0 }
    tab_totals[ws][tab].tt = tab_totals[ws][tab].tt + tt
    tab_totals[ws][tab].ttb = tab_totals[ws][tab].ttb + ttb

    -- Workspace total (keyed by workspace name string)
    workspace_totals[ws] = workspace_totals[ws] or { tt = 0, ttb = 0 }
    workspace_totals[ws].tt = workspace_totals[ws].tt + tt
    workspace_totals[ws].ttb = workspace_totals[ws].ttb + ttb

    -- Grand total
    grand_total.tt = grand_total.tt + tt
    grand_total.ttb = grand_total.ttb + ttb
  end

  return tab_totals, workspace_totals, grand_total
end

-- ---------------------------------------
-- Public API
-- ---------------------------------------

---@param state PaneState[]
---@return string
function M.to_timesheet_csv(state)
  if not state or #state == 0 then
    return "Workspace,Tab,Pane,Time,Breaks\n"
  end

  -- Copy to avoid mutation
  local sorted = {}
  for i, v in ipairs(state) do
    sorted[i] = v
  end

  sort_state(sorted)
  local tab_totals, workspace_totals, grand_total = aggregate(sorted)

  local lines = {}
  table.insert(lines, "Workspace,Tab,Pane,Time,Breaks")

  local current_ws = nil
  local current_tab = nil

  for i, pane in ipairs(sorted) do
    local ws = pane.workspace or pane._workspace_id
    local tab = pane.tab or pane._tab_id
    local pane_name = pane.name
    local tt = pane.tt or 0
    local ttb = pane.ttb or 0

    local ws_display = ws
    local tab_display = tostring(tab)

    -- Suppress repeated labels
    if current_ws == ws then
      ws_display = ""
    end
    if current_tab == tab then
      tab_display = ""
    end

    -- Pane row
    table.insert(
      lines,
      string.format(
        "%s,%s,%s,%s,%s",
        ws_display,
        tab_display,
        pane_name or "",
        time.format_hhmm(tt),
        time.format_hhmm(ttb)
      )
    )

    current_ws = ws
    current_tab = tab

    -- Check next row
    local next_pane = sorted[i + 1]
    local next_tab = next_pane and (next_pane.tab or next_pane._tab_id)
    local next_ws = next_pane and (next_pane.workspace or next_pane._workspace_id)

    -- Flush tab total if tab changes or last row
    -- Insert blank line, then aggregate row: empty workspace, tab name, empty pane, tt, ttb
    if tab ~= next_tab then
      local t_tot = tab_totals[ws][tab]
      table.insert(lines, ",,,,") -- blank line before aggregate
      table.insert(
        lines,
        string.format(",%s,,%s,%s", tab, time.format_hhmm(t_tot.tt), time.format_hhmm(t_tot.ttb))
      )
    end

    -- Flush workspace total if workspace changes or last row
    -- Insert blank line, then aggregate row: workspace name, empty tab/pane, tt, ttb
    if ws ~= next_ws then
      local w_tot = workspace_totals[ws]
      table.insert(lines, ",,,,") -- blank line before aggregate
      table.insert(
        lines,
        string.format("%s,,,%s,%s", ws, time.format_hhmm(w_tot.tt), time.format_hhmm(w_tot.ttb))
      )
      table.insert(lines, "") -- blank row after workspace total
    end
  end

  -- Grand total
  table.insert(lines, ",,,,") -- blank line before grand total
  table.insert(
    lines,
    string.format(
      "Grand Total,,,%s,%s",
      time.format_hhmm(grand_total.tt),
      time.format_hhmm(grand_total.ttb)
    )
  )

  return table.concat(lines, "\n")
end

return M
