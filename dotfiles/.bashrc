# ---------------------------------------------------------
#  CUSTOM SETTINGS
# ---------------------------------------------------------

# color prompt
export PS1="\[\e[1;37m\][\u@\h \W]\$ \[\e[m\]"

# editors
export VISUAL=vim
export EDITOR=vim

# case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;
# autocorrect typos in path names when using `cd`
shopt -s cdspell;
# allow aliases with sudo
alias sudo="sudo "

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias prev="cd -"
alias l='ls'
alias ll="ls -AFGhl"
mkcd () { mkdir "$@"; cd "$@"; }
up() { cd $(eval printf '../'%.0s {1..$1}) && pwd; }
alias e="vim"

# autojump
[[ -e /usr/share/autojump/autojump.sh ]] && source /usr/share/autojump/autojump.sh
export AUTOJUMP_IGNORE_CASE=1
