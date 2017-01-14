# ---------------------------------------------------------
#  CUSTOM SETTINGS
# ---------------------------------------------------------

# term
export TERM=xterm-256color

# editors
export VISUAL=vim
export EDITOR=vim

# shell behavior
shopt -s nocaseglob;
shopt -s cdspell;

# aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias l='ls'
alias ll="ls -AFGhl"

alias sudo="sudo "

mkcd() { mkdir "$1"; cd "$1"; }

# locales
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# autojump
[[ -e /usr/share/autojump/autojump.sh ]] && source /usr/share/autojump/autojump.sh
export AUTOJUMP_IGNORE_CASE=1
