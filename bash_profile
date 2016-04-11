#===============================================================================
#          File: bash_profile
#        Author: Pedro Ferrari
#       Created: 11 Apr 2016
# Last Modified:
#   Description: My Bash Profile
#===============================================================================
# Note: we use the chalk colorscheme and powerline plugin

# Path settings
PATH="/usr/bin:/bin:/usr/sbin:/sbin"
export PATH="/usr/local/bin:/usr/local/sbin:$PATH" # homebrew
export PATH="$HOME/prog-tools/arara4:$PATH" # arara
export PATH="/Library/TeX/texbin:$PATH" # basictex
export PATH="$HOME/miniconda3/bin:$PATH" # miniconda

# Symlink cask apps to Applications folder
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# Alias
alias python='python3'
# Update brew, python and tlmgr
alias uall='brew update && brew upgrade && conda update --all &&'\
'tlmgr update --all'

# Set english utf-8 locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# For powerline
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1
. $HOME/miniconda3/lib/python3.5/site-packages/powerline/bindings/bash/powerline.sh

# Set vi mode
set -o vi

# SSH and Tmux: connect to ssh and then start tmux creating a new session called
# pedrof or attaching to an existing one with that name
alias emr-tmux='ssh prd-emr-master -t tmux new -A -s pedrof'
# Presto command line
alias presto='ssh prd-emr-master -t tmux new -A -s pedrof '\
'"presto-cli\ --catalog\ hive\ --schema\ fault\ --user\ pedrof"'

# Try the following
# alias run-presto='ssh prd-emr-master -t tmux new -A -s pedrof "presto-cli\ --catalog\ hive\ --schema\ fault\ --user\ pedrof\ --execute\ \"SELECT ref_hash FROM all_events_monthly LIMIT 5;\"\ --output-format\ ALIGNED\ --file\ test.txt"'
