local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local mux = wezterm.mux
local spawn = require("vnix.core.spawn")
local misc = require("vnix.utils.misc")
local state = require("vnix.state.state")
local common = require("vnix-common")

---@param vnix VNixGlobal
local function restore(vnix, win_sub, state_sub)
  log.log("INFO", "vnix: restoring session")

  -- Validate input parameters
  if not vnix then
    log.log("ERROR", "vnix: Invalid vnix object provided to restore")
    return false
  end

  local workspaces = {}
  local traversed = {}
  local current_state = state_sub and misc.keys_to_num(state_sub) or state.get()
  local gui_window = win_sub and win_sub or nil

  -- Validate state data
  if not current_state then
    log.log("WARN", "vnix: No valid state to restore")
    return true -- Not an error, just nothing to restore
  end

  -- Inject vnix-nvim server pane BEFORE main restoration loop
  local vnix_nvim_ok, vnix_nvim_err = pcall(function()
    if vnix.no_nvim_ui then
      log.log("INFO", "vnix: UI is disabled by user configuration.")
      return
    end

    if not vnix.ui_running then
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

      -- Create vnix-nvim pane configuration
      --- @type PaneSpec
      local vnix_pane = {
        workspace = "__vnix__",
        tab = "ui",
        name = "ui",
        cwd = vnix.vnix_dir,
        args = { vnix.shell, "-l", "-c", loop_cmd },
        env = {
          VNIX = "VNIX",
          VNIX_DIR = vnix.vnix_dir,
        },
      }

      -- Launch the pane
      local _, _, window = mux.spawn_window({
        workspace = vnix_pane.workspace,
        cwd = vnix_pane.cwd,
        args = vnix_pane.args,
        set_environment_variables = vnix_pane.env,
        position = {
          origin = "ActiveScreen",
          x = 0,
          y = 0,
        },
      })

      -- Maximize the GUI window if it exists
      if not gui_window then
        gui_window = window:gui_window()
        if gui_window then
          gui_window:maximize()
        end
      end

      -- Track the workspace and emit setup event
      workspaces[vnix_pane.workspace] = window
      wezterm.emit("vnix:ui-setup")
    else
      log.log("INFO", "vnix: vnix-nvim already running")
    end
  end)

  if not vnix_nvim_ok then
    log.log("ERROR", "vnix: error launching vnix-nvim server pane: " .. tostring(vnix_nvim_err))
  else
    vnix.ui_running = true
    log.log("INFO", "vnix: vnix-nvim server successfully launched")
  end

  local super_context = {}

  ---@param p PaneState
  local function spawn_pane(p_id, p, tab, pane, dir)
    -- Validate input parameters
    if not p_id or not p then
      log.log("WARN", "vnix: Invalid pane data for spawn_pane, skipping")
      return tab, pane
    end

    -- Check if the pane has already been traversed or if it's a null pane.
    -- This prevents infinite loops in case of circular references in the state.
    if traversed[p_id] then
      return tab, pane
    else
      -- Mark the current pane as traversed
      traversed[p_id] = { id = p_id }
    end

    local window
    local cwd = p["cwd"] or vnix.user_home or os.getenv("HOME") or "/"
    local workspace = p["workspace"] or "default"
    local args = p["args"] or nil
    local args_mode = p["args_mode"] or nil
    local env = p.env or {}
    local pane_setting = {
      pane_state = p,
      workspace = p["workspace"],
      tab = p["tab"],
      name = p["name"],
      dir = dir,
      cwd = cwd,
      args = args,
      args_mode = args_mode,
      env = env,
      size = p["size"],
    }

    -- Safe pane/window creation with error handling
    local creation_ok, creation_err = pcall(function()
      local ok, err

      super_context, workspaces, window, gui_window, tab, pane, p.args_mode, p.lazy, pane_setting, ok, err =
        spawn.create({
          p_id = p_id,
          workspaces = workspaces,
          window = window,
          gui_window = gui_window,
          tab = tab,
          pane = pane,
          workspace = workspace,
          pane_setting = pane_setting,
        }, super_context)

      return ok, err
    end)

    if not creation_ok then
      log.log("ERROR", "vnix: Failed to create pane " .. p_id .. ": " .. tostring(creation_err))
      return tab, pane
    end

    -- Logic to recursively spawn child panes (right/bottom splits) with validation
    local split_ok, split_err = pcall(function()
      if p.right or p.bottom then
        -- Determine the primary split direction (right or bottom)
        local first_dir = (p.first == "right" and p.first) or (p.bottom and "bottom") or "right"
        local first_id = tonumber(p[first_dir])

        if first_id and current_state[first_id] then
          local first = current_state[first_id]
          -- Validate that the child pane belongs to the same workspace/tab
          if first and first.workspace == p["workspace"] and first.tab == p.tab then
            first["workspace"] = workspace
            first["tab"] = p.tab or p.name or workspace
            -- Add back-reference to child pane
            -- No circular reference check needed since we only set forward refs (right/bottom) on parents
            -- and back-refs (top/left) on children, which naturally prevents cycles
            if first_dir == "bottom" then
              first.top = p_id
            elseif first_dir == "right" then
              first.left = p_id
            end
            spawn_pane(first_id, first, tab, pane, first_dir:gsub("^%l", string.upper))
          end
        end

        -- Determine the secondary split direction
        local second_dir = first_dir == "bottom" and "right" or "bottom"
        local second_id = tonumber(p[second_dir])

        if second_id and current_state[second_id] then
          local second = current_state[second_id]
          -- Validate that the child pane belongs to the same workspace/tab
          if second and second.workspace == p["workspace"] and second.tab == p.tab then
            second["workspace"] = workspace
            second["tab"] = p.tab or p.name or workspace
            -- Add back-reference to child pane
            -- No circular reference check needed since we only set forward refs (right/bottom) on parents
            -- and back-refs (top/left) on children, which naturally prevents cycles
            if second_dir == "bottom" then
              second.top = p_id
            elseif second_dir == "right" then
              second.left = p_id
            end
            spawn_pane(second_id, second, tab, pane, second_dir:gsub("^%l", string.upper))
          end
        end
      end
    end)

    if not split_ok then
      log.log(
        "WARN",
        "vnix: Error processing splits for pane " .. p_id .. ": " .. tostring(split_err)
      )
    end

    return tab, pane
  end

  -- Main restoration loop with error handling
  local tab, pane

  local restore_ok, restore_err = pcall(function()
    for p_id, p in ipairs(current_state) do
      if p then
        tab, pane = spawn_pane(p_id, p, tab, pane)
        current_state[p_id] = p
      else
        log.log("WARN", "vnix: Skipping invalid pane state at index " .. p_id)
      end
    end
  end)

  if not restore_ok then
    log.log("ERROR", "vnix: Error during main restoration loop: " .. tostring(restore_err))
    return false
  end

  -- Safe state management with error handling
  local state_ok, state_err = pcall(function()
    if state_sub then
      local new_state = {}
      local existing_state = state.get()

      -- Merge existing state
      if existing_state then
        for _, v in ipairs(existing_state) do
          if v then
            table.insert(new_state, v)
          end
        end
      end

      -- Merge new state
      if state_sub then
        for _, v in ipairs(misc.keys_to_num(state_sub)) do
          if v then
            table.insert(new_state, v)
          end
        end
      end

      state.save_and_return(new_state)
    else
      state.save_and_return(current_state)
    end

    -- Ensure focused_id is valid (only correct if out of bounds, don't default to 1)
    local final_state = state.get()
    if not vnix.activity.cp_id or vnix.activity.cp_id > #final_state then
      vnix.activity.cp_id = #final_state
    end

    wezterm.emit("vnix:switch-to", gui_window, pane)
  end)

  if not state_ok then
    log.log("ERROR", "vnix: Error managing state after restore: " .. tostring(state_err))
    return false
  end

  return true
end

return restore
