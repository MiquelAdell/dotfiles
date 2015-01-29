-- Load Extensions
local application = require "mjolnir.application"
local window = require "mjolnir.window"
local hotkey = require "mjolnir.hotkey"
local keycodes = require "mjolnir.keycodes"
local fnutils = require "mjolnir.fnutils"
local alert = require "mjolnir.alert"
local screen = require "mjolnir.screen"
-- User packages
local grid = require "mjolnir.bg.grid"
local hints = require "mjolnir.th.hints"
local appfinder = require "mjolnir.cmsj.appfinder"

local definitions = nil
local hyper = nil

local gridset = function(frame)
  return function()
    local win = window.focusedwindow()
    if win then
      grid.set(win, frame, win:screen())
    else
      alert.show("No focused window.")
    end
  end
end

auxWin = nil
function saveFocus()
  auxWin = window.focusedwindow()
  alert.show("Window '" .. auxWin:title() .. "' saved.")
end
function focusSaved()
  if auxWin then
    auxWin:focus()
  end
end

local hotkeys = {}

function createHotkeys()
  for key, fun in pairs(definitions) do
    local mod = hyper
    if string.len(key) == 2 and string.sub(key,2,2) == "c" then
      mod = {"cmd"}
    end
    
    local hk = hotkey.new(mod, string.sub(key,1,1), fun)
    table.insert(hotkeys, hk)
    hk:enable()
  end
end

function rebindHotkeys()
  for i, hk in ipairs(hotkeys) do
    hk:disable()
  end
  hotkeys = {}
  createHotkeys()
  alert.show("Rebound Hotkeys")
end

function applyPlace(win, place)
  local scrs = screen:allscreens()
  local scr = scrs[place[1]]
  grid.set(win, place[2], scr)
end

function applyLayout(layout)
  return function()
    for appName, place in pairs(layout) do
      local app = appfinder.app_from_name(appName)
      if app then
        for i, win in ipairs(app:allwindows()) do
          applyPlace(win, place)
        end
      end
    end
  end
end

function init()
  createHotkeys()
  keycodes.inputsourcechanged(rebindHotkeys)
  alert.show("Mjolnir, at your service.")
end

-- Actual config =================================

hyper = {"cmd", "shift", "ctrl"}
-- Set grid size.
grid.GRIDWIDTH  = 6
grid.GRIDHEIGHT = 8
grid.MARGINX = 0
grid.MARGINY = 0
local gw = grid.GRIDWIDTH
local gh = grid.GRIDHEIGHT


local goleft = {x = 0, y = 0, w = gw/2, h = gh}
local goright = {x = gw/2, y = 0, w = gw/2, h = gh}
local gobig = {x = 0, y = 0, w = gw, h = gh}
local gomiddle = {x = 1, y = 1, w = 4, h = 6}

local quarter1 = {x = 0,    y = 0,    w = gw/2, h = gh/2}
local quarter2 = {x = gw/2, y = 0,    w = gw/2, h = gh/2}
local quarter3 = {x = 0,    y = gh/2, w = gw/2, h = gh/2}
local quarter4 = {x = 0,    y = gh/2, w = gw/2, h = gh/2}

local fullApps = {
  "Safari","Aurora","Nightly","Xcode","Qt Creator","Google Chrome",
  "Google Chrome Canary", "Eclipse", "Coda 2", "iTunes", "Emacs", "Firefox"
}
local layout2 = {
  Mail = {1, gomiddle},
  Spotify = {1, gomiddle},
  Calendar = {1, gomiddle},
  Dash = {1, gomiddle},
}
fnutils.each(fullApps, function(app) layout2[app] = {1, gobig} end)

definitions = {
  i = saveFocus,
  o = focusSaved,
  
  x = gridset(gomiddle),
  a = gridset(goleft),
  s = grid.maximize_window,
  d = gridset(goright),
  
  u = gridset(quarter1),
  i = gridset(quarter2),
  o = gridset(quarter3),
  p = gridset(quarter4),
  
  l = applyLayout(layout2),
  
  z = grid.pushwindow_nextscreen,
  r = mjolnir.reload,
  q = function() appfinder.app_from_name("Mjolnir"):kill() end,

  v = function() hints.appHints(window.focusedwindow():application()) end,
  c = hints.windowHints
}

-- launch and focus applications
fnutils.each({
  { key = "e", app = "Google Chrome" },
  { key = "u", app = "Atom" },
  { key = "i", app = "Terminal" }
  }, function(object)
    definitions[object.key] = function() application.launchorfocus(object.app) end
    end)
    
    init()