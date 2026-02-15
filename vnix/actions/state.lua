local wezterm = require("wezterm")
local state = require("vnix.state")
local activity = require("vnix.activity")
local mux = wezterm.mux
local vnix = wezterm.GLOBAL.vnix

---@class PaneInformation
---@field pane Pane
---@field index number

---@class StateActionsMod
---@field reset_panes_info fun(workspace: string, tab: MuxTab): nil
---@field reset_all_panes_info fun(): nil
---@field reset_flat_state fun(): nil
local _M = {} ---@type StateActionsMod

wezterm.on(
  "vnix:state-update",
  ---cb
  ---@param win Window
  ---@param trigger_type 'init'| 'constructive' | 'effective' | nil
  function(win, trigger_type)
    local pane ---@type Pane
    local current_state = vnix.activity.active_pane

    if current_state then
      pane = mux.get_pane(current_state.id)
      if not pane then
        state.remove_pane(current_state)
        vnix.activity.active_pane = nil
      end
    end

    local workspace = win:active_workspace()
    local tab = win:active_tab()
    pane = win:active_pane()
    local found_pane = state.find_pane(workspace, tab:tab_id(), pane:pane_id())

    if found_pane then
      activity.set_focused_pane(found_pane)
    end

    pcall(function()
      if
        trigger_type == "init"
        or trigger_type == "constructive"
        or trigger_type == "effective"
      then
        _M.reset_flat_state()

        if trigger_type == "init" then
          _M.reset_all_panes_info()
        else
          _M.reset_panes_info(workspace, tab)
        end
      elseif trigger_type == "constructive" then
        _M.reset_panes_info(workspace, tab)
      end
    end)

    pcall(function()
      local fs = require("vnix.fs")
      fs.write_json(vnix.vnix_dir .. "/activity.json", vnix.activity)
      fs.write_json(vnix.vnix_dir .. "/panes.json", vnix.state_flat)
    end)

    wezterm.emit("vnix:update-status", win, pane)
  end
)

function _M.reset_all_panes_info()
  local workspaces = state.get_workspaces()
  local windows = mux.all_windows()
  for _, wo in ipairs(workspaces) do
    local w ---@type MuxWindow

    for _, wi in ipairs(windows) do
      if wi:get_workspace() == wo.name then
        w = wi
        break
      end
    end

    if w then
      for _, t in ipairs(w:tabs()) do
        _M.reset_panes_info(wo.name, t)
      end
    end
  end
end

function _M.reset_panes_info(workspace_name, tab)
  local workspace, _ = state.find_workspace_by_name(workspace_name)
  if not workspace then
    return
  end

  local tab_id = tab:tab_id()
  local tab_state = state.find_tab_by_id(workspace, tab_id)
  if not tab_state then
    return
  end

  local panes = tab:panes_with_info()
  state.traverse_pane(tab_state.pane, function(item)
    for _, v in ipairs(panes) do
      if v.pane:pane_id() == item.id then
        item.idx = v.index
        item.size = {
          width = v.width,
          height = v.height,
        }
      end
    end
  end)
end

function _M.reset_flat_state()
  local out = {} ---@type VnixStateFlat

  state.traverse_all_panes(function(pane, tab, workspace)
    ---@type VnixStateFlatEntry
    local entry = {
      pane_id = pane.id,
      pane_idx = pane.idx,
      pane_name = pane.name,
      tab_id = tab.id,
      tab_idx = tab.idx,
      tab_name = tab.name,
      workspace = workspace.name,
      cwd = pane.cwd or tab.cwd or workspace.cwd,
      meta = pane.meta,
    }

    table.insert(out, entry)
  end)

  vnix.state_flat = out
end

return _M
