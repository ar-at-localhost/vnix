---@module "vnix-common"
local M = {
  VNIX_USER_VAR_NAME = "vnixuservar",
}

function M.obj_to_tbl(obj)
  local numeric = {}

  for k, v in pairs(obj) do
    if k ~= nil then -- Ensure key is not nil
      local num_key = tonumber(k)
      if num_key then
        numeric[num_key] = v
      else
        numeric[k] = v
      end
    end
  end

  return numeric
end

---@cast M VNixCommon
return M
