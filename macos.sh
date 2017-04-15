#!/usr/bin/env bash
#===============================================================================
#          File: macos.sh
#        Author: Pedro Ferrari
#       Created: 14 Apr 2017
# Last Modified: 14 Apr 2017
#   Description: Mac OSX (and apps) settings
#===============================================================================
cur_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# iTerm
if [ -d "/Applications/iTerm.app/" ]; then
    onedarkish_iterm="$cur_dir/onedarkish.itermcolors"
    if [ -f "$onedarkish_iterm" ]; then
        defaults write -app iTerm 'Custom Color Presets' -dict-add "onedarkish" "$(cat "$onedarkish_iterm")"
    fi
    defaults write -app iTerm QuitWhenAllWindowsClosed -bool true
fi

# Skim (PDF viewer)
if [ -d "/Applications/Skim.app/" ]; then
    # Auto reload files
    defaults write -app Skim SKAutoReloadFileUpdate -boolean true
    # Syntex (with neovim)
    defaults write -app Skim SKTeXEditorPreset "Custom"
    defaults write -app Skim SKTeXEditorCommand  "nvr"
    defaults write -app Skim SKTeXEditorArguments "--remote-silent +\'\'%line|foldo!\'\' \'\'%file\'\'"
fi
