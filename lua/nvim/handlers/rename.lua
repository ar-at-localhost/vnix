local resp = require("nvim.resp")
local VnixForm = require("nvim.forms")
local tbl = require("common.tbl")

local types = { "pane", "tab", "workspace", "all" }

---@param idx integer?
local function get_type_line(idx)
  if not idx then
    idx = 1
  end

  local vals = {}
  for i, v in ipairs(types) do
    local pre = ""
    if i == idx then
      pre = ""
    end

    table.insert(vals, string.format("%s  %s", pre, v:gsub("^%l", string.upper)))
  end

  return table.concat(vals, "  ")
end

---@param form VnixForm
---@param idx number?
local function navigate(form, idx)
  local item = tbl.find_one(form._spec.fields, function(item)
    return item.key == "kind"
  end)

  if not item then
    return
  end

  item.value = types[idx]
  form._spec.help[1] = { { get_type_line(idx), "Bold" } }
  form:reset_help(form._spec.help)
end

---@class VnixNvimRenameHandlerMod
local M = {}

---Handle create Request
---@param req UIMessageRenameReq
function M.handle(req)
  ---@type VnixFormSpec
  local spec = {
    title = "Rename",
    fields = {
      {
        key = "name",
        title = "New name",
        desc = "Please provide new name.",
      },
      {
        key = "kind",
        title = "Type",
        desc = "Type",
        do_not_render = true,
        value = "pane",
      },
    },

    help = {
      { { get_type_line(), "Bold" } },
      { { string.rep("-", 48), "Bold" } },
      { { "󱧡 Help", "Bold" } },
      { { " <leader>p/t/w/a        Quick select type", "Help" } },
      { { " <leader><CR>           Submit", "Help" } },
    },

    keys = {
      ["type-pane"] = {
        "<leader>p",
        desc = "Select Pane",
        function(form)
          navigate(form, 1)
        end,
      },
      ["type-tab"] = {
        "<leader>t",
        desc = "Select Tab",
        function(form)
          navigate(form, 2)
        end,
      },
      ["type-workspace"] = {
        "<leader>w",
        desc = "Select Workspace",
        function(form)
          navigate(form, 3)
        end,
      },
      ["type-all"] = {
        "<leader>a",
        desc = "Select All",
        function(form)
          navigate(form, 4)
        end,
      },
    },
  }

  local form = VnixForm:new(spec, function(result)
    resp.write(resp.create_from_req(req, result))
  end)

  form:run()
end

return M
