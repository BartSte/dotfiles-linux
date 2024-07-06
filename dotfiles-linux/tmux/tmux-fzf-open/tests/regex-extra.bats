#!/usr/bin/env bats
# vim: ft=bash

MATCHES=(
    "File \"/home/barts/code/khalorg/src/khalorg/cli.py\", line 4, in <module>"
    "File \"\\\\wsl.localhost\\home\\barts\\code\\khalorg\\src\\khalorg\\cli.py\", line 4, in <module>"
    "/home/barts/code/khalorg/src/khalorg/khal/args.py:6: in <module>"
    "\\\\wsl.localhost\\home\\barts\\code\\khalorg\\src\\khalorg\\khal\\args.py:6: in <module>"
)

@test "valid_regexes" {
    for match in "${MATCHES[@]}"; do
        echo "Checking match: $match" >&3
        grep -oE "$(regex-extra)" <<<"$match"
    done
}
