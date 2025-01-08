#!/bin/bash

function green() {
    _colour="\033[1;32m"
    echo -e "${_colour}$*\e[0m"
}

function default() {
    echo -e "\033[0m"
}

function magenta() {
    _colour="\033[1;35m"
    echo -e "${_colour}$*\e[0"
}

function yellow() {
    _colour="\033[1;33m"
    echo -e "${_colour}$*\e[0m"
}

function tick() {
    echo -e "\033[32m✔"
}

function cross() {
    echo -e "\033[31m✘"
}

function _error() {
    _colour="\033[1;31m✘"
    echo -e "${_colour} [error] $*\e[0m"
}

function _warning() {
    _colour="\033[1;33m‼"
    echo -e "${_colour} [warning] $*\e[0m"
}

function _ok() {
    _tick="\033[32m✔"
    echo -e "${_tick} [ok] $*\e[0m"
}

function _environment_setup_2_tabs {
    _green="\033[1;32m"
    _magenta="\033[1;35m"
    echo -e "${_green}$1 \t\t${_magenta}$2\e[0m"
}

function _environment_setup_3_tabs {
    _green="\033[1;32m"
    _magenta="\033[1;35m"
    echo -e "${_green}$1 \t\t\t${_magenta}$2\e[0m"
}

export -f green
export -f default
export -f magenta
export -f yellow
export -f tick
export -f cross
export -f _error
export -f _warning
export -f _ok
export -f _environment_setup_2_tabs
export -f _environment_setup_3_tabs