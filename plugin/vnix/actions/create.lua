--TODO: Activate
local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local rpc = require("vnix.utils.rpc")
local act = wezterm.action
local vnix = wezterm.GLOBAL.vnix

wezterm.on(
  "vnix:create",
  ---Callback
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    -- Validate input parameters
    if not win or not pane then
      log.log("ERROR", "vnix: Invalid win or pane provided to create")
      return
    end

    if not vnix then
      log.log("ERROR", "vnix: vnix global not initialized")
      return
    end

    local create_ok, create_err = pcall(function()
      if vnix.no_nvim_ui then
        wezterm.emit("vnix:create-plain", win, pane)
      else
        rpc.dispatch(win, pane, {
          id = 0,
          return_to = 0,
          type = "create",
          data = nil,
        })
      end
    end)

    if not create_ok then
      log.log("ERROR", "vnix: Error in create operation: " .. tostring(create_err))
    end
  end
)

wezterm.on(
  "vnix:create-plain",
  ---Callback
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    -- Validate input parameters
    if not win or not pane then
      log.log("ERROR", "vnix: Invalid win or pane provided to create-plain")
      return
    end

    local plain_ok, plain_err = pcall(function()
      win:perform_action(
        act.PromptInputLine({
          on_change = function() -- Removed unused 'input' parameter
            -- No real-time change needed for creation
          end,
          on_cancel = function()
            log.log("INFO", "vnix: User cancelled create operation")
          end,
          on_submit = function(input)
            local submit_ok, submit_err = pcall(function()
              -- Validate input
              if not input or type(input) ~= "string" then
                log.log("WARN", "vnix: Invalid input provided for create")
                return
              end

              -- First trim whitespace from input
              local trimmed_input = input:gsub("^%s+", ""):gsub("%s+$", "")

              local target_type = "tab" -- Default to tab
              local new_name = trimmed_input

              -- Parse input prefix to determine target type and extract name
              if #trimmed_input > 0 then
                if trimmed_input:sub(1, 1) == "#" then
                  target_type = "workspace"
                  new_name = trimmed_input:sub(2)
                elseif trimmed_input:sub(1, 1) == "$" then
                  target_type = "tab"
                  new_name = trimmed_input:sub(2)
                end
              end
              if new_name == "" then
                log.log("WARN", "vnix: Empty name provided for create, cancelling")
                return
              end

              -- Validate name doesn't contain invalid characters
              if new_name:match("[/\\:*?\"<>|]") then
                log.log("WARN", "vnix: Invalid characters in name: " .. new_name)
                return
              end

              if target_type == "workspace" then
                -- Create workspace with error handling
                local workspace_ok, workspace_err = pcall(function()
                  win:perform_action(act.SwitchToWorkspace({ name = new_name }), pane)
                end)

                if not workspace_ok then
                  log.log("ERROR", "vnix: Failed to create workspace: " .. tostring(workspace_err))
                else
                  log.log("INFO", "vnix: Successfully created workspace: " .. new_name)
                end
              elseif target_type == "tab" then
                -- Get current workspace safely
                local current_workspace
                local workspace_get_ok, workspace_get_err = pcall(function()
                  current_workspace = win:active_workspace()
                end)

                if not workspace_get_ok then
                  log.log(
                    "ERROR",
                    "vnix: Failed to get current workspace: " .. tostring(workspace_get_err)
                  )
                  return
                end

                -- Create tab with error handling
                local tab_ok, tab_err = pcall(function()
                  win:perform_action(
                    act.SpawnTab({
                      cwd = vnix.user_home or os.getenv("HOME") or "/",
                      workspace = current_workspace,
                    }),
                    pane
                  )
                end)

                if not tab_ok then
                  log.log("ERROR", "vnix: Failed to create tab: " .. tostring(tab_err))
                  return
                end

                -- Rename the newly created tab with error handling
                local rename_ok, rename_err = pcall(function()
                  local tab = win:active_tab()

                  if tab then
                    tab:set_title(new_name)
                  end
                end)

                if not rename_ok then
                  log.log("ERROR", "vnix: Failed to rename new tab: " .. tostring(rename_err))
                else
                  log.log("INFO", "vnix: Successfully created tab: " .. new_name)
                end
              end
            end)

            if not submit_ok then
              log.log("ERROR", "vnix: Error during create submit: " .. tostring(submit_err))
            end
          end,
          title = "Create (prefix # for workspace, $ for tab):",
        }),
        pane
      )
    end)

    if not plain_ok then
      log.log("ERROR", "vnix: Error in create-plain operation: " .. tostring(plain_err))
    end
  end
)
