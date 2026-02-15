local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local state = require("vnix.state.state")
local state_utils = require("vnix.state.state_utils")
local time = require("vnix.utils.time")
local fs = require("vnix.utils.fs")
local vnix = wezterm.GLOBAL.vnix

-- Load color palette from Stylix
local function load_stylix_colors()
  local palette_path = (os.getenv("HOME") or "/") .. "/.config/stylix/palette.json"
  local palette = fs.read_json(palette_path)
  if palette then
    return {
      obg = "#" .. palette.base09, -- Orange background
      ofg = "#" .. palette.base00, -- Light foreground
      efg = "#" .. palette.base00, -- Light foreground
      ebg = "#" .. palette.base0D, -- Blue background
      transparent = "#" .. palette.base00, -- Transparent
      black = "#" .. palette.base05, -- Black variant
    }
  else
    -- Fallback colors (Stylix Catppuccin Latte)
    return {
      obg = "#fe640b",
      ofg = "#eff1f5",
      efg = "#eff1f5",
      ebg = "#1e66f5",
      transparent = "#eff1f5",
      black = "#9ca0b0", -- Black variant
    }
  end
end

local colors = load_stylix_colors()

wezterm.on("update-status", function(win, pane)
  wezterm.emit("vnix:update-status", win, pane)
end)

wezterm.on("vnix:update-status", function(win, pane)
  if not win or not pane then
    log.log("ERROR", "vnix: Invalid win or pane provided to vnix:update-status")
    return
  end

  if not vnix then
    log.log("ERROR", "vnix: vnix global not initialized in status bar")
    return
  end

  local status_ok, status_err = pcall(function()
    -- Safe pane ID retrieval with error handling
    local pane_id
    local pane_id_ok, pane_id_err = pcall(function()
      pane_id = pane:pane_id()
    end)

    if not pane_id_ok or not pane_id then
      log.log("ERROR", "vnix: Failed to get pane ID for status bar: " .. tostring(pane_id_err))
      return
    end

    local state_pane, state_pane_id, _ = state.find_pane(win, pane)

    if state_pane then
      _ = state_pane_id
      local status_format_ok, status_format_err = pcall(function()
        local tt = vnix.activity.tt
        local now = os.time()
        if not vnix.activity.tts then
          vnix.activity.tts = now
        end

        local has_pane = (state_pane.tab or "") ~= (state_pane.name or "")

        -- Build RIGHT statusline with validation
        local right_status_ok, right_status_err = pcall(function()
          local time_text = ""
          if tt then
            time_text = "󱎫 " .. time.format_time_diff(state_pane.tt)
          else
            time_text = "󱎬 " .. time.format_time_diff(state_pane.ttb)
          end

          local rs = {
            { Foreground = { Color = colors.black } },
            { Text = " " .. time_text .. " " },
          }

          win:set_right_status(wezterm.format(rs))
        end)

        if not right_status_ok then
          log.log("ERROR", "vnix: Failed to set right status: " .. tostring(right_status_err))
        end

        -- Build LEFT statusline with validation
        local key_table = win:active_key_table()
        local workspace_name = state_pane.workspace or "default"
        local tab_name = state_pane.tab or "tab"
        local pane_name = state_pane.name or "pane"
        local mode = key_table == "vnix_navigation" and "[n]" or ""

        local left_text = mode .. "  " .. workspace_name .. " ·  " .. tab_name
        if has_pane then
          left_text = left_text .. " ·  " .. pane_name
        end

        local left_status = {
          { Foreground = { Color = colors.black } },
          { Text = left_text },
        }

        local left_status_ok, left_status_err = pcall(function()
          win:set_left_status(wezterm.format(left_status))
        end)

        if not left_status_ok then
          log.log("ERROR", "vnix: Failed to set left status: " .. tostring(left_status_err))
        end
      end)

      if not status_format_ok then
        log.log("ERROR", "vnix: Error formatting status bar: " .. tostring(status_format_err))
      end
    end
  end)

  if not status_ok then
    log.log("ERROR", "vnix: Error in status bar update: " .. tostring(status_err))
  end
end)
