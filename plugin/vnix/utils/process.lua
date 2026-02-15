-- process.lua
local M = {}

-- Detect platform
local is_windows = package.config:sub(1, 1) == "\\"
local win_exts = { ".exe", ".bat", ".cmd", ".com" }

-- Check if file exists
local function file_exists(path)
  local f = io.open(path, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

--- Resolve a program from PATH
-- @return string|nil Absolute path if found, otherwise nil
function M.resolve_program(prog)
  local path_var = os.getenv("PATH") or ""
  local sep = is_windows and ";" or ":"

  for dir in path_var:gmatch("([^" .. sep .. "]+)") do
    if is_windows then
      for _, ext in ipairs(win_exts) do
        local candidate = dir .. "\\" .. prog .. ext
        if file_exists(candidate) then
          return candidate
        end
      end
      local candidate = dir .. "\\" .. prog
      if file_exists(candidate) then
        return candidate
      end
    else
      local candidate = dir .. "/" .. prog
      if file_exists(candidate) then
        return candidate
      end
    end
  end

  return nil
end

--- Run a child process using pipes
-- Works safely in both config load and runtime phases
-- @param args table command + arguments
-- @param cwd string|nil working directory
-- @return ok:boolean, stdout:string|nil, stderr:string|nil
function M.run_child(args, cwd)
  if not args or #args == 0 then
    return false, nil, "no command provided"
  end

  local cmd = table.concat(args, " ")
  if cwd then
    cmd = string.format("cd %s && %s", cwd, cmd)
  end

  -- Merge stderr into stdout so we always capture errors
  local pipe = io.popen(cmd .. " 2>&1")
  if not pipe then
    return false, nil, "failed to run command"
  end
  local out = pipe:read("*a")
  pipe:close()
  return true, out, nil
end

return M
