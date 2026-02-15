-- Hammerspoon Configuration

-- ============================================
-- GHOSTTY WINDOW POSITION SETTINGS
-- ============================================
GHOSTTY_X = 3676
GHOSTTY_Y = 37
GHOSTTY_WIDTH = 1432
GHOSTTY_HEIGHT = 1391
-- ============================================

-- Reload config automatically when this file changes
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "R", function()
  hs.reload()
end)
hs.alert.show("Hammerspoon Config Loaded")

-- DEBUG: Show current window position/size
-- Press Cmd+Alt+Ctrl+W to see focused window's frame info
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "W", function()
  local win = hs.window.focusedWindow()
  if win then
    local frame = win:frame()
    local screen = win:screen():frame()
    
    local info = string.format(
      "Window Frame:\n" ..
      "x: %d (%.1f%% of screen)\n" ..
      "y: %d\n" ..
      "width: %d (%.1f%% of screen)\n" ..
      "height: %d\n\n" ..
      "Screen: %dx%d",
      frame.x, (frame.x / screen.w) * 100,
      frame.y,
      frame.w, (frame.w / screen.w) * 100,
      frame.h,
      screen.w, screen.h
    )
    
    hs.alert.show(info, 10)
    print(info)
  else
    hs.alert.show("No focused window")
  end
end)

-- Toggle Ghostty with Cmd+Return
-- Uses exact position/size defined at top of file
hs.hotkey.bind({"cmd"}, "return", function()
  local app = hs.application.get("Ghostty")
  
  local function positionWindow()
    local win = app:mainWindow()
    if win then
      win:setFrame({
        x = GHOSTTY_X,
        y = GHOSTTY_Y,
        w = GHOSTTY_WIDTH,
        h = GHOSTTY_HEIGHT
      })
    end
  end
  
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
      positionWindow()
    end
  else
    hs.application.open("Ghostty")
    -- Wait for window to appear, then position it
    hs.timer.doAfter(0.5, function()
      app = hs.application.get("Ghostty")
      if app then
        positionWindow()
        hs.timer.doAfter(0.5, function()
          hs.eventtap.keyStrokes("clear && fastfetch && ll")
          hs.eventtap.keyStroke({}, "return")
        end)
      end
    end)
  end
end)
