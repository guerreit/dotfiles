#!/bin/zsh
# Script to set Solarized Dark theme for macOS Terminal and adjust font size and window

# Download Solarized Dark Terminal theme from a working source
theme_url="https://github.com/mbadolato/iTerm2-Color-Schemes/raw/master/terminal/Solarized%20Dark.terminal"
theme_file="Solarized Dark.terminal"
curl -fsSL "$theme_url" -o "$theme_file"

# Open the theme to import into Terminal.app
open "$theme_file"

echo "Please wait a few seconds for Terminal to import the theme."

echo "When the Solarized Dark theme window appears, click 'Default' at the bottom to set it as default, then press Enter here."
read -r _

# Try to set Solarized Dark as the default profile, set font size, and make window full screen using AppleScript
osascript <<EOD
tell application "Terminal"
    set themeName to "Solarized Dark"
    set themeExists to false
    repeat with t in (get the name of every settings set)
        if t as string is equal to themeName then
            set themeExists to true
            exit repeat
        end if
    end repeat
    if themeExists then
        set default settings to settings set themeName
        set current settings of tabs of windows to settings set themeName
        -- Set font size to 16 for all windows and tabs
        repeat with w in windows
            repeat with t in tabs of w
                set font name of settings of t to "Menlo-Regular"
                set font size of settings of t to 16
            end repeat
        end repeat
        -- Set window size to 250 columns by 60 rows for all windows
        repeat with w in windows
            set number of columns of w to 250
            set number of rows of w to 60
        end repeat
        -- Make the front window full screen
        try
            set frontmost to true
            tell application "System Events"
                keystroke "f" using {control down, command down}
            end tell
        end try
    else
        display dialog "Solarized Dark profile not found. Please import it manually and try again." buttons {"OK"}
    end if
end tell
EOD

echo "If you still don't see Solarized Dark as your default, open Terminal Preferences > Profiles and set it manually."
