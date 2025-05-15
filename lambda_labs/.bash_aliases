alias tmxa="tmux attach -t"
alias tmxl="tmux list-sessions"
alias tmxn="tmux new-session -d -s"
alias tmxs="tmux send-keys -t"

alias gs="git status"
alias gf="git fetch"
alias gp="git pull"

serve_background_vllm() {
    SESSION_NAME=$1

    cd ~/kindo-evals

    tmux new-session -d -s $SESSION_NAME ; tmux send-keys -t $SESSION_NAME "./scripts/start_vllm_server.sh $2 $3 $4 $5" C-m

    echo "Started vllm server in tmux session '$SESSION_NAME'. Attach to session with 'tmux attach -t $SESSION_NAME'"
}