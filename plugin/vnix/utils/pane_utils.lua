local M = {}

function M.resolve_size(win, pane_info, state_pane)
  local window_size = win:get_dimensions()
  local width = pane_info.pixel_width
  local height = pane_info.pixel_height

  local percent = {
    width = math.ceil(width / window_size.pixel_width * 100),
    height = math.ceil(height / window_size.pixel_height * 100),
  }

  state_pane.size = { percent = percent, width = width, height = height }
end

return M
