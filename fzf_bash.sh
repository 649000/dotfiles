# Note: this uses rust binaries: fd, bat, lsd and devicon-lookup
# It also assumes (for bindings) that bash is used in vi-mode

# Setup {{{

# Set base dir
base_pkg_dir='/usr'
if [[ "$OSTYPE" == 'darwin'* ]]; then
    if type "brew" > /dev/null 2>&1; then
        base_pkg_dir=$(brew --prefix)
    else
        base_pkg_dir='/usr/local'
    fi
fi

# Enable completion and key bindings (note: we override some of these mappings
# below)
if [[ $- == *i* ]]; then
    if [[ "$OSTYPE" == 'darwin'* ]]; then
        completion_base_dir="$base_pkg_dir/opt/fzf/shell"
    else
        completion_base_dir="$base_pkg_dir/share/fzf"
    fi
    . "$completion_base_dir/completion.bash" 2> /dev/null
fi

# }}}
# Options {{{

# Change default options and colors
export FZF_DEFAULT_OPTS='
--height 15
--inline-info
--prompt="❯ "
--bind=ctrl-space:toggle+up
--color=bg+:#282c34,bg:#24272e,fg:#abb2bf,fg+:#abb2bf,hl:#528bff,hl+:#528bff
--color=prompt:#61afef,header:#566370,info:#5c6370,pointer:#c678dd
--color=marker:#98c379,spinner:#e06c75,border:#282c34
'

# Use fd for files and dirs
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--multi
--preview 'bat --color always --style numbers --theme TwoDark --line-range :200 {2}'
--expect=tab,ctrl-t,ctrl-o,alt-c,alt-p,alt-f,ctrl-y
--header=enter=vim,\ tab=insert,\ C-t=fzf-files,\ C-o=open,\ A-c=cd-file-dir,\ A-p=parent-dirs,\ A-f=ranger,\ C-y=yank
"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
FZF_ALT_C_OPTS_BASE="
--no-multi
--expect=ctrl-o,ctrl-t,alt-c,alt-p,alt-f,ctrl-y
--header=enter=fzf-files,\ C-o=cd,\ A-c=fzf-dirs,\ A-p=parent-dirs,\ A-f=ranger,\ C-y=yank
"
export FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS_BASE\
--preview 'lsd -F --tree --depth 2 --color=always --icon=always {2} | head -200'
"
export FZF_ALT_Z_OPTS="$FZF_ALT_C_OPTS_BASE\
--no-sort
--tac
--preview 'lsd -F --tree --depth 2 --color=always --icon=always {3} | head -200'
"
# History options
export FZF_CTRL_R_OPTS="--tac --sync -n2..,.. --tiebreak=index"

# Extend list of commands with fuzzy completion (basically add our aliases)
complete -F _fzf_path_completion -o default -o bashdefault v o dog

# }}}
# Bindings {{{

# Helpers {{{

# Bind unused key, "\C-x\C-a", to enter vi-movement-mode quickly and then use
# that thereafter.
bind '"\C-x\C-a": vi-movement-mode'

bind '"\C-x\C-e": shell-expand-line'
bind '"\C-x\C-r": redraw-current-line'
bind '"\C-x^": history-expand-line'

# }}}
# File and dirs {{{

# Custom Ctrl-t mapping (also Alt-t to ignore git-ignored files)
__fzf_select_custom__() {
    local cmd dir
    cmd="$FZF_CTRL_T_COMMAND"
    if [[ "$1" == 'no-ignore' ]]; then
        cmd="$cmd --no-ignore-vcs"
    fi
    if [[ "$2" ]]; then
        cmd="$cmd . $2"  # use narrow dir
    fi
    out=$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_T_OPTS" fzf)
    key=$(head -1 <<< "$out")
    mapfile -t _files <<< "$(tail -n+2 <<< "$out")"

    if [ ${#_files[@]} -eq 1 ] && [[ -z "${_files[0]}" ]]; then
        return 1
    else
        files=();
        for f in "${_files[@]}"; do
            files+=("${f#* }")
        done
    fi

    case "$key" in
        tab)
            printf '%q ' "${files[@]}" ;;
        ctrl-t)
            __fzf_select_custom__ "no-ignore" "$(dirname "${files[0]}")" ;;
        ctrl-o)
            printf 'open %q' "${files[0]}" ;;
        alt-c)
            printf 'cd %q' "$(dirname "${files[0]}")" ;;
        alt-p)
            __fzf_cd_parent__ "$(dirname "${files[0]}")" ;;
        alt-f)
            printf 'ranger --selectfile %q' "${files[0]}" ;;
        ctrl-y)
            printf -v files_str "%s " "${files[@]}"
            printf 'echo %s | xsel --clipboard' "$files_str" ;;
        *)
            printf 'v %q' "${files[@]}" ;;
    esac
}
fzf-file-widget-custom() {
    local selected=""
    selected="$(__fzf_select_custom__ "$1" "$2")"
    READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
    READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
}
# Note this will insert output to the prompt and there is no way to choose to
# execute it instead: https://github.com/junegunn/fzf/issues/477
# shellcheck disable=SC2016
bind -x '"\C-t": "fzf-file-widget-custom"'
bind -m vi-command '"\C-t": "i\C-t"'
bind -x '"\et": "fzf-file-widget-custom no-ignore"'
bind -m vi-command '"\et": "i\et"'


# Helper that defines actions for keys in directory-like maps
__fzf_cd_action_key__() {
    out="$1"
    key=$(head -1 <<< "$out")
    dir=$(head -2 <<< "$out" | tail -1)

    if [[ -z "$dir" ]]; then
        return 1
    else
        dir="${dir#* }"
    fi

    case "$key" in
        ctrl-o)
            printf 'cd %q' "$dir" ;;
        alt-f)
            printf 'ranger %q' "$dir" ;;
        alt-c)
            __fzf_cd_custom__ "no-ignore" "$dir" ;;
        alt-p)
            __fzf_cd_parent__ "$dir" ;;
        ctrl-y)
            printf 'echo %s | xsel --clipboard' "$dir" ;;
        *)
            __fzf_select_custom__ "no-ignore" "$dir" ;;
    esac
}

# Custom Alt-c maps (also Alt-d to ignore git-ignored dirs)
__fzf_cd_custom__() {
    local cmd dir
    cmd="$FZF_ALT_C_COMMAND"
    if [[ "$1" == 'no-ignore' ]]; then
        cmd="$cmd --no-ignore-vcs"
    fi
    if [[ "$2" ]]; then
        cmd="$cmd . $2"  # use narrow dir
    fi
    out=$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf)
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ec": "\C-x\C-addi`__fzf_cd_custom__`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ec": "i\ec"'
# shellcheck disable=SC2016
bind '"\ed": "\C-x\C-addi`__fzf_cd_custom__ no-ignore`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ed": "i\ed"'

# Alt-h map to cd from home dir
# shellcheck disable=SC2016
bind '"\eh": "\C-x\C-addi`__fzf_cd_custom__ no-ignore ~`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\eh": "i\eh"'

# Alt-p mapping to cd to selected parent directory (sister to Alt-c)
__fzf_cd_parent__() {
    local dirs=()
    get_parent_dirs() {
        if [[ -d "${1}" ]]; then
            dirs+=("$1")
        else
            return
        fi
        if [[ "${1}" == '/' ]]; then
            for _dir in "${dirs[@]}"; do
                echo "$_dir"
            done
        else
            get_parent_dirs "$(dirname "$1")"
        fi
    }
    start_dir="$(dirname "$PWD")"
    cmd="get_parent_dirs $(realpath "${1:-$start_dir}")"
    out=$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" fzf)
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ep": "\C-x\C-addi`__fzf_cd_parent__`\C-x\C-e\C-x\C-r\C-m"'
bind -m vi-command '"\ep": "i\ep"'

# Z
z() {
    [ $# -gt 0 ] && _z "$*" && return
    cmd="_z -l 2>&1"
    out="$(eval "$cmd" | devicon-lookup |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_ALT_Z_OPTS" fzf |
        sed 's/^\W\s[0-9,.]* *//')"
    __fzf_cd_action_key__ "$out"
}
# shellcheck disable=SC2016
bind '"\ez": "\C-x\C-addi`z`\C-x\C-e\C-x\C-r\C-m"'
# shellcheck disable=SC2016
bind -m vi-command '"\ez": "ddi`z`\C-x\C-e\C-x\C-r\C-m"'

# }}}
# History {{{

__fzf_history__() (
    local line
    shopt -u nocaseglob nocasematch
    cmd="HISTTIMEFORMAT= history"
    line=$(eval "$cmd" |
        FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS $FZF_CTRL_R_OPTS" fzf |
        command grep '^ *[0-9]'
    )
    sed 's/^ *\([0-9]*\)\** .*/!\1/' <<< "$line"
)
# shellcheck disable=SC2016
bind '"\C-r": "\C-x\C-addi`__fzf_history__`\C-x\C-e\C-x\C-r\C-x^\C-x\C-a$a"'
bind -m vi-command '"\C-r": "i\C-r"'

# }}}
# Tmux {{{

# Tmux session switcher (`tms foo` attaches to `foo` if exists, else creates
# it)
tms() {
    [[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
    if [[ "$1" ]]; then
        if [[ "$1" == "-ask" ]]; then
            read -r -p "New tmux session name: " session_name
        else
            session_name="$1"
        fi
        tmux $change -t "$session_name" 2>/dev/null || \
            (tmux -f "$HOME/.tmux/tmux.conf" new-session -d -s "$session_name" && \
            tmux $change -t "$session_name");
        return
    fi
    session=$(tmux list-sessions -F \
        "#{session_name}" 2>/dev/null | fzf --exit-0) && \
        tmux $change -t "$session" || echo "No sessions found."
}
# Tmux session killer
tmk() {
    session=$(tmux list-sessions -F "#{session_name}" | \
        fzf --query="$1" --exit-0) &&
    tmux kill-session -t "$session"
}

# }}}
# Git {{{

# Forgit (git and fzf)
export FORGIT_NO_ALIASES="1"
alias gl=__forgit_log
alias gd=__forgit_diff
alias ga=__forgit_add
alias gcu=__forgit_restore
alias gsv=__forgit_stash_show
if [ -f "$HOME/.local/bin/forgit.plugin.sh" ]; then
    . "$HOME/.local/bin/forgit.plugin.sh"
fi

# }}}

# }}}
