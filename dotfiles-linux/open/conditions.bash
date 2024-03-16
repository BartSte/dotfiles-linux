#!/usr/bin/env bash
set -euo pipefail

_is_python() { [[ $1 =~ .*\.py[:]* ]]; }
_is_cpp() { [[ $1 =~ .*\.(c|h|cpp|hpp) ]]; }

is_html() { [[ $1 =~ .*\.html ]]; }
is_image() { [[ $1 =~ .*\.(png|jpg|jpeg|gif|bmp|tiff|tif|svg) ]]; }
is_pdf() { [[ $1 =~ .*\.pdf ]]; }
is_text() { [[ $1 =~ .*\.(txt|md|markdown|org|rst|tex|py|c|h|cpp|hpp|lua|sh|bash|zsh|json|yaml|yml|toml|xml|cfg|conf|ini|log|js|ts|jsx|tsx|css|java)[:]* ]]; }
is_url() { [[ $1 =~ ^([a-zA-Z]+://|www\..*) ]]; }

running_tmux() { [[ ! -z $TMUX ]]; }
running_wsl() { grep -iq microsoft /proc/version; }
