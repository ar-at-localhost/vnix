local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1001 }
config.color_scheme = "Catppuccin Latte"
config.font = wezterm.font("Fira Code Nerd Font")
config.font_size = 11
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_max_width = 0
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = false
config.status_update_interval = 60000
config.window_decorations = "NONE"
config.mouse_wheel_scrolls_tabs = false
config.default_cursor_style = "BlinkingBlock"

config.unix_domains = {
  ---@diagnostic disable-next-line: missing-fields
  {
    name = "vnix-dev",
  },
}

-- Load vnix plugin
local vnix = require("vnix")
vnix.apply_to_config(config, {
  vnix_dir = "/tmp/vnix-dev",
  config_file = "config.json",
  debug = true,
  dev = true,
})

return config
