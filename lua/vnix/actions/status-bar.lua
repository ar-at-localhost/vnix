local wezterm = require("wezterm")
local vnix = wezterm.GLOBAL.vnix

-- Load colors
local function load_colors()
  return {
    obg = "#fe640b",
    ofg = "#eff1f5",
    efg = "#eff1f5",
    ebg = "#1e66f5",
    transparent = "#eff1f5",
    black = "#9ca0b0", -- Black variant
  }
end

local colors = load_colors()

wezterm.on("update-status", function(win, pane)
  wezterm.emit("vnix:update-status", win, pane)
end)

wezterm.on("vnix:update-status", function(win, pane)
  if not win or not pane or not vnix then
    return
  end

  pcall(function()
    local state_pane = vnix.activity.active_pane
    if not state_pane then
      return
    end

    if state_pane then
      local has_pane = (state_pane.tab or "") ~= (state_pane.name or "")

      -- Right Status
      pcall(function()
        local time_text = "󱎬  Coming soon!"

        local rs = {
          { Foreground = { Color = colors.black } },
          { Text = " " .. time_text .. " " },
        }

        win:set_right_status(wezterm.format(rs))
      end)

      -- Left Status
      pcall(function()
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
        win:set_left_status(wezterm.format(left_status))
      end)
    end
  end)
end)
