local org = require("orgmode")
local OrgApiHeadline = require("orgmode.api.headline")

--------------------> Extended OrgApiHeadline <--------------------
---@class OrgApiHeadline
---@field set_todo fun(self: OrgApiHeadline, keyword: string)
function OrgApiHeadline:set_todo(keyword)
  ---@diagnostic disable-next-line: invisible
  self:_do_action(function()
    local headline = org.files:get_closest_headline()
    headline:set_todo(keyword)
  end)
end

---@class OrgApiHeadline
---@field clock_in fun(self: OrgApiHeadline)
function OrgApiHeadline:clock_in()
  ---@diagnostic disable-next-line: invisible
  self:_do_action(function()
    local headline = org.files:get_closest_headline()

    if headline:is_clocked_in() then
      return
    end

    headline:clock_in()
  end)
end

---@class OrgApiHeadline
---@field clock_out fun(self: OrgApiHeadline)
function OrgApiHeadline:clock_out()
  ---@diagnostic disable-next-line: invisible
  self:_do_action(function()
    local headline = org.files:get_closest_headline()

    if not headline:is_clocked_in() then
      return
    end

    headline:clock_out()
  end)
end

---@class OrgApiHeadline
---@field is_clocked_in fun(self: OrgApiHeadline)
function OrgApiHeadline:is_clocked_in()
  ---@diagnostic disable-next-line: invisible
  self:_do_action(function()
    local headline = org.files:get_closest_headline()
    return headline:is_clocked_in()
  end)
end

---@class OrgApiHeadline
---@field toggle_clock fun(self: OrgApiHeadline): OrgPromise
function OrgApiHeadline:toggle_clock()
  ---@diagnostic disable-next-line: invisible
  return self:_do_action(function()
    local headline = org.files:get_closest_headline()
    return headline:is_clocked_in() and headline:clock_out() or headline:clock_in()
  end)
end

---@class OrgApiHeadline
---@field cancel_active_clock fun(self: OrgApiHeadline)
function OrgApiHeadline:cancel_active_clock()
  ---@diagnostic disable-next-line: invisible
  self:_do_action(function()
    local headline = org.files:get_closest_headline()
    return headline:is_clocked_in() and headline:cancel_active_clock()
  end)
end
-------------------------------------------------------------------

return OrgApiHeadline
