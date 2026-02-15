--TODO: Activate
local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local state = require("vnix.state.state")
local ui = require("vnix.core.ui")
local state_utils = require("vnix.state.state_utils")
local act = wezterm.action
local vnix = wezterm.GLOBAL.vnix

wezterm.on("vnix:rename", function(win, pane)
  -- Validate input parameters
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to rename")
    return
  end

  if not vnix then
    log.log("ERROR", "vnix: vnix global not initialized")
    return
  end

  local rename_ok, rename_err = pcall(function()
    local current, _ = state.find_pane(win, pane)

    if not current then
      log.log("WARN", "vnix: Cannot find current pane for rename operation")
      return
    end

    if vnix.no_nvim_ui then
      wezterm.emit("vnix:rename-plain", win, pane)
    else
      ui.run(win, pane, { "rename", { current } })
    end
  end)

  if not rename_ok then
    log.log("ERROR", "vnix: Error in rename operation: " .. tostring(rename_err))
  end
end)

wezterm.on("vnix:rename-pane", function(win, pane, data)
  -- Validate input parameters
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to rename-pane")
    return
  end

  if not data then
    log.log("ERROR", "vnix: Invalid data provided to rename-pane")
    return
  end

  local change = false

  local rename_pane_ok, rename_pane_err = pcall(function()
    local changed_pane = nil
    local all_panes = state.get()
    if not all_panes then
      log.log("ERROR", "vnix: Failed to get state for rename-pane operation")
      return
    end

    for _, v in ipairs(all_panes) do
      if v and v._workspace_id == data._workspace_id then
        if data.workspace and data.workspace ~= v.workspace then
          v.workspace = data.workspace
          change = true
        end

        if v._tab_id == data._tab_id then
          if data.tab and data.tab ~= v.tab then
            v.tab = data.tab
            change = true
          end

          if data.name and v._pane_id == data._pane_id and data.name ~= v.name then
            v.name = data.name
            change = true
            changed_pane = v
          end
        end
      end
    end

    if change then
      state_utils.update_focus(nil, changed_pane, all_panes)
      wezterm.emit("update-right-status", win, pane)
    else
      log.log("WARN", "vnix: No matching update performed in rename-pane")
    end
  end)

  if not rename_pane_ok then
    log.log("ERROR", "vnix: Error in rename-pane operation: " .. tostring(rename_pane_err))
  end
end)

-- New event handler for plain renaming
wezterm.on(
  "vnix:rename-plain",
  ---Callback
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    -- Validate input parameters
    if not win or not pane then
      log.log("ERROR", "vnix: Invalid win or pane provided to rename-plain")
      return
    end

    local plain_ok, plain_err = pcall(function()
      win:perform_action(
        act.PromptInputLine({
          on_change = function() -- Removed unused parameters
            -- No real-time change needed for renaming
          end,
          on_cancel = function()
            log.log("INFO", "vnix: User cancelled rename operation")
          end,
          on_submit = function(input)
            local submit_ok, submit_err = pcall(function()
              if not input or type(input) ~= "string" then
                log.log("WARN", "vnix: Invalid input provided for rename")
                return
              end

              local current, current_index = state.find_pane(win, pane)
              if not current then
                log.log("WARN", "vnix: Cannot find current pane for rename")
                return
              end

              local target_type = "pane" -- Default to pane
              local new_name = input

              -- Parse input prefix to determine target type
              if #input > 0 then
                if input:sub(1, 1) == "#" then
                  target_type = "workspace"
                  new_name = input:sub(2)
                elseif input:sub(1, 1) == "$" then
                  target_type = "tab"
                  new_name = input:sub(2)
                elseif input:sub(1, 1) == "-" then
                  target_type = "pane"
                  new_name = input:sub(2)
                end
              end

              -- Validate new name
              new_name = new_name:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
              if new_name == "" then
                log.log("WARN", "vnix: Empty name provided, cancelling rename")
                return
              end

              if target_type == "workspace" then
                -- Rename workspace with error handling
                local workspace_ok, workspace_err = pcall(function()
                  local mw = win:mux_window()
                  mw:set_workspace(new_name)
                end)

                if not workspace_ok then
                  log.log("ERROR", "vnix: Failed to rename workspace: " .. tostring(workspace_err))
                  return
                end

                -- Update state for all panes in this workspace
                local all_panes = state.get()
                if all_panes then
                  for _, p_state in ipairs(all_panes) do
                    if p_state and p_state._workspace_id == current._workspace_id then
                      p_state.workspace = new_name
                    end
                  end
                  state.save_and_return(all_panes)
                end
              elseif target_type == "tab" then
                -- Rename tab with error handling
                local tab_ok, tab_err = pcall(function()
                  local tab = win:active_tab()
                  if tab then
                    tab:set_title(new_name)
                  end
                end)

                if not tab_ok then
                  log.log("ERROR", "vnix: Failed to rename tab: " .. tostring(tab_err))
                  return
                end

                -- Update state for all panes in this tab
                local all_panes = state.get()
                if all_panes then
                  for _, p_state in ipairs(all_panes) do
                    if p_state and p_state._tab_id == current._tab_id then
                      p_state.tab = new_name
                    end
                  end
                  state.save_and_return(all_panes)
                end
              elseif target_type == "pane" then
                -- Update state for the current pane
                local all_panes = state.get()
                if
                  all_panes
                  and current_index
                  and current_index > 0
                  and current_index <= #all_panes
                then
                  all_panes[current_index].name = new_name
                  state.save_and_return(all_panes)
                end
              end

              log.log(
                "INFO",
                "vnix: Successfully renamed " .. target_type .. " to '" .. new_name .. "'"
              )
            end)

            if not submit_ok then
              log.log("ERROR", "vnix: Error during rename submit: " .. tostring(submit_err))
            end
          end,
          title = "Rename (prefix # for workspace, $ for tab, - for pane):",
        }),
        pane
      )
    end)

    if not plain_ok then
      log.log("ERROR", "vnix: Error in rename-plain operation: " .. tostring(plain_err))
    end
  end
)
