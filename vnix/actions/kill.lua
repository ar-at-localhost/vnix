local wezterm = require("wezterm")
local act = wezterm.action

wezterm.on(
  "vnix:kill",
  ---cb
  ---@param win Window
  ---@param pane Pane
  function(win, pane)
    win:perform_action(
      act.CloseCurrentPane({
        confirm = false,
      }),
      pane
    )

    wezterm.emit("vnix:state-update")
  end
)
