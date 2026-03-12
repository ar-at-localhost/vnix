local wezterm = require("wezterm")
local mux = wezterm.mux
local tbl = require("common.tbl")

---@class VnixMuxMod
---@field create_workspace fun(arg: VnixWorkspace): VnixWorkspaceState, MuxWindow  Create a workspace
---@field _split_pane fun(arg: VnixPaneState, pane: Pane): VnixPaneState Split an exisitng pane (recursive)
---@field split_pane fun(arg: VnixPaneState, dir: 'Right' | 'Bottom', pane: Pane): VnixPaneState, Pane Split a pane
---@field await_gui_window fun(win: MuxWindow, cb: fun(win: Window), _attempt?: number, _switch_requested?: boolean) Wait for gui window to be attached
---@field normalize_args fun(args: string | string[] | nil): { paste?: string, args: string[] | nil}
local M = {} ---@type VnixMuxMod

function M.create_workspace(arg)
  local copy = tbl.deep_copy(arg) ---@type VnixWorkspaceState
  local first_tab = arg.tabs[1]

  if not first_tab then
    error(string.format("No tab defined in workspace %s!", arg.name))
  end

  local tab, pane, win ---@type MuxTab, Pane, MuxWindow
  local first_pane = first_tab.pane
  local args_opts = M.normalize_args(first_pane.args)

  tab, pane, win = mux.spawn_window({
    workspace = arg.name,
    args = args_opts.args,
    cwd = arg.cwd,
    set_environment_variables = tbl.merge_all(
      arg.env or {},
      first_tab.env or {},
      first_pane.env or {}
    ),
  })

  if not tab or not pane or not win then
    wezterm.log_error("Error creating workspace:", pane, tab, win)
    error("Unable to create workspace!")
  end

  tab:set_title(first_pane.name)
  if args_opts.paste then
    pane:send_paste(args_opts.paste)
  end

  copy.tabs[1].idx = 0
  copy.tabs[1].pane.id = pane:pane_id()
  copy.tabs[1].pane.idx = 0
  copy.tabs[1].pane.tab = first_tab.name
  copy.tabs[1].pane.workspace = arg.name
  copy.tabs[1].pane.tab_id = tab:tab_id()
  copy.tabs[1].pane.tab_idx = copy.tabs[1].idx
  copy.tabs[1].id = copy.tabs[1].pane.tab_id
  copy.tabs[1].pane = M._split_pane(copy.tabs[1].pane, pane)
  copy.id = win:get_workspace() or arg.name

  for i = 2, #arg.tabs do
    copy.tabs[i].cwd = copy.tabs[i].cwd or copy.cwd
    copy.tabs[i] = M.create_tab(arg.tabs[i], win, copy.id, i - 1)
    copy.tabs[i].idx = i
  end

  return copy, win
end

---VnixTabState Create a new tab
---@param arg VnixTab
---@param win string | MuxWindow
---@param workspace string
---@param idx integer
function M.create_tab(arg, win, workspace, idx)
  idx = idx or 0
  local first_pane = arg.pane

  if not first_pane then
    error(string.format("No pane defined in tab %s!", arg.name))
  end

  local windows = mux.all_windows()
  local window ---@type MuxWindow

  if type(win) == "string" then
    for _, v in ipairs(windows) do
      if v:get_workspace() == win then
        window = v
      end
    end
  elseif win then
    window = win
  end

  if not window then
    if type(win) == "string" then
      error(string.format("No window found for workspace %s!", win))
    else
      error("Invalid window provided!")
    end
  end

  local arg_opts = M.normalize_args(first_pane.args)

  local tab, pane, _ = window:spawn_tab({
    cwd = arg.cwd,
    args = arg_opts.args,
    set_environment_variables = tbl.merge_all(arg.env or {}, first_pane.env or {}),
  })

  tab:set_title(arg.name)
  if arg_opts.paste then
    pane:send_paste(arg_opts.paste)
  end

  local copy = tbl.deep_copy(arg) ---@type VnixTabState
  copy.id = tab:tab_id()
  copy.pane.name = arg.pane.name
  copy.pane.id = pane:pane_id()
  copy.pane.tab = copy.name
  copy.pane.tab_id = copy.id
  copy.pane.tab_idx = idx
  copy.pane.workspace = workspace
  copy.pane.cwd = copy.pane.cwd or copy.cwd
  copy.pane = M._split_pane(copy.pane, pane)
  return copy
end

function M.split_pane(arg, dir, pane)
  local new_pane = pane:split({
    direction = dir,
    workspace = arg.workspace,
    args = arg.args or nil,
    set_environment_variables = arg.env,
    cwd = arg.cwd,
  })

  local copy = tbl.deep_copy(arg) ---@type VnixPaneState
  copy.id = new_pane:pane_id()
  return copy, new_pane
end

function M._split_pane(arg, pane)
  local first = (
    arg.first_split
    and type(arg.first_split) == "string"
    and string.lower(arg.first_split)
  )
    or (arg.right and "right")
    or (arg.bottom and "bottom")

  if first and first ~= "right" and first ~= "bottom" then
    first = "right"
  end

  local second = first == "right" and "bottom" or "right"
  local copy = tbl.deep_copy(arg) ---@type VnixPaneState

  if first and arg[first] then
    local split
    local child = copy[first] ---@type VnixPaneState
    child.workspace = copy.workspace
    child.tab = copy.tab
    child.tab_id = copy.tab_id
    child.tab_idx = copy.tab_idx
    child.cwd = child.cwd or copy.cwd
    child, split = M.split_pane(child, first:gsub("^%l", string.upper), pane)
    copy[first] = M._split_pane(child, split)
  end

  if second and arg[second] then
    local split
    local child = copy[second] ---@type VnixPaneState
    child.workspace = copy.workspace
    child.tab = copy.tab
    child.tab_id = copy.tab_id
    child.tab_idx = copy.tab_idx
    child.cwd = child.cwd or copy.cwd
    child, split = M.split_pane(child, second:gsub("^%l", string.upper), pane)
    copy[second] = M._split_pane(child, split)
  end

  return copy
end

function M.await_gui_window(win, func, _attempts)
  _attempts = _attempts or 0
  if _attempts > 60 then
    wezterm.log_error("vnix: gave up waiting for gui_window")
    return
  end

  local ok, gui_window = pcall(function()
    local gui_win = win:gui_window()
    gui_win:window_id()
    return gui_win
  end)

  if ok and gui_window then
    return func(gui_window)
  end

  wezterm.time.call_after(1, function()
    M.await_gui_window(win, func, _attempts + 1)
  end)
end

function M.normalize_args(args)
  if not args then
    return {
      args = nil,
    }
  end

  if type(args) == "string" then
    return {
      args = { args },
    }
  end

  if type(args) == "table" then
    if args[1] == ":" then
      return {
        paste = table.concat(tbl.slice(args, 2), " "),
      }
    end

    return {
      args = args,
    }
  end

  return {
    args = nil,
  }
end

---resolve_gui_window fun(): Window | nil Attempt to find GUI Window
---@param arg? string | integer Either workspace name or GUI Window ID (Optional, omit to resolve any)
---@return Window|nil
function M.resolve_gui_window(arg)
  local mux_windows = mux.all_windows()

  for _, w in ipairs(mux_windows) do
    local active_workspace = w:get_workspace()

    local ok, win = pcall(function()
      return w:gui_window()
    end)

    if
      ok
      and win
      and (
        not arg
        or (
          (type("arg") == "string" and active_workspace == arg)
          or (type("arg") == "number" and win:window_id() == arg)
        )
      )
    then
      return win
    end
  end
end

---Resolve pane by id or return the first if ID not specified
---@param id number?
---@param check? fun(pane: Pane, tab: MuxTab, win: MuxWindow): boolean
---@return Pane?, MuxTab?, MuxWindow?
function M.find_pane(id, check)
  for _, w in ipairs(mux.all_windows()) do
    for _, t in ipairs(w:tabs()) do
      for _, p in ipairs(t:panes_with_info()) do
        if (not id or p.pane:pane_id() == id) and (not check or check(p.pane, t, w)) then
          return p.pane, t, w
        end
      end
    end
  end

  return nil, nil, nil
end

---Get active mux window
---@param workspace string?
---@return MuxWindow?
function M.find_win(workspace)
  local name = workspace or mux:get_active_workspace()
  local all_windows = mux.all_windows()

  for _, v in ipairs(all_windows) do
    if v:get_workspace() == name then
      return v
    end
  end
end

---Find Mux tab
---@param id number Wezterm Tab ID
---@return MuxTab? tab Mux Tab
---@return integer? idx Tab index (0-based)
---@return MuxWindow? win Mux Window
function M.find_tab(id)
  local all_windows = mux.all_windows()

  for _, w in ipairs(all_windows) do
    for i, t in ipairs(w:tabs()) do
      if t:tab_id() == id then
        return t, i - 1, w
      end
    end
  end
end

return M
