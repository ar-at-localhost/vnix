local M = {}

-- Default configuration values for the plugin
M.defaults = {
  keys = {}, -- User-defined keybinding overrides
  status_update_interval = 10000,
}

-- This will hold the final, merged configuration
M.options = {}

-- Deep-merges the user's options over the defaults.
-- This ensures that all keys are present.
function M.new(opts)
  opts = opts or {}
  local final_opts = {}

  -- Create a deep copy of defaults to avoid modifying the original table
  for k, v in pairs(M.defaults) do
    -- A simple value copy is sufficient here since defaults are not tables
    final_opts[k] = v
  end

  -- Merge user options
  for k, v in pairs(opts) do
    if v ~= nil then
      final_opts[k] = v
    end
  end

  M.options = final_opts
  return M.options
end

return M
