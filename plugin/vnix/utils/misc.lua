local wezterm = require("wezterm")
local log = require("vnix.utils.log")
local misc = {}

function misc.args_table_to_str(args)
  if not args or not args[1] then
    return ""
  end

  local str_args = table.concat(args, " ")
  return str_args
end

function misc.handle_args(vnix, settings)
  if not vnix or not vnix.shell or not settings.args then
    return nil, nil
  end

  local args = settings.args
  local mode = settings.args_mode or ""
  local lazy = nil
  local shell = true
  local str_args = ""

  if (type(args) == "table" and #args > 0) or (type(args) == "userdata") then
    str_args = misc.args_table_to_str(args)
  elseif type(args) == "string" then
    str_args = args
  end

  if not #str_args then
    log.log(
      "WARN",
      "vnix: skipping empty args: args => "
        .. wezterm.json_encode(args)
        .. " str_args => "
        .. str_args
    )

    return nil, nil
  end

  if not string.find(mode, "s") then
    shell = false
  end

  if string.find(mode, "l") then
    lazy = true
  end

  local cmd = ""

  if settings.cwd then
    cmd = "cd " .. settings.cwd .. "&&"
  end

  if shell then
    local shell_args = {
      vnix.shell,
      "-l",
      "-i",
    }

    if not lazy then
      cmd = cmd .. str_args .. "&&"
    end

    cmd = cmd .. vnix.shell .. " -li;"

    if #cmd > 0 then
      table.insert(shell_args, "-c")
      table.insert(shell_args, cmd)
    end

    args = shell_args
  end

  if lazy then
    local lazy_cmd = str_args .. "\r"

    if #cmd > 0 and not shell then
      lazy_cmd = cmd + lazy_cmd
    end

    lazy = lazy_cmd
  end

  return args, lazy
end

function misc.keys_to_num(t)
  -- Validate input parameter
  if not t then
    log.log("WARN", "misc: Invalid table provided to keys_to_num")
  end

  local numeric = {}
  local convert_ok, convert_err = pcall(function()
    for k, v in pairs(t) do
      if k ~= nil then -- Ensure key is not nil
        local num_key = tonumber(k)
        if num_key then
          numeric[num_key] = v
        else
          numeric[k] = v
        end
      end
    end
  end)

  if not convert_ok then
    log.log("ERROR", "misc: Error converting keys to numbers: " .. tostring(convert_err))
    return {}
  end

  return numeric
end

function misc.deep_extend(orig, new_tbl)
  -- Validate input parameters
  if not orig then
    log.log("ERROR", "misc: Invalid orig table provided to deep_extend")
    return new_tbl or {}
  end

  if not new_tbl then
    log.log("WARN", "misc: Invalid new_tbl provided to deep_extend, returning original")
    return orig
  end

  local extend_ok, extend_err = pcall(function()
    for k, v in pairs(new_tbl) do
      if k ~= nil then -- Ensure key is not nil
        if v and orig[k] then
          -- Recursive deep extend with protection against circular references
          local recursion_ok, recursion_err = pcall(function()
            misc.deep_extend(orig[k], v)
          end)
          if not recursion_ok then
            log.log(
              "WARN",
              "misc: Recursion error in deep_extend, using shallow copy: "
                .. tostring(recursion_err)
            )
            orig[k] = v
          end
        else
          orig[k] = v
        end
      end
    end
  end)

  if not extend_ok then
    log.log("ERROR", "misc: Error in deep_extend: " .. tostring(extend_err))
  end

  return orig
end

return misc
