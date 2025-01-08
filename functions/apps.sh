#!/bin/bash

function output_configuration_name() {

    if command -v figlet > /dev/null 2>&1; then

        figlet -t "$1"-"$2"
        echo
        if  [ -n "$3" ]; then
            figlet -t "Environment:  $3"
        fi
        echo
        if [ -n "$4" ]; then
            figlet -t "Module:  $4"
        fi
    else
        echo "$1"-"$2"
    fi

}

function check_for_terraform_executable() {

    if ! command -v terraform > /dev/null 2>&1; then
        _error "Please install Terraform"
        return 1
    fi
}

function az_logout() {

    echo -e "$(yellow)Logging out az cli$(default)"
    az logout
    sleep 5
}

export -f output_configuration_name
export -f check_for_terraform_executable
export -f az_logout