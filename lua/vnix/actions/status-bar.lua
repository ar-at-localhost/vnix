local wezterm = require("wezterm")
local common = require("common")
local vnix_mux = require("vnix.mux")
local rpc = require("vnix.rpc")
local events = require("vnix.events")
local vnix = wezterm.GLOBAL.vnix

---@class Config
---@field resolved_palette Palette

local function load_colors()
  return vnix and vnix.palette
    or {
      background = "#eff1f5",
      foreground = "#4c4f69",
      tab_bar = {
        background = "dce0e8",
      },
      brights = {
        "#acb0be",
        "#d20f39",
        "#40a02b",
        "#df8e1d",
        "#1e66f5",
        "#ea76cb",
        "#179299",
        "#6c6f85",
      },
    }
end

local colors = load_colors()

wezterm.on("update-status", function(win, pane)
  wezterm.emit("vnix:update-status", win, pane)
  if vnix.ui_req and vnix.ui_req.type == "procs" then
    wezterm.emit("vnix:procs-refresh", win, pane)
  end
end)

wezterm.on(
  "vnix:update-status",
  ---@param win Window
  function(win, pane)
    if not vnix then
      return
    end

    local is_vnix = false

    pcall(function()
      local state_pane = vnix.runtime.active_pane
      if not state_pane or win:active_workspace() == common.vnix_token then
        ---@diagnostic disable-next-line: cast-local-type
        state_pane = state_pane or vnix.nvim
        is_vnix = true
      end

      if state_pane then
        local has_pane = (state_pane.tab or "") ~= (state_pane.name or "")

        -- Right Status
        pcall(function()
          local sep = is_vnix and "" or utf8.char(0xe0b2)

          local task = vnix.status and vnix.status.task
            or {
              title = "No task!",
              formatted = "00:00",
            }

          local rs = {
            { Background = { Color = colors.tab_bar.background } },
            { Foreground = { Color = colors.brights[5] } },
            { Text = sep },
            { Background = { Color = colors.brights[5] } },
            { Foreground = { Color = "white" } },
            { Text = " " .. task.title .. " " },
            { Background = { Color = colors.brights[5] } },
            { Foreground = { Color = colors.brights[7] } },
            { Text = "" },
            { Background = { Color = colors.brights[7] } },
            { Foreground = { Color = "white" } },
            { Text = " " .. task.formatted .. " " },
          }

          win:set_right_status(wezterm.format(rs))
        end)

        -- Left Status
        pcall(function()
          local sep = is_vnix and "" or utf8.char(0xe0b0)
          local key_table = win:active_key_table()
          local workspace_name = is_vnix and "Vnix" or state_pane.workspace or "default"
          local tab_name = is_vnix and "UI" or state_pane.tab or "tab"
          local pane_name = state_pane.name or "pane"
          local mode = key_table == "vnix_navigation" and "[n]" or ""
          local segments = {}
          if mode ~= "" then
            table.insert(segments, {
              text = " " .. mode .. " ",
              fg = colors.background,
              bg = colors.brights[2],
            })
          end
          table.insert(segments, {
            text = "  " .. workspace_name .. " ",
            fg = colors.background,
            bg = colors.brights[7],
          })
          table.insert(segments, {
            text = " 󰓪 " .. tab_name .. " ",
            fg = colors.background,
            bg = colors.brights[5],
          })
          if has_pane and not is_vnix then
            table.insert(segments, {
              text = " 󰾍 " .. pane_name .. " ",
              fg = colors.background,
              bg = colors.brights[4],
            })
          end
          local left_status = {}
          for i, seg in ipairs(segments) do
            local next_seg = segments[i + 1]
            table.insert(left_status, { Background = { Color = seg.bg } })
            table.insert(left_status, { Foreground = { Color = seg.fg } })
            table.insert(left_status, { Text = seg.text })
            if next_seg then
              table.insert(left_status, { Background = { Color = next_seg.bg } })
              table.insert(left_status, { Foreground = { Color = seg.bg } })
              table.insert(left_status, { Text = "" })
            else
              table.insert(left_status, { Background = { Color = colors.tab_bar.background } })
              table.insert(left_status, { Foreground = { Color = seg.bg } })
              table.insert(left_status, { Text = sep })
            end
          end
          win:set_left_status(wezterm.format(left_status))
        end)
      end
    end)
  end
)

---@param onshot? boolean
local function sync_status(onshot)
  if vnix and vnix.is_ready then
    vnix.status = rpc.get_status() or nil
    if not onshot then
      wezterm.time.call_after(60, sync_status)
    end
  end
end

events.make_event("vnix:sync-status", function(_, _)
  sync_status(true)
end)

sync_status()
