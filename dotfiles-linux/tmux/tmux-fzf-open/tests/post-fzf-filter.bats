INPUTS=(
    "\"/home/barts/code/khalorg/src/khalorg/cli.py\", line 4"
    "\"\\\\wsl.localhost\\home\\barts\\code\\khalorg\\src\\khalorg\\cli.py\", line 4"
    "/home/barts/code/khalorg/src/khalorg/khal/args.py:6:"
    "\\\\wsl.localhost\\home\\barts\\code\\khalorg\\src\\khalorg\\khal\\args.py:6:"
)

EXPECTED=(
    "/home/barts/code/khalorg/src/khalorg/cli.py:4:"
    "\\\\wsl.localhost\\home\\barts\\code\\khalorg\\src\\khalorg\\cli.py:4:"
    "/home/barts/code/khalorg/src/khalorg/khal/args.py:6:"
    "\\\\wsl.localhost\\home\\barts\\code\\khalorg\\src\\khalorg\\khal\\args.py:6:"
)

@test "valid_regexes" {
    local input expected actual
    for i in "${!INPUTS[@]}"; do
        input=${INPUTS[$i]}
        expected=${EXPECTED[$i]}
        actual=$(post-fzf-filter <<<"$input") 

        echo "Input: $input" >&3
        echo "Expected: $expected" >&3
        echo "Actual: $actual" >&3
        [ "$actual" = "$expected" ]
    done
} 
