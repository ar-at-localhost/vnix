local wezterm = require("wezterm")
local tbl = require("common.tbl")
local specials = require("vnix.keys.specials")
local act = wezterm.action

---@type VnixKeyGroup
local common = {
  keys = {
    dashboard = {
      key = "d",
      mods = "LEADER",
      action = act.EmitEvent("vnix:dashboard"),
      description = "Dashboard",
    },
    create = {
      key = "+",
      mods = "LEADER|SHIFT",
      action = act.EmitEvent("vnix:create"),
      description = "Create new",
    },
    rename = {
      key = "r",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:trigger-rename", win, pane)
      end),
      description = "Create new workspace",
    },
    kill = { key = ";", mods = "LEADER", action = act.EmitEvent("vnix:kill"), description = "Kill" },
    persist = {
      key = "p",
      mods = "LEADER|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:persist", win, pane, "secondary")
      end),
    },
    persist_primary = {
      key = "P",
      mods = "LEADER|CTRL",
      action = wezterm.action_callback(function(win, pane)
        wezterm.emit("vnix:persist", win, pane, "primary")
      end),
    },
    procs = {
      key = "p",
      mods = "LEADER",
      action = act.ActivateKeyTable({
        name = "vnix_procs",
      }),
      description = "Vnix Procs",
    },
  },
  tables = {
    vnix_procs = tbl.deep_merge(specials.keys, {
      procs = {
        key = "p",
        action = act.EmitEvent("vnix:procs"),
        description = "Procs list (Active worksapce)",
      },
      procs_all = {
        key = "P",
        mods = "SHIFT",
        action = wezterm.action_callback(function(win, pane)
          wezterm.emit("vnix:procs", win, pane, "all")
        end),
        description = "Procs list (All)",
      },
      procs_vnix = {
        key = "p",
        mods = "CTRL",
        action = wezterm.action_callback(function(win, pane)
          wezterm.emit("vnix:procs", win, pane, "vnix")
        end),
        description = "Procs list (Vnix level)",
      },
    }),
  },
}

return common
