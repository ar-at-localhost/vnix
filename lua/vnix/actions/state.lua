local wezterm = require("wezterm")
local state = require("vnix.state")
local mux = wezterm.mux
local vnix = wezterm.GLOBAL.vnix
local events = require("vnix.events")
local rpc = require("vnix.rpc")

---@class PaneInformation
---@field pane Pane
---@field index number

---@class StateActionsMod
---@field reset_panes_info fun(workspace: string, tab: MuxTab, tab_idx?: integer): nil
---@field reset_all_panes_info fun(): nil
---@field reset_flat_state fun(): nil
local _M = {} ---@type StateActionsMod

events.make_event(
  "vnix:persist",
  ---Callback
  ---@param win Window
  ---@param pane Pane
  ---@param kind ('primary' | 'secondary')?
  function(win, pane, kind)
    if not kind then
      kind = "secondary"
    end

    rpc.dispatch(
      win,
      pane,
      ---@type UIMessagePersistReq
      {
        type = "persist",
        id = 0,
        return_to = 0,
        timestamp = "",
        workspace = "",
        data = kind == "primary" and vnix.specs_file_primary or vnix.specs_file_secondary,
      }
    )
  end
)

function _M.reset_all_panes_info()
  local workspaces = state:get_workspaces()
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
      for i, t in ipairs(w:tabs()) do
        _M.reset_panes_info(wo.name, t, i - 1)
      end
    end
  end
end

function _M.reset_panes_info(workspace_name, tab, tab_idx)
  local workspace, _ = state:find_workspace_by_name(workspace_name)
  if not workspace then
    return
  end

  local tab_id = tab:tab_id()
  local tab_name = tab:get_title()
  local tab_state = state:find_tab_by_id(workspace, tab_id)
  if not tab_state then
    return
  end

  local panes = tab:panes_with_info()

  if tab_idx then
    tab_state.idx = tab_idx
  end

  state:traverse_pane(tab_state.pane, function(item)
    for _, v in ipairs(panes) do
      if v.pane:pane_id() == item.id then
        item.idx = v.index
        item.workspace = workspace_name
        item.tab = tab_name

        item.size = {
          width = v.width,
          height = v.height,
        }

        if tab_idx then
          item.tab_idx = tab_idx
        end
      end
    end
  end)
end

return _M
