#!/bin/bash

function check_path() {

    if [ ! -d "$1" ]; then
        return 1
    else
        return 0
    fi
}

function check_file() {

    if [ ! -f "$1" ]; then
        return 1
    else
        return 0
    fi
}

export -f check_path
export -f check_file