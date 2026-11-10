#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
subject="$repo_root/bin/open"
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
fake_bin="$test_directory/bin"
fixtures="$test_directory/files"
mkdir -p "$fake_bin" "$fixtures"
export OPEN_TEST_CALLS="$test_directory/calls"
export OPEN_TEST_REAL_FILE
OPEN_TEST_REAL_FILE=$(command -v file)
mkdir -p "$OPEN_TEST_CALLS"
unset OPEN_LOG_FILE OPEN_LOG_LEVEL LINBROWSER WSLBROWSER TMUX TMUX_PANE WSL_DISTRO_NAME WSL_INTEROP
export OPEN_TEST_LINUX_PATH="$fixtures/source.txt"
export OPEN_TEST_WINDOWS_PATH='C:/Users/Bart/source.txt'

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    cat "$test_directory/stderr" >&2
    exit 1
}

cat > "$fake_bin/stub" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
name=${0##*/}
printf '%s\0' "$@" >> "$OPEN_TEST_CALLS/$name"
case $name in
    grep)
        # Make WSL detection independent of the host running the tests.
        [[ ${*: -1} != /proc/version ]] || exit 1
        exec /usr/bin/grep "$@"
        ;;
    file)
        if [[ -n ${OPEN_TEST_MIME:-} ]]; then
            printf '%s\n' "$OPEN_TEST_MIME"
        else
            exec "$OPEN_TEST_REAL_FILE" "$@"
        fi
        ;;
    wslpath)
        [[ ${OPEN_TEST_CONVERSION_FAIL:-0} != 1 ]] || exit 9
        if [[ $1 == -ua ]]; then
            printf '%s\n' "$OPEN_TEST_LINUX_PATH"
        else
            printf '%s\n' "$OPEN_TEST_WINDOWS_PATH"
        fi
        ;;
    tmux)
        [[ ${OPEN_TEST_TMUX_FAIL:-0} != 1 ]] || exit 9
        case $1 in
            display-message)
                if [[ ${*: -1} == '#S:#I:#P' ]]; then
                    printf 'open-test:1:0\n'
                elif [[ ${*: -1} == '#{session_id}' ]]; then
                    printf '$0\n'
                else
                    printf '%%2\n'
                fi
                ;;
            list-panes)
                if [[ $* == *'#{window_id}'* ]]; then
                    case ${OPEN_TEST_EDITOR:-other} in
                        none) printf '%%2 @1 1 0 zsh\n%%3 @0 0 0 codex\n' ;;
                        current) printf '%%1 @0 0 0 nvim\n%%2 @1 1 0 nvim\n' ;;
                        *) printf '%%2 @1 1 0 zsh\n%%9 @4 4 2 nvim\n' ;;
                    esac
                else
                    printf '0:%s\n' "${OPEN_TEST_COMMAND:-nvim}"
                fi
                ;;
            select-window | select-pane | split-window) ;;
            *) exit 99 ;;
        esac
        ;;
    nvim | key2pane | browser | imv | zathura | sc-im)
        printf 'program stdout\n'
        printf 'program stderr\n' >&2
        exit "${OPEN_TEST_STATUS:-0}"
        ;;
    *) exit 99 ;;
esac
STUB
chmod +x "$fake_bin/stub"
for program in grep file wslpath tmux nvim key2pane browser imv zathura sc-im; do
    ln -s stub "$fake_bin/$program"
done
export PATH="$fake_bin:$PATH"
printf 'A text document.\nSecond line.\n' > "$fixtures/source.txt"
printf '{"key": "value"}\n' > "$fixtures/document.json"
: > "$fixtures/empty.txt"
ln -s source.txt "$fixtures/link.txt"
printf '\0\1\2\3' > "$fixtures/binary"
printf 'A text document.\n' > "$fixtures/report:2026"
printf 'A text document.\n' > "$fixtures/-dash.txt"

run() {
    local expected=$1 status=0
    shift
    rm -f "$OPEN_TEST_CALLS/"*
    "$subject" "$@" > "$test_directory/stdout" 2> "$test_directory/stderr" || status=$?
    [[ $status == "$expected" ]] || fail "Expected status $expected, got $status for: $*"
}

assert_args() {
    local program=$1
    shift
    printf '%s\0' "$@" > "$test_directory/expected"
    cmp -s "$test_directory/expected" "$OPEN_TEST_CALLS/$program" || fail "Wrong $program arguments"
}

assert_text() {
    assert_args nvim -c 'call cursor(1, 1)' -- "$1"
}

run 0 --help
[[ ! -e $OPEN_TEST_CALLS/nvim ]] || fail 'Help opened an editor'
for args in --invalid --log --linpath; do
    if [[ $args == --linpath ]]; then
        run 1 --linpath --winpath "$fixtures/source.txt"
    else
        run 1 "$args" </dev/null
    fi
done
run 1 --log --quiet "$fixtures/source.txt"
run 1 '' </dev/null
run 1 </dev/null
run 1 "$fixtures/source.txt" "$fixtures/document.json"
run 1 "$fixtures/missing"
run 1 "$fixtures"
run 1 "$fixtures/binary"
[[ $(< "$test_directory/stderr") != *'numeric argument required'* ]] || fail 'Invalid exit argument'
run 1 "$fixtures/source.txt:0"
run 1 "$fixtures/source.txt:2:0"
run 1 "$fixtures/source.txt:2:let g:injected=1"

for name in source.txt document.json empty.txt link.txt report:2026; do
    run 0 "$fixtures/$name"
    assert_text "$fixtures/$name"
    assert_args file --mime-type -Lb -- "$fixtures/$name"
done
run 0 "$fixtures/source.txt:002:0003"
assert_args nvim -c 'call cursor(2, 3)' -- "$fixtures/source.txt"
run 0 "$fixtures/source.txt:2:"
assert_args nvim -c 'call cursor(2, 1)' -- "$fixtures/source.txt"
run 0 --linpath "$fixtures/source.txt"
[[ ! -e $OPEN_TEST_CALLS/wslpath ]] || fail 'Linux path converted outside WSL'
run 0 "$fixtures/source.txt" <<< "$fixtures/missing"
assert_text "$fixtures/source.txt"
run 0 <<< "$fixtures/document.json"
assert_text "$fixtures/document.json"
(
    cd "$fixtures"
    run 0 -- -dash.txt
    assert_text "$fixtures/-dash.txt"
)

tricky_name="$fixtures/space ' \" \\ | let g:injected=1 | %"$'\n\r\t\e'".txt"
printf 'A text document.\n' > "$tricky_name"
run 0 "$tricky_name:2:3"
assert_args nvim -c 'call cursor(2, 3)' -- "$tricky_name"

export LINBROWSER="$fake_bin/browser"
for url in 'https://example.invalid/a?q=1&b=2' 'www.example.invalid' 'mailto:bart@example.invalid'; do
    run 0 "$url"
    assert_args browser "$url"
    [[ ! -e $OPEN_TEST_CALLS/file ]] || fail 'URL passed to file detection'
done
export WSLBROWSER="$fake_bin/missing-browser"
run 0 https://example.invalid
assert_args browser https://example.invalid
export WSL_DISTRO_NAME=Test
run 1 https://example.invalid
unset WSLBROWSER
export OPEN_TEST_STATUS=42
run 42 https://example.invalid
run 42 "$fixtures/source.txt"
unset OPEN_TEST_STATUS
unset LINBROWSER
run 1 https://example.invalid
[[ $(< "$test_directory/stderr") == *'No browser configured'* ]] || fail 'Missing browser diagnostic'

export WSLBROWSER="$fake_bin/browser"
for windows_input in 'C:\Users\Bart\source.txt:2:3' '"C:\Users\Bart\source.txt":2:3' '"C:\Users\Bart\source.txt:2:3"' '\\server\share\source.txt:2:3'; do
    run 0 --linpath "$windows_input"
    assert_args nvim -c 'call cursor(2, 3)' -- "$fixtures/source.txt"
done
assert_args wslpath -ua //server/share/source.txt
run 0 --linpath "$fixtures/source.txt"
[[ ! -e $OPEN_TEST_CALLS/wslpath ]] || fail 'Already Linux path converted'
(
    cd "$fixtures"
    printf 'A text document.\n' > '"quoted.txt"'
    run 0 '"quoted.txt"'
    assert_text "$fixtures/\"quoted.txt\""
)
quoted_name="$fixtures/inside\"quote.txt"
printf 'A text document.\n' > "$quoted_name"
run 0 --linpath "$quoted_name"
assert_text "$quoted_name"
export OPEN_TEST_CONVERSION_FAIL=1
run 1 --linpath 'C:\Users\Bart\source.txt'
[[ ! -e $OPEN_TEST_CALLS/nvim ]] || fail 'Failed conversion opened an editor'
unset OPEN_TEST_CONVERSION_FAIL
run 0 --winpath "$fixtures/source.txt"
assert_text "$fixtures/source.txt"
[[ ! -e $OPEN_TEST_CALLS/wslpath ]] || fail 'Text sent to Linux editor as a Windows path'

export OPEN_TEST_MIME=text/html
run 0 "$fixtures/source.txt"
assert_args browser "$OPEN_TEST_WINDOWS_PATH"
assert_args wslpath -ma "$fixtures/source.txt"
unset WSLBROWSER
export LINBROWSER="$fake_bin/browser"
run 0 "$fixtures/source.txt"
assert_args browser "$fixtures/source.txt"
run 0 --winpath "$fixtures/source.txt"
assert_args browser "$OPEN_TEST_WINDOWS_PATH"
export OPEN_TEST_CONVERSION_FAIL=1
run 1 --winpath "$fixtures/source.txt"
[[ ! -e $OPEN_TEST_CALLS/browser ]] || fail 'Failed conversion opened a browser'
unset OPEN_TEST_CONVERSION_FAIL
unset WSL_DISTRO_NAME
run 0 "$fixtures/source.txt"
assert_args browser "$fixtures/source.txt"

for mime in image/png application/pdf application/x-sc; do
    export OPEN_TEST_MIME=$mime
    run 0 "$fixtures/source.txt"
    case $mime in
        image/png) assert_args imv "$fixtures/source.txt" ;;
        application/pdf) assert_args zathura "$fixtures/source.txt" ;;
        application/x-sc) assert_args sc-im "$fixtures/source.txt" ;;
    esac
    export OPEN_TEST_STATUS=17
    run 17 "$fixtures/source.txt"
    unset OPEN_TEST_STATUS
    run 0 --quiet "$fixtures/source.txt"
    [[ ! -s $test_directory/stdout && ! -s $test_directory/stderr ]] || fail 'Quiet viewer printed output'
done
for mime in application/ld+json application/xml application/atom+xml application/javascript application/yaml application/toml; do
    export OPEN_TEST_MIME=$mime
    run 0 "$fixtures/source.txt"
    assert_text "$fixtures/source.txt"
done
unset OPEN_TEST_MIME

run 0 --quiet "$fixtures/source.txt"
[[ ! -s $test_directory/stdout && ! -s $test_directory/stderr ]] || fail 'Quiet editor printed output'
run 1 --quiet "$fixtures/missing"
[[ ! -s $test_directory/stdout && ! -s $test_directory/stderr ]] || fail 'Quiet error printed output'
run 0 --verbose "$fixtures/source.txt"
[[ $(< "$test_directory/stderr") == *'File:'* ]] || fail 'Verbose messages missing'
logfile="$test_directory/log directory/open.log"
run 0 --log "$logfile" "$fixtures/source.txt"
[[ $(< "$logfile") == *'File:'* ]] || fail 'Log messages missing'
printf 'previous invocation\n' >> "$logfile"
run 0 --quiet --log "$logfile" "$fixtures/source.txt"
[[ ! -s $test_directory/stdout && ! -s $test_directory/stderr ]] || fail 'Quiet logging printed output'
[[ $(< "$logfile") == *'previous invocation'* ]] || fail 'Log truncated'
run 1 --quiet --log "$fixtures/source.txt/open.log" "$fixtures/source.txt"
[[ ! -s $test_directory/stdout && ! -s $test_directory/stderr ]] || fail 'Quiet log error printed output'
run 1 --log "$test_directory/not-created/open.log" --invalid
[[ $(< "$test_directory/stderr") == *'Unknown option'* ]] || fail 'Log option masked argument error'

export TMUX=mock
export TMUX_PANE=%2
export OPEN_TEST_TMUX_FAIL=1
run 1 "$fixtures/source.txt"
[[ ! -e $OPEN_TEST_CALLS/nvim && ! -e $OPEN_TEST_CALLS/key2pane ]] || fail 'tmux failure opened an editor'
unset OPEN_TEST_TMUX_FAIL
run 0 "$tricky_name:2:3"
mapfile -d '' -t pane_args < "$OPEN_TEST_CALLS/key2pane"
[[ ${pane_args[9]} == "$tricky_name" && ${pane_args[10]} == 2 && ${pane_args[11]} == 3 ]] || fail 'tmux lost raw path or position'
# The session ID is the literal tmux identifier $0.
# shellcheck disable=SC2016
[[ ${pane_args[3]} == '$0' && ${pane_args[5]} == 4 && ${pane_args[7]} == 2 ]] || fail 'Wrong Neovim pane target'
[[ ! -e $OPEN_TEST_CALLS/nvim ]] || fail 'Existing editor was ignored'
# Exercise the exact shell and Vim templates with real interpreters below.
export OPEN_TEST_SHELL_PATH="${pane_args[12]}"
export OPEN_TEST_VIM_PATH="${pane_args[13]}"
export OPEN_TEST_EDITOR=current
run 0 "$fixtures/source.txt"
mapfile -d '' -t pane_args < "$OPEN_TEST_CALLS/key2pane"
[[ ${pane_args[5]} == 1 && ${pane_args[7]} == 0 ]] || fail 'Current editor did not take precedence'
export OPEN_TEST_EDITOR=none
run 0 "$fixtures/source.txt:2:3"
[[ ! -e $OPEN_TEST_CALLS/key2pane && ! -e $OPEN_TEST_CALLS/nvim ]] || fail 'Fallback reused a non-editor pane'
[[ $(tr '\0' '\n' < "$OPEN_TEST_CALLS/tmux") == *'split-window'* ]] || fail 'Fallback did not create an editor pane'
[[ $(tr '\0' '\n' < "$OPEN_TEST_CALLS/tmux") == *'call cursor(2, 3)'* ]] || fail 'Fallback lost the cursor position'
export OPEN_TEST_MIME=image/png
run 0 "$fixtures/source.txt"
assert_args imv "$fixtures/source.txt"
[[ ! -e $OPEN_TEST_CALLS/tmux ]] || fail 'Image opened in a tmux editor'
unset OPEN_TEST_MIME TMUX TMUX_PANE OPEN_TEST_EDITOR

# Format the repository's actual key2pane actions without sending tmux keys.
real_key2pane=$(PATH=${PATH#*:} command -v key2pane || true)
shell_command="nvim -c 'call cursor(2, 3)' -- $OPEN_TEST_SHELL_PATH"
vim_command=":execute 'edit ' . fnameescape($OPEN_TEST_VIM_PATH) | call cursor(2, 3)"
if [[ -n $real_key2pane ]]; then
    for target_command in bash zsh nvim codex; do
        export OPEN_TEST_COMMAND=$target_command
        formatted=$("$real_key2pane" --config "$repo_root/key2pane/config.json" \
            --logfile "$test_directory/key2pane.log" --dry-run -w 0 -i 0 -- \
            "$tricky_name" 2 3 "$OPEN_TEST_SHELL_PATH" "$OPEN_TEST_VIM_PATH" 2> "$test_directory/stderr")
        case $target_command in
            bash | zsh) [[ $formatted == "$shell_command Enter" ]] || fail 'Wrong key2pane shell template' ;;
            nvim) [[ $formatted == "Escape $vim_command Enter" ]] || fail 'Wrong key2pane Vim template' ;;
            codex) [[ $formatted == "$tricky_name" ]] || fail 'Codex did not receive literal filename' ;;
        esac
    done
    unset OPEN_TEST_COMMAND
else
    printf 'SKIP: key2pane template checks (key2pane unavailable)\n'
fi

# Bash and Zsh must interpret the escaped shell filename as one argument.
for interpreter in bash zsh; do
    command -v "$interpreter" >/dev/null || continue
    rm -f "$OPEN_TEST_CALLS/nvim"
    "$interpreter" -c "$shell_command" >/dev/null 2>&1
    assert_args nvim -c 'call cursor(2, 3)' -- "$tricky_name"
done

# Real headless Neovim checks argument safety, filename identity, and position.
real_nvim=$(PATH=${PATH#*:} command -v nvim || true)
if [[ -n $real_nvim ]]; then
    export OPEN_TEST_RESULT="$test_directory/nvim-result"
    export OPEN_TEST_EXPECTED_PATH="$tricky_name"
    check_command='lua assert(vim.fn.expand("%:p") == vim.env.OPEN_TEST_EXPECTED_PATH); assert(vim.g.injected == nil); assert(vim.fn.line(".") == 2); assert(vim.fn.col(".") == 3); vim.fn.writefile({"ok"}, vim.env.OPEN_TEST_RESULT)'
    printf 'First line.\nSecond line.\n' > "$tricky_name"
    timeout 10 "$real_nvim" --headless -u NONE -i NONE -n -c 'call cursor(2, 3)' \
        -c "$check_command" -c 'qa!' -- "$tricky_name" > "$test_directory/stdout" 2> "$test_directory/stderr"
    [[ -f $OPEN_TEST_RESULT ]] || fail 'Direct Neovim arguments failed'
    rm "$OPEN_TEST_RESULT"
    timeout 10 "$real_nvim" --headless -u NONE -i NONE -n \
        -c "$vim_command" \
        -c "$check_command" -c 'qa!' > "$test_directory/stdout" 2> "$test_directory/stderr"
    [[ -f $OPEN_TEST_RESULT ]] || fail 'tmux Vim command failed'
else
    printf 'SKIP: headless Neovim checks (nvim unavailable)\n'
fi
printf 'PASS: open regression tests\n'
