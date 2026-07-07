# Per-folder named tmux sessions.
# Source this from ~/.zshrc:  source ~/.config/tmux/session.zsh

# Derive a safe session name from the current directory basename.
# tmux forbids '.' and ':' in session names, so replace them.
_tmux_session_name() {
  basename "$PWD" | tr '.:' '__'
}

# `tmux` with no args: create the folder session the first time
# (with a preset window layout), otherwise attach/switch to it (dedupe).
# Any `tmux <args...>` call is passed straight through to real tmux.
tmux() {
  if [ "$#" -gt 0 ]; then
    command tmux "$@"
    return
  fi

  local session
  session="$(_tmux_session_name)"

  if command tmux has-session -t "=$session" 2>/dev/null; then
    # Already exists -> dedupe: attach, or switch if we're inside tmux.
    if [ -n "$TMUX" ]; then
      command tmux switch-client -t "=$session"
    else
      command tmux attach-session -t "=$session"
    fi
    return
  fi

  # First start: build the layout (windows start at 1 per base-index).
  command tmux new-session -d -s "$session" -c "$PWD" -n edit
  command tmux send-keys   -t "=$session:1" 'nvim .' C-m   # 1: nvim .
  command tmux new-window  -t "=$session:"  -c "$PWD"       # 2: empty
  command tmux new-window  -t "=$session:"  -c "$PWD"       # 3: empty
  command tmux new-window  -t "=$session:"  -c "$PWD" -n lazygit
  command tmux send-keys   -t "=$session:4" 'lazygit' C-m   # 4: lazygit
  command tmux select-window -t "=$session:1"

  if [ -n "$TMUX" ]; then
    command tmux switch-client -t "=$session"
  else
    command tmux attach-session -t "=$session"
  fi
}

# `tk`: kill the session that belongs to the current folder.
# Works from a plain shell or from inside the session (closes all windows).
tk() {
  local session
  session="$(_tmux_session_name)"
  if command tmux has-session -t "=$session" 2>/dev/null; then
    command tmux kill-session -t "=$session"
    echo "Killed tmux session: $session"
  else
    echo "No tmux session for this folder: $session"
  fi
}
