# Activate virtualenv if .venv exists
source .venv/bin/activate 2>/dev/null || true

dir="$HOME/dotfiles-linux/aider/prompts"
export AIDER_READ="[$dir/code/personal/python/conventions.md]"
