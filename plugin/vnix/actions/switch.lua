local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local rpc = require("vnix.utils.rpc")
local act = wezterm.action
local state = require("vnix.state.state")
local state_utils = require("vnix.state.state_utils")
---@type VNixGlobal
local vnix = wezterm.GLOBAL.vnix

wezterm.on("vnix:switch", function(win, pane)
  log.log("INFO", "vnix: Received switch event")
  -- Validate input parameters
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to switch")
    return
  end

  if not vnix then
    log.log("ERROR", "vnix: vnix global not initialized")
    return
  end

  local switch_ok, switch_err = pcall(function()
    if vnix.no_nvim_ui then
      wezterm.emit("vnix:switch-plain", win, pane)
    else
      rpc.dispatch(win, pane, {
        id = 0,
        return_to = 0,
        type = "switch",
        data = nil,
      })
    end
  end)

  if not switch_ok then
    log.log("ERROR", "vnix: Error in switch operation: " .. tostring(switch_err))
  end
end)

wezterm.on("vnix:switch-to", function(win, pane, id, context, dir)
  if not context then
    context = "p"
  end

  if not dir then
    dir = ""
  end

  id = id or vnix.activity.cp_id

  -- Validate input parameters
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to switch-to")
    return
  end

  if not id then
    log.log("WARN", "vnix: No ID provided for switch-to operation")
    return
  end

  local switch_to_ok, switch_to_err = pcall(function()
    local all_panes = state.get()

    if not all_panes or #all_panes == 0 then
      log.log("WARN", "vnix: No panes available for switch-to operation")
      return
    end

    local numeric_id = tonumber(id)
    if not numeric_id or numeric_id < 1 or numeric_id > #all_panes then
      log.log("ERROR", "vnix: Invalid pane ID for switch-to: " .. tostring(id))

      numeric_id = vnix.activity.cp_id
      if not numeric_id or numeric_id < 1 or numeric_id > #all_panes then
        log.log("ERROR", "vnix: Fallback pane ID isn't available either, aborting...")
        return
      else
        log.log("INFO", "vnix: Using fallback pane ID: " .. numeric_id)
      end
    end

    local current_pane_state, _ = state.find_pane(win, pane)
    if not current_pane_state then
      log.log("WARN", "vnix: Could not find current pane in state for switch-to operation")

      local last = tonumber(vnix.activity.cp_id)
      if last ~= numeric_id then
        current_pane_state = all_panes[last]
        if current_pane_state then
          log.log("INFO", "vnix: using last pane from activity data for switch-to operation")
        end
      end
    end

    local item = all_panes[numeric_id]
    if not item then
      log.log("ERROR", "vnix: Invalid pane data at ID " .. numeric_id)
      return
    end

    -- Validate required fields
    if not item._workspace_id then
      log.log("ERROR", "vnix: Missing workspace_id for pane " .. numeric_id)
      return
    end

    if vnix.debug then
      wezterm.log_info("Found pane state for switch:", wezterm.json_encode(item))
    end

    -- Perform workspace switch with error handling
    local workspace_ok, workspace_err = pcall(function()
      win:perform_action(act.SwitchToWorkspace({ name = item._workspace_id }), pane)
    end)

    if not workspace_ok then
      log.log("ERROR", "vnix: Failed to switch workspace: " .. tostring(workspace_err))
      return
    else
      log.log("INFO", "Switched to workspace: " .. item._workspace_id)
    end

    -- Perform tab activation with error handling
    if item._tab_index then
      local tab_ok, tab_err = pcall(function()
        win:perform_action(act.ActivateTab(tonumber(item._tab_index)), pane)
      end)

      if not tab_ok then
        log.log("ERROR", "vnix: Failed to activate tab: " .. tostring(tab_err))
      else
        log.log("INFO", "Switched to tab: " .. tostring(item._tab_index + 1))
      end
    end

    -- Perform pane activation with error handling
    if item._wez_pane_index then
      local pane_ok, pane_err = pcall(function()
        if dir ~= "" then
          win:perform_action(act.ActivatePaneDirection(dir), pane)
        else
          win:perform_action(act.ActivatePaneByIndex(tonumber(item._wez_pane_index)), pane)
        end
      end)

      if not pane_ok then
        log.log("ERROR", "vnix: Failed to activate pane: " .. tostring(pane_err))
      else
        log.log("INFO", "Switched to pane " .. dir or tostring(item._wez_pane_index or 0))
      end

      local actived_pane = win:active_pane()
      if not actived_pane or actived_pane:pane_id() == pane:pane_id() then
        log.log(
          "ERROR",
          "vnix: Failed to activate pane: "
            .. tostring(actived_pane or nil)
            .. " | "
            .. tostring(pane:pane_id())
        )
      else
        if item.lazy then
          actived_pane:send_paste(item.lazy)
          log.log("INFO", "vnix: pasted " .. item.lazy)
          item.lazy = nil
        end
      end
    end

    vnix.activity.cp_id = numeric_id or 0
    state_utils.update_focus(item, current_pane_state, all_panes, context)
    log.log("INFO", "vnix: Successfully switched to pane " .. numeric_id)
    wezterm.emit("vnix:update-status", win, pane, true)
  end)

  if not switch_to_ok then
    log.log("ERROR", "vnix: Error in switch-to operation: " .. tostring(switch_to_err))
  end
end)

wezterm.on("vnix:switch-plain", function(win, pane)
  log.log("INFO", "vnix: Received switch-plain event")
  -- Validate input parameters
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to switch-plain")
    return
  end

  local plain_ok, plain_err = pcall(function()
    local all_panes = state.get()
    log.log("INFO", "vnix: Got state with " .. (all_panes and #all_panes or 0) .. " panes")
    if not all_panes then
      log.log("ERROR", "vnix: Failed to get state for plain switch")
      return
    end

    if #all_panes == 0 then
      log.log("WARN", "vnix: No panes available for switching")
      return
    end

    local options = {}

    -- Build options with error handling
    local options_ok, options_err = pcall(function()
      for id, v in ipairs(all_panes) do
        if v then
          local workspace = v.workspace or "ws"
          local tab = v.tab or "tab"
          local name = v.name or tostring(id)

          table.insert(options, {
            id = tostring(id),
            label = workspace .. "/" .. tab .. "/" .. name,
          })
        else
          log.log("WARN", "vnix: Skipping invalid pane data at index " .. id)
        end
      end
    end)

    if not options_ok then
      log.log("ERROR", "vnix: Error building options for switch: " .. tostring(options_err))
      return
    end

    if #options == 0 then
      log.log("WARN", "vnix: No valid options available for switching")
      return
    end

    -- Perform input selector action with error handling
    local selector_ok, selector_err = pcall(function()
      win:perform_action(
        act.InputSelector({
          action = wezterm.action_callback(function(_, _, id, label)
            if id and label then
              log.log("INFO", "vnix: User selected pane " .. id .. " (" .. label .. ")")
              wezterm.emit("vnix:switch-to", win, pane, id)
            else
              log.log("INFO", "vnix: User cancelled switch operation")
            end
          end),
          title = "Choose Workspace",
          choices = options,
          fuzzy = true,
          fuzzy_description = "Fuzzy find your workspaces / tabs / panes: ",
        }),
        pane
      )
    end)

    if not selector_ok then
      log.log("ERROR", "vnix: Failed to show input selector: " .. tostring(selector_err))
    end
  end)

  if not plain_ok then
    log.log("ERROR", "vnix: Error in switch-plain operation: " .. tostring(plain_err))
  end
end)

-- Export module for testing
local M = {}
return M
