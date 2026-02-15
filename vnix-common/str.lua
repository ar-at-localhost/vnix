---@class StringUtils
---@field pad_right fun(str: string | nil, target_len: number, char?: string): string Pad string on the right to target length.
---@field pad_left fun(str: string | nil, target_len: number, char?: string): string Pad string on the left to target length.
---@field pad fun(str: string | nil, target_len: number, char?: string, ellipsis?: string): string Center pad string to target length. If string is longer than target_len, it will ellipsify.
local M = {} ---@type StringUtils

---@private
---@param char string
---@param n number
---@return string
local function repeat_char(char, n)
  if n <= 0 then
    return ""
  end
  return string.rep(char, n)
end

---@private
---@param char string|nil
---@return string
local function normalize_char(char)
  if not char or char == "" then
    return " "
  end
  return char:sub(1, 1)
end

---@param str string
---@param target_len number
---@param char? string Padding character (default: space)
---@return string
function M.pad_right(str, target_len, char)
  str = tostring(str or "")
  char = normalize_char(char)

  local len = #str
  if len >= target_len then
    return str
  end

  return str .. repeat_char(char, target_len - len)
end

---@param str string
---@param target_len number
---@param char? string Padding character (default: space)
---@return string
function M.pad_left(str, target_len, char)
  str = tostring(str or "")
  char = normalize_char(char)

  local len = #str
  if len >= target_len then
    return str
  end

  return repeat_char(char, target_len - len) .. str
end

---@param str string
---@param target_len number
---@param char? string Padding character (default: space)
---@param ellipsis? string Ellipsis string (default: "...")
---@return string
function M.pad(str, target_len, char, ellipsis)
  str = tostring(str or "")
  char = normalize_char(char)
  ellipsis = ellipsis or "..."

  local len = #str

  -- Oversized: ellipsify
  if len > target_len then
    if target_len <= #ellipsis then
      return ellipsis:sub(1, target_len)
    end

    local visible = target_len - #ellipsis
    return str:sub(1, visible) .. ellipsis
  end

  -- Exact
  if len == target_len then
    return str
  end

  -- Center pad
  local total_padding = target_len - len
  local left = math.floor(total_padding / 2)
  local right = total_padding - left

  return repeat_char(char, left) .. str .. repeat_char(char, right)
end

return M
