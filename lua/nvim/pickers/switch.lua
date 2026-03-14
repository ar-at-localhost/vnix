local config = require("nvim.config")
local resp = require("nvim.resp")

---@type snacks.picker.Config
local common = {
  confirm = function(self, item)
    local kind = self.opts.source
    resp.write(resp.create_from_req(
      nil,
      ---@type UIMessageSwitchRespData
      {
        kind = kind,
        id = item.value,
      }
    ))

    self:close()
  end,

  win = {
    input = {
      keys = {
        -- selene: allow(mixed_table)
        ["<leader>w"] = {
          "workspaces",
          mode = { "n", "v" },
        },
        -- selene: allow(mixed_table)
        ["<leader>t"] = {
          "tabs",
          mode = { "n", "v" },
        },
        -- selene: allow(mixed_table)
        ["<leader>p"] = {
          "panes",
          mode = { "n", "v" },
        },
      },
    },
  },

  actions = {
    workspaces = function(self)
      if self.opts.source == "workspaces" then
        return
      end

      self:close()
      local next = Snacks.picker.workspace
      config.pickers.switch = {
        source = "workspace",
      }
      next()
    end,
    tabs = function(self)
      if self.opts.source == "tabs" then
        return
      end

      self:close()
      local next = Snacks.picker.tab
      config.pickers.switch = {
        source = "tab",
      }
      next()
    end,
    panes = function(self)
      if self.opts.source == "panes" then
        return
      end

      self:close()
      local next = Snacks.picker.pane
      config.pickers.switch = { source = "pane" }
      next()
    end,
  },
}

return common
