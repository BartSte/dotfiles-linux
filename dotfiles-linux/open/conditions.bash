#!/usr/bin/env bash

is_url() {
    [[ $1 =~ ^[a-zA-Z]+://.* ]] || [[ $1 =~ ^www\..* ]]
}

is_html() {
    [[ $1 =~ .*\.html ]]
}

is_image() {
    [[ $1 =~ .*\.png ]] || [[ $1 =~ .*\.jpg ]] || [[ $1 =~ .*\.jpeg ]]
}

is_python() {
    [[ $1 =~ .*\.py[:]* ]]
}

is_pdf() {
    [[ $1 =~ .*\.pdf ]]
}

is_cpp() {
    [[ $1 =~ .*\.c ]] || [[ $1 =~ .*\.h ]] || [[ $1 =~ .*\.cpp ]] || [[ $1 =~ .*\.hpp ]]
}

running_tmux() {
    [[ ! -z $TMUX ]]
}
