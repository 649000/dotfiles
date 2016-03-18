--==============================================================================
--          File: init.lua
--        Author: Pedro Ferrari
--       Created: 13 Mar 2016
-- Last Modified: 18 Mar 2016
--   Description: My Hammerspoon config file
--==============================================================================
-- See https://github.com/Hammerspoon/hammerspoon/wiki/Sample-Configurations
-- for configuration examples

-- Modifier shortcuts
local cmd_ctrl = {"ctrl", "cmd"}

-- Reload (auto) hotkey script
hs.hotkey.bind(cmd_ctrl, "A", function()
  hs.reload()
  hs.alert.show("Hammerspoon config was reloaded.")
end)

-- Don't perform animations when resizing
hs.window.animationDuration = 0

-- Get list of screens and refresh that list whenever screens are plugged or
-- unplugged:
local screens = hs.screen.allScreens()
local screenwatcher = hs.screen.watcher.new(function()
                                                screens = hs.screen.allScreens()
                                            end)
screenwatcher:start()

-- Resize window for chunk of screen (this deprecates Spectable)
-- For x and y: use 0 to expand fully in that dimension, 0.5 to expand halfway
-- For w and h: use 1 for full, 0.5 for half
function resize_win(x, y, w, h)
	local win = hs.window.focusedWindow()
	local f = win:frame()
	local screen = win:screen()
	local max = screen:frame()

	f.x = max.x + (max.w * x)
	f.y = max.y + (max.h * y)
	f.w = max.w * w
	f.h = max.h * h
	win:setFrame(f)
end
hs.hotkey.bind({"cmd"}, "left", function()
                resize_win(0,0,0.5,1) end) -- left
hs.hotkey.bind({"cmd"}, "right", function()
                resize_win(0.5,0,0.5,1) end) -- right
hs.hotkey.bind(cmd_ctrl, "up", function()
                resize_win(0,0,1,0.5) end) -- top
hs.hotkey.bind(cmd_ctrl, "down", function()
                resize_win(0,0.5,1,0.5) end) -- bottom
hs.hotkey.bind({"cmd"}, "up", function()
                resize_win(0,0,1,1) end) -- full
hs.hotkey.bind(cmd_ctrl, "1", function()
                resize_win(0,0,0.5,0.5) end) -- Top left quarter
hs.hotkey.bind(cmd_ctrl, "2", function()
                resize_win(0,0.5,0.5,0.5) end) -- Bottom left quarter
hs.hotkey.bind(cmd_ctrl, "3", function()
                resize_win(0.5,0,0.5,0.5) end) -- Top right quarter
hs.hotkey.bind(cmd_ctrl, "4", function()
                resize_win(0.5,0.5,0.5,0.5) end) -- Bottom right quarter
hs.hotkey.bind(cmd_ctrl, "5", function()
                resize_win(0.25,0.25,0.5,0.5) end) -- Center


-- Resize window width (setting the grid first)
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0
hs.grid.GRIDWIDTH = 10
hs.grid.GRIDHEIGHT = 2
hs.hotkey.bind(cmd_ctrl, "-", function()
    hs.grid.resizeWindowThinner(hs.window.focusedWindow())
end)
hs.hotkey.bind(cmd_ctrl, "=", function()
    hs.grid.resizeWindowWider(hs.window.focusedWindow())
end)

-- Move window to next/previous monitor (checks to make sure monitor exists, if
-- not moves to last monitor that exists)
function moveToMonitor(x)
	local win = hs.window.focusedWindow()
	local newScreen = nil
	while not newScreen do
		newScreen = screens[x]
		x = x - 1
	end
	win:moveToScreen(newScreen)

    -- Also move the mouse to center of next screen
    local center = hs.geometry.rectMidPoint(newScreen:fullFrame())
    hs.mouse.setAbsolutePosition(center)
end
hs.hotkey.bind(cmd_ctrl,"right", function() moveToMonitor(2) end)
hs.hotkey.bind(cmd_ctrl,"left", function() moveToMonitor(1) end)


-- Switch focus and mouse to the next monitor
-- Preload hs.application to avoid problems when switching monitor focus
local application = require "hs.application"
function windowInScreen(screen, win) -- Check if a window belongs to a screen
    return win:screen() == screen
end
function focusNextScreen()
    -- Get next screen (and its center point) using current mouse position
    -- local next_screen = hs.window.focusedWindow():screen():next()
    local next_screen = hs.mouse.getCurrentScreen():next()
    local center = hs.geometry.rectMidPoint(next_screen:fullFrame())

    -- Find windows within this next screen, ordered from front to back.
    windows = hs.fnutils.filter(hs.window.orderedWindows(),
                                hs.fnutils.partial(windowInScreen, next_screen))

    -- Move the mouse to the center of the other screen
    hs.mouse.setAbsolutePosition(center)

    --  Set focus on front-most application window or bring focus to desktop if
    --  no windows exists
    if #windows > 0 then
        windows[1]:focus()
    else
        hs.window.desktop():focus()
        -- In this case also do a click to activate menu bar
        hs.eventtap.leftClick(hs.mouse.getAbsolutePosition())
    end
end
hs.hotkey.bind({"alt"}, "§", focusNextScreen)
hs.hotkey.bind({"alt"}, "`", focusNextScreen)


-- Run or activate applications (this deprecates Apptivate)
hs.hotkey.bind(cmd_ctrl, "v", function()
                hs.application.launchOrFocus("Macvim") end)
hs.hotkey.bind(cmd_ctrl, "c", function()
                hs.application.launchOrFocus("Iterm") end)
hs.hotkey.bind(cmd_ctrl, "i", function()
                hs.application.launchOrFocus("Firefox") end)
hs.hotkey.bind(cmd_ctrl, "x", function()
                hs.application.launchOrFocus("Microsoft Excel") end)
hs.hotkey.bind(cmd_ctrl, "g", function()
                hs.application.launchOrFocus("GifGrabber") end)
hs.hotkey.bind(cmd_ctrl, "s", function()
                hs.application.launchOrFocus("Skype") end)
hs.hotkey.bind(cmd_ctrl, "l", function()
                hs.application.launchOrFocus("Slack") end)
hs.hotkey.bind(cmd_ctrl, "p", function()
                hs.application.launchOrFocus("Skim") end)
hs.hotkey.bind(cmd_ctrl, "e", function()
                hs.application.launchOrFocus("Finder") end)
hs.hotkey.bind(cmd_ctrl, "t", function()
                hs.application.launchOrFocus("Thunderbird") end)
hs.hotkey.bind(cmd_ctrl, "d", function()
                hs.execute("open /Users/Pedro/Downloads/") end)

-- Vim specific
hs.hotkey.bind(cmd_ctrl, "m", function()
                                os.execute("/usr/local/bin/mvim -u " ..
                                "/Users/Pedro/OneDrive/vimfiles/vimrc_min &")
                            end)

-- Restart Vim and load previous session
hs.hotkey.bind(cmd_ctrl, "r", function()
                hs.eventtap.keyStrokes(",kv")
                hs.eventtap.keyStroke({"cmd"}, "N")
                hs.timer.doAfter(3, function()
                                        hs.eventtap.keyStrokes(",ps") end)
                end)


-- Toggle hidden files
hs.hotkey.bind(cmd_ctrl, "h", function()
    hidden_status = hs.execute("defaults read com.apple.finder " ..
                                "AppleShowAllFiles")
    if hidden_status == "YES\n"  then
        hs.execute("defaults write com.apple.finder AppleShowAllFiles NO")
    else
        hs.execute("defaults write com.apple.finder AppleShowAllFiles YES")
    end
    hs.execute("killall Finder")
end)

-- Expose (show thumbnails of open windows with a hint; kind of deprecates
-- Hyperswitch)
hs.expose.ui.otherSpacesStripWidth = 0  -- I don't use other spaces
hs.expose.ui.highlightThumbnailStrokeWidth = 5
hs.expose.ui.textSize = 30
hs.expose.ui.nonVisibleStripWidth = 0.2
hs.expose.ui.nonVisibleStripBackgroundColor = {0.08, 0.08, 0.08}
hs.hotkey.bind(cmd_ctrl, "j", function()
                hs.expose.new():toggleShow() end)

-- Active window screenshot
hs.hotkey.bind({"shift", "cmd"}, "5", function()
                local image = hs.window.focusedWindow():snapshot()
                local current_time = os.date("%Y-%m-%d %H.%M.%S")
                local screenshot_dir = os.getenv("HOME") ..
                                        "/Pictures/Screenshots/"
                local filename = screenshot_dir .. "Screen Shot " ..
                                    current_time .. ".png"
                -- FIXME: The following gives an error
                -- image:saveToFile(filename)
                hs.alert("Screenshot saved as " .. filename)
            end)


-- TODO: Shutdown, restart and clear bin, also toggle hidden files
-- hs.hotkey.bind({"shift", "cmd"}, "r", function()
                -- hs.caffeinate.restartSystem() end)
hs.hotkey.bind({"shift", "cmd"}, "p", function()
                hs.caffeinate.shutdownSystem() end)


function YesNoDialogBox(ActionFunc)
	test = hs.chooser.new(ActionFunc)
    test:rows(2)
    test:choices({{["text"] = "Yes", ["subText"] = "", ["id"] = "yes"},
                {["text"] = "No", ["subText"] = "", ["id"] = "no"}})
    test:show()
end
function RebootIfChoice(input)
    if input.id == "yes" then
        hs.alert("Your choice was: yes")
    else
        hs.alert("Your choice was: no")
    end
end
hs.hotkey.bind({"shift", "cmd"}, "r", function() YesNoDialogBox(RebootIfChoice) end)
