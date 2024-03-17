#!/usr/bin/env bash

# Find the `target` (which is a short string) in the `file` and return the line
# number. Next display `file` using `bat` and highlight the line number.
target=$(sed -E 's/^[ 0-9]+ //' <<< "$1")
file=/tmp/tmux-fzf-url-capture

# Find the line number of the `target` in the `file`. It does nat to be an exact
# match, but a match that contains the `target`.
line_number=$(grep -n "$target" "$file" | head -n 1 | cut -d: -f1)

# Display the `file` using `bat` and highlight the line number
echo "Line: $line_number"
bat -f -pp -H "$line_number" "$file"

# TODO: add support for scrolling, just like `fzf-help`
