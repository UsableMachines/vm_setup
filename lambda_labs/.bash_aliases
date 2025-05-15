alias tmxa="tmux attach -t"
alias tmxl="tmux list-sessions"
alias tmxn="tmux new-session -d -s"
alias tmxs="tmux send-keys -t"

alias gs="git status"
alias gf="git fetch"
alias gp="git pull"

if [ -f ~/.env ]; then
    . ~/.env
fi