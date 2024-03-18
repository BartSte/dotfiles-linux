#!/usr/bin/env bash
set -euo pipefail

usage="Usage: $(basename "$0") [-h | --help] <numbers> <index>

Uses bat to display the text recieved stdin, while highlighting the line number
that corresponds to the <index>th element of <numbers>. Here, <numbers> is a
string of line numbers, separated by a whitespace, and <index> is a number.

For example: 

- stdin:
    1: This is the first line
    2: This is the second line
    3: This is the third line
    4: and so on ...
    5: and on ...

- <numbers>: 2 3 5
- <index>: 2

Now the line number 3 will be highlighted in the output using bat:

    1: This is the first line
    2: This is the second line
    --> 3: This is the third line <-- highlighted
    4: and so on ...
    5: and on ...

This script is typically used in combination with fzf's preview-window as
follows:

fzf --preview 'echo \$text | \$this_script \$numbers {n}'

where, \$text is the text to display, \$numbers is the list of line numbers,
and {n} is the index of the selected fzf entry. The assumption is that the
order of the \$numbers is the same as the order of the fzf entries.

The list of <numbers> corresponds to the following:
- We have a list of items, where each item is a fragment of text.
- For each item, i.e. the text fragment, there is a line in the text that
contains the item. 

In the example abov, the list of items could be:

    items=\"first line\nand so on ...\"
where the items are separated by a newline. 

Now the <numbers> would be: 1 4. 

The <numbers> above can, for example, be obtained by using the following
command on the text and the items:

    echo -e \$items | grep -n -F -f <(echo -e \$items) | cut -d: -f1

TODO:


stdin:
The text to display.

options:
-h --help   shows this help messages
-d --debug  prints debug information instead of executing the command

positional:
<numbers>   the list of line numbers
<index>     the index of the <numbers> to highlight"

bat_warning="
##############################################################################
Warning: bat/batcat is not installed. Using cat instead. By installing
bat/batcat, you can get syntax highlighting, automatic scrolling and the
selected option will be highlighted. To disable this warning, set the
environment variable FZF_HELP_BAT_WARNING to false.
##############################################################################
"

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help)
            echo "$usage"
            exit 0
            ;;
        -d | --debug)
            debug=true
            ;;
        *)
            if [[ -z $opts ]]; then
                opts="$1"
            elif [[ -z $index ]]; then
                index="$1"
            else
                echo "Unknown argument: $1"
                echo "$usage"
                exit 1
            fi
            ;;
        esac
        shift
    done
}

#######################################
# `opts` is a list of line_number:option pairs, separated by a new line. For
# example:
#   1:--some-option
#   2:--some-other-option
#  10:--another-option
# This function returns the line number of the option at the given index. In
# the example above, for index 0, the line number 1 is returned.
#######################################
get_line_number() {
    local opts index line_number
    opts=$1
    index=$2
    line_number=$(head -n $(($index + 1)) <<<"$opts" | tail -1 | sed "s/:.*$//g")
    [[ -z $line_number ]] && line_number=0
    echo "$line_number"
}

#######################################
# Returns the number of lines to scroll up such that the line containing the
# option at the given index is in the middle of the screen.
#######################################
get_scroll_lines() {
    local half_page line_number scroll

    line_number=$1
    half_page=$(get_half_page)

    scroll=$(($line_number - $half_page))
    scroll=$(($scroll > 0 ? $scroll : 0))
    echo $scroll
}

#######################################
# Returns half the number of lines of the terminal. If the environment variable
# FZF_PREVIEW_LINES is set, its value is returned instead.
#######################################
get_half_page() {
    local number_of_lines

    number_of_lines=${FZF_PREVIEW_LINES:-}
    [[ -z $number_of_lines ]] && number_of_lines=$(tput lines)

    echo $(($number_of_lines / 2))
}

#######################################
# Prints the bat warning message to stderr, if the environment variable
# FZF_HELP_BAT_WARNING is set to true.
#######################################
print_bat_warning() {
    if [[ $show_bat_warning == "true" ]]; then
        echo "$bat_warning" >&2
    fi
}

print_debug_info() {
    local msg
    msg+="\nopts:\n$opts\n"
    msg+="\nindex:\n$index\n"
    msg+="\nline_number:\n$line_number\n"
    msg+="\nscroll:\n$scroll\n"
    msg+="\nfzf_help_syntax:\n$fzf_help_syntax\n"
    msg+="\nshow_bat_warning:\n$show_bat_warning\n"
    msg+="\nstdout:\n$(cat -)\n"
    echo -e "$msg"
}

#######################################
# Executes the args with batcat or bat, if one of them is installed. If none of
# them is installed, cat is used instead. If the environment variable
# FZF_HELP_BAT_WARNING is set to false, the warning message is not printed
# to stderr.
#######################################
exec_bat() {
    if $debug; then
        print_debug_info
    elif which batcat &>/dev/null; then
        batcat "$@"
    elif which bat &>/dev/null; then
        bat "$@"
    else
        print_bat_warning
        cat
    fi
}

opts=""
index=""
debug=false
parse_args "$@"
fzf_help_syntax="${FZF_HELP_SYNTAX:-txt}"
show_bat_warning="${FZF_HELP_BAT_WARNING:-true}"

[[ -z $opts ]] && echo "Missing <opts>" && echo "$usage" && exit 1
[[ -z $index ]] && echo "Missing <index>" && echo "$usage" && exit 1

line_number=$(get_line_number "$opts" "$index")
scroll=$(get_scroll_lines "$line_number")

printf '\033[2J'
exec_bat -f -pp -H "$line_number" -r "$scroll": --language="$fzf_help_syntax"
