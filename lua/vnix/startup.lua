local wezterm = require("wezterm")
local mux = require("vnix.mux")
local config = require("vnix.config")
local vnix = wezterm.GLOBAL.vnix
local interval = 0.1 -- seconds
local state = require("vnix.state")

---@class VnixStartupMod
---@field gui_startup fun(): nil
---@field restore fun(cfg: VnixSpecs, _next: number?): nil
local M = {} ---@type VnixStartupMod

function M.gui_startup()
  if vnix and vnix.is_ready then
    local specs = config.load() ---@type VnixSpecs
    M.restore(specs)
  else
    wezterm.time.call_after(interval, M.gui_startup)
  end
end

---@param arg VnixSpecs
function M.restore(arg)
  local nvim_cmd = "vnix-nvim +'Vnix setup'"

  -- FIXME: Accept the shell cmd overrides from user
  -- Detect if the shell is fish
  local is_fish = string.find(vnix.shell, "fish") ~= nil

  -- Choose the correct infinite loop syntax
  local loop_cmd
  if is_fish then
    loop_cmd = string.format("while true; %s; end", nvim_cmd)
  else
    loop_cmd = string.format("while true; do %s; done", nvim_cmd)
  end

  local vnix_workspace = {
    name = "___vnix___",
    cwd = vnix.vnix_dir,
    env = {
      VNIX = "VNIX",
      VNIX_DIR = vnix.vnix_dir,
    },
    tabs = {
      {
        name = "___vnix___",
        pane = {
          name = "___vnix___",
          args = { vnix.shell, "-l", "-c", loop_cmd },
        },
      },
    },
  }

  local _, win = mux.create_workspace(vnix_workspace)
  mux.await_gui_window(win, function(gui_window)
    vnix._window_id = gui_window:window_id()
    gui_window:maximize()

    local workspaces = {}
    for _, w in ipairs(arg.workspaces) do
      local workspace = mux.create_workspace(w)
      table.insert(workspaces, workspace)
    end

    vnix.runtime.workspaces = workspaces
    M._notify()
  end)
end

function M._notify()
  if not vnix._window_id then
    wezterm.time.call_after(1, M._notify)
    return
  end

  local id = nil

  --- Lookup last known pane and switch to it
  if vnix.runtime and vnix.runtime.active_pane then
    local ap = vnix.runtime.active_pane
    if ap then
      local pane = state.find_pane_by_names(ap.workspace, ap.tab, ap.name)
      if pane then
        id = pane.id
      end
    end
  end

  local pane = state.find_pane_by_id(id, function(_, _, workspace)
    return workspace.name ~= "__vnix__"
  end)

  if pane then
    local gui_win = nil ---@type Window
    for _, w in ipairs(wezterm.gui.gui_windows()) do
      if w:is_focused() then
        gui_win = w
        break
      end
    end

    if gui_win then
      gui_win:perform_action(
        wezterm.action.SwitchToWorkspace({
          name = pane.workspace,
        }),
        gui_win:active_pane()
      )

      local pane_obj = mux.find_pane(pane.id)
      if pane_obj then
        pane_obj:activate()
      end

      wezterm.time.call_after(0, function()
        wezterm.emit("vnix:state-update", gui_win, "init")
      end)
    end
  end
end

return M
