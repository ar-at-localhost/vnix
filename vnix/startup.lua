local wezterm = require("wezterm")
local mux = require("vnix.mux")
local config = require("vnix.config")
local state = require("vnix.state")
local vnix = wezterm.GLOBAL.vnix
local interval = 0.1 -- seconds

---@class VnixStartupMod
---@field gui_startup fun(): nil
---@field restore fun(cfg: VnixConfig, _next: number?): nil
---@field workspaces VnixWorkspaceState[]
local M = {
  workspaces = {},
} ---@type VnixStartupMod

function M.gui_startup()
  if vnix and vnix.is_ready then
    local cfg = config.load_from_file(vnix.config_file) ---@type VnixConfig
    M.restore(cfg)
  else
    wezterm.time.call_after(interval, M.gui_startup)
  end
end

function M.restore(arg, next)
  if not next then
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
      name = "__vnix__",
      cwd = vnix.vnix_dir,
      env = {
        VNIX = "VNIX",
        VNIX_DIR = vnix.vnix_dir,
      },
      tabs = {
        {
          name = "__vnix__",
          pane = {
            name = "__vnix__",
            args = { vnix.shell, "-l", "-c", loop_cmd },
          },
        },
      },
    }

    mux.create_workspace(vnix_workspace, function()
      M.restore(arg, 1)
    end)

    return
  end

  local target = arg.workspaces[next]
  if not target then
    state.set_workspaces(M.workspaces)
    -- TODO: Switch to last active pane from activity load
    wezterm.emit("vnix:state-update", mux.resolve_gui_window(), "init")
    return
  end

  wezterm.time.call_after(0, function()
    mux.create_workspace(target, function(workspace)
      table.insert(M.workspaces, workspace)
      M.restore(arg, next + 1)
    end)
  end)
end

return M
