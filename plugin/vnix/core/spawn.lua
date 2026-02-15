local wezterm = require("wezterm")
local mux = wezterm.mux
local misc = require("vnix.utils.misc")
local log = require("vnix.utils.log")
local vnix = wezterm.GLOBAL.vnix

local M = {}

--- @class WorkspaceMapEntry
--- @field tab_count number
--- @field pane_count number

--- @class PaneSetting
--- @field pane_state PaneState
--- @field workspace string
--- @field tab string
--- @field name string
--- @field dir string
--- @field cwd string
--- @field args string[]
--- @field args_mode string
--- @field env table
--- @field size PaneSize

--- @class CreateContext
--- @field p_id number
--- @field workspaces table
--- @field window MuxWindow
--- @field gui_window Window
--- @field tab MuxTab
--- @field pane Pane
--- @field workspace string
--- @field pane_setting PaneSetting

--- @param context CreateContext
--- @param super_context table
function M.create(context, super_context)
  local creation_ok, creation_err
  local args, lazy = misc.handle_args(vnix, context.pane_setting)
  local args_mode = context.pane_setting.args_mode

  -- Safe pane/window creation with error handling
  creation_ok, creation_err = pcall(function()
    local cmd = {
      cwd = context.pane_setting.cwd,
      env = context.pane_setting.env,
    }

    if args then
      cmd.args = args
    end

    if context.pane_setting.dir then
      if not context.gui_window or not context.pane then
        error("No window or pane provided for split operation")
      end

      cmd.direction = context.pane_setting.dir
      cmd.size = 0.5

      pcall(function()
        if cmd.direction == "Right" and context.pane_setting.size.percent then
          cmd.size = context.pane_setting.size.percent.width / 100
        end

        if cmd.direction == "Bottom" and context.pane_setting.size.percent then
          cmd.size = context.pane_setting.size.percent.height / 100
        end

        if cmd.size >= 1 then
          cmd.size = 0.5
        end
      end)

      log.log(
        "info",
        "splitting " .. context.pane_setting.dir .. " with percent size " .. tostring(cmd.size)
      )

      context.pane = context.pane:split(cmd)
      context.window = context.workspaces[context.pane_setting.workspace]
    else
      cmd.workspace = context.pane_setting.workspace
      if not context.workspaces[context.pane_setting.workspace] then
        context.tab, context.pane, context.window = mux.spawn_window(cmd)

        if not context.gui_window then
          context.gui_window = context.window:gui_window()
          if context.gui_window then
            context.gui_window:maximize()
          end
        end

        context.workspaces[context.pane_setting.workspace] = context.window
      else
        context.window = context.workspaces[context.pane_setting.workspace]
        context.tab, context.pane, context.window = context.window:spawn_tab(cmd)
      end

      if context.window then
        context.tab = context.window:active_tab()
        if context.tab then
          context.tab:set_title(
            context.pane_setting.tab or context.pane_setting.name or context.pane_setting.workspace
          )
        end
      end
    end
  end)

  if not creation_ok then
    log.log("ERROR", "vnix: Failed to create pane: " .. tostring(creation_err))
  end

  -- Adjust pane index
  local _, err = pcall(function()
    local pane_state = context.pane_setting.pane_state
    context.tab = context.pane:tab() or context.tab

    if context.tab == nil then
      error("Failed to obtain the tab from pane")
    end

    local ps = context.pane_setting

    if not super_context[ps.workspace] then
      super_context[ps.workspace] = {
        tab_count = 0,
        tabs = {},
      }
    end

    if not super_context[ps.workspace].tabs[ps.tab] then
      super_context[ps.workspace].tabs[ps.tab] = {
        tab_index = super_context[ps.workspace].tab_count,
        pane_count = 0,
      }

      super_context[ps.workspace].tab_count = super_context[ps.workspace].tab_count + 1
    end

    pane_state.size = context.pane_setting.size
    pane_state._workspace_id = context.workspace
    pane_state._tab_id = context.tab:tab_id()
    pane_state._tab_index = super_context[ps.workspace].tabs[ps.tab].tab_index
    pane_state._pane_id = context.pane:pane_id()
    pane_state._wez_pane_index = super_context[ps.workspace].tabs[ps.tab].pane_count

    super_context[ps.workspace].tabs[ps.tab].pane_count = super_context[ps.workspace].tabs[ps.tab].pane_count
      + 1
  end)

  if err then
    log.log("ERROR", "vnix: Failed to assing pane identities: " .. tostring(err))
  end

  return super_context,
    context.workspaces,
    context.window,
    context.gui_window,
    context.tab,
    context.pane,
    args_mode,
    lazy,
    context.pane_setting,
    creation_ok,
    creation_err
end

return M
