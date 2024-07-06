#!/usr/bin/env bats
# vim: ft=bash

matches=(
    "File \"/home/barts/code/khalorg/src/khalorg/cli.py\", line 4, in <module>"
    "/home/barts/code/khalorg/src/khalorg/khal/args.py:6: in <module>"
)

@test "valid_regexes" {
    for match in "${matches[@]}"; do
        echo "$match" | grep -oE "$(regex-extra)"
    done
}
