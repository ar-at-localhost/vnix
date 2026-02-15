local wezterm = require("wezterm")
local mux = wezterm.mux
local tbl = require("common.tbl")

---@alias CreateWorkspaceCb fun(workspace: VnixWorkspaceState)
---@alias AwaitGuiWindowCb fun()

---@class VnixMuxMod
---@field create_workspace fun(arg: VnixWorkspace, cb: CreateWorkspaceCb)  Create a workspace
---@field create_tab fun(arg: VnixTab, win: string | MuxWindow, workspace: string?): VnixTabState Create a new tab
---@field _split_pane fun(arg: VnixPaneState, pane: Pane): VnixPaneState Split an exisitng pane (recursive)
---@field split_pane fun(arg: VnixPaneState, dir: 'Right' | 'Bottom', pane: Pane): VnixPaneState, Pane Split a pane
---@field gui_window? Window Obtained GUI Window
---@field _await_gui_window fun(win: MuxWindow, cb: AwaitGuiWindowCb, _attempt?: number, _switch_requested?: boolean) Wait for gui window to be attached
---@field normalize_args fun(args: string | string[] | nil): { paste?: string, args: string[] | nil}
---@field resolve_gui_window fun(workspace?: string): Window | nil Attempt to find GUI Window
local M = {} ---@type VnixMuxMod

function M.create_workspace(arg, cb)
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
    set_environment_variables = tbl.merge_all(
      arg.env or {},
      first_tab.env or {},
      first_pane.env or {}
    ),
  })

  M._await_gui_window(win, function()
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
    copy.tabs[1].id = copy.tabs[1].pane.tab_id
    copy.tabs[1].pane = M._split_pane(copy.tabs[1].pane, pane)
    copy.id = win:get_workspace() or arg.name

    for i = 2, #arg.tabs do
      copy.tabs[i] = M.create_tab(arg.tabs[i], win, copy.id)
      copy.tabs[i].idx = i
    end

    cb(copy)
  end)
end

function M.create_tab(arg, win, workspace)
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
  copy.pane.workspace = workspace
  copy.pane.tab_id = copy.id
  copy.pane = M._split_pane(copy.pane, pane)
  return copy
end

function M.split_pane(arg, dir, pane)
  local new_pane = pane:split({
    direction = dir,
    workspace = arg.workspace,
    args = arg.args or nil,
    set_environment_variables = arg.env,
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
    local child = copy[first]
    child.workspace = copy.workspace
    child.tab = copy.tab
    child.tab_id = copy.tab_id
    child, split = M.split_pane(child, first:gsub("^%l", string.upper), pane)
    copy[first] = M._split_pane(child, split)
  end

  if second and arg[second] then
    local split
    local child = copy[second]
    child.workspace = copy.workspace
    child.tab = copy.tab
    child.tab_id = copy.tab_id
    child, split = M.split_pane(child, second:gsub("^%l", string.upper), pane)
    copy[second] = M._split_pane(child, split)
  end

  return copy
end

function M._await_gui_window(win, func, _attempts, switch_requested)
  _attempts = _attempts or 0
  if _attempts > 60 then
    wezterm.log_error("vnix: gave up waiting for gui_window")
    return
  end

  local ok, gui_window = pcall(function()
    local gui_win = win:gui_window()
    if not gui_win then
      return nil
    end
    return gui_win
  end)

  if ok and gui_window then
    M.gui_window = gui_window
    gui_window:maximize()
    func()
    return
  elseif M.gui_window and not switch_requested then
    M.gui_window:perform_action(
      wezterm.action.SwitchToWorkspace({
        name = win:get_workspace(),
      }),
      M.gui_window:active_pane()
    )

    switch_requested = true
  end

  wezterm.time.call_after(1, function()
    M._await_gui_window(win, func, _attempts + 1, switch_requested)
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

function M.resolve_gui_window(workspace)
  local mux_windows = mux.all_windows()

  for _, w in ipairs(mux_windows) do
    local active_workspace = w:get_workspace()

    local ok, win = pcall(function()
      return w:gui_window()
    end)

    if ok and (not workspace or active_workspace == workspace) then
      return win
    end
  end
end

return M
