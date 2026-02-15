local wezterm = require("wezterm")
local rpc = require("vnix.utils.rpc")
local vnix = wezterm.GLOBAL.vnix

local function poll_interval()
  wezterm.time.call_after(60, function()
    wezterm.emit("vnix:tt-interval")
  end)
end

---Sync time tracked
---@param force? boolean
local function sync_tt(force)
  if not force then
    poll_interval()
  end

  if not vnix or not vnix.is_ready or (vnix.activity.tt_lock and not force) then
    return
  end

  local is_tracking = vnix.activity.tt
  local state = require("vnix.state.state")
  local current_state = state.get()
  local current_pane_state = current_state[vnix.activity.cp_id]

  if not current_pane_state then
    return
  end

  current_pane_state[is_tracking and "tt" or "ttb"] = (os.time() - vnix.activity.tts)
    + current_pane_state[is_tracking and "tt" or "ttb"]

  vnix.activity.tts = os.time()
  state.save(current_state)
end

wezterm.on("vnix:tt", function(win, pane)
  rpc.dispatch(win, pane, {
    id = 0,
    timestamp = "",
    type = "timesheet",
    return_to = 0,
    data = "menu",
  })
end)

wezterm.on("vnix:tt-interval", function()
  sync_tt()
end)

wezterm.on(
  "vnix:tt-action",
  ---cb
  ---@param win Window
  ---@param pane Pane
  ---@param resp UIMessageTTResp
  function(win, pane, resp)
    local resp_type = resp.data
    if resp_type == "reset" then
      -- TODO: Reset time tracker
      do
      end
    elseif resp_type == "start" or resp_type == "stop" then
      vnix.activity.tt_lock = true

      pcall(function()
        sync_tt(true)
        vnix.activity.tt = resp_type == "start"
      end)

      vnix.activity.tt_lock = false
    end

    wezterm.emit("vnix:switch-to", win, pane, nil, resp.return_to)
  end
)

poll_interval()
