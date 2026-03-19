local wezterm = require("wezterm")
local common = require("common")
local switch_actions = require("vnix.actions.switch")
local mux = require("vnix.mux")
local config = require("vnix.config")
local state = require("vnix.state")
local interval = 0.1 -- seconds
local vnix = wezterm.GLOBAL.vnix

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
  local nvim_cmd = string.format([[vnix-nvim --listen %s +'Vnix setup']], vnix.runtime.sock_path)

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

  local vnix_id = common.vnix_token

  local vnix_workspace = {
    name = vnix_id,
    cwd = vnix.vnix_dir,
    env = {
      VNIX = "VNIX",
      VNIX_DIR = vnix.vnix_dir,
    },
    tabs = {
      {
        name = vnix_id,
        pane = {
          name = vnix_id,
          args = { vnix.shell, "-l", "-c", loop_cmd },
        },
      },
    },
  }

  pcall(function()
    -- auto start procs which are enabled for autostart.
    if arg.procs then
      vnix.runtime.procs = arg.procs
      for _, proc in ipairs(vnix.runtime.procs) do
        proc.id = string.format("%s/%s", vnix_id, proc.title):lower()
        proc.status = "ready"
        proc.workspace = vnix_id

        if proc.autostart then
          table.insert(vnix_workspace.tabs, {
            name = proc.title,
            pane = {
              name = proc.title,
              cwd = proc.cwd,
              args = wezterm.shell_split(proc.cmd),
            },
          })
        end
      end
    end
  end)

  local vnix_workspace_state, win = mux.create_workspace(vnix_workspace)
  vnix.nvim = vnix_workspace_state.tabs[1]

  if win then
    mux.await_gui_window(win, function(gui_window)
      vnix._window_id = gui_window:window_id()
      gui_window:maximize()
      local cfg = gui_window:effective_config()
      if cfg then
        vnix.palette = cfg.resolved_palette
      end

      local workspaces = {}
      for wi, w in ipairs(arg.workspaces) do
        local workspace = mux.create_workspace(w, false, wi)
        table.insert(workspaces, workspace)
      end

      vnix.runtime.workspaces = workspaces
      M._notify()
    end)
  end
end

function M._notify()
  if not vnix._window_id then
    wezterm.time.call_after(1, M._notify)
    return
  end

  local gui_win = mux.resolve_gui_window(common.vnix_token)
  local pane = nil

  --- Lookup last known pane and switch to it
  if vnix.runtime and vnix.runtime.active_pane then
    local ap = vnix.runtime.active_pane
    if ap then
      pane = state.find_pane_by_names(ap.workspace, ap.tab, ap.name)
    end
  end

  if gui_win then
    switch_actions.switch_to_pane_action(gui_win, pane)
  end

  wezterm.emit("vnix:state-update", gui_win, "init")
  if gui_win then
    wezterm.emit("vnix:procs-refresh", gui_win, gui_win:active_pane())
  end
end

return M
