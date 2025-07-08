#!/bin/bash

set -e

SESSION_NAME="btc_wallet_session"

# Check if tmux installed
if ! command -v tmux &> /dev/null; then
  echo "[INFO] tmux not found. Installing..."

  if [ "$(uname)" == "Darwin" ]; then
    if ! command -v brew &> /dev/null; then
      echo "[ERROR] Homebrew not found. Please install Homebrew first: https://brew.sh/"
      exit 1
    fi
    brew install tmux
  elif [ -x "$(command -v apt-get)" ]; then
    sudo apt-get update
    sudo apt-get install -y tmux
  elif [ -x "$(command -v yum)" ]; then
    sudo yum install -y tmux
  elif [ -x "$(command -v dnf)" ]; then
    sudo dnf install -y tmux
  elif [ -x "$(command -v pacman)" ]; then
    sudo pacman -Sy --noconfirm tmux
  else
    echo "[ERROR] Package manager not supported. Please install tmux manually."
    exit 1
  fi
fi

# Up cron container in the background
docker compose up -d cron

# Delete previous session if exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Create new session
tmux new-session -d -s "$SESSION_NAME"

# Top panel: client
tmux send-keys -t "$SESSION_NAME":0.0 "docker compose run --rm client" C-m

# Bottom panel: cron logs
tmux split-window -v -t "$SESSION_NAME"
tmux send-keys -t "$SESSION_NAME":0.1 "docker compose logs -f cron" C-m

# Connect to the top panel
tmux select-pane -t "$SESSION_NAME":0.0

# Launch tmux interface
tmux attach -t "$SESSION_NAME"
