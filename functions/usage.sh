#!/bin/bash

function show_usage() {

    case "$1" in

    *apply.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./helper_scripts/apply.sh\e[0m"
        ;;
    *auth.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./helper_scripts/auth.sh -t tenant_guid\e[0m"
        return 1
        ;;
    *init.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./helper_scripts/init.sh\e[0m"
        ;;
    *plan.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./helper_scripts/plan.sh\e[0m"
        ;;
    *setup.sh)
        _green="\033[1;32m"
        _colour="\033[1;33m‼"
        echo -e "${_green}[] denotes optional argument\e[0m"
        echo -e "${_colour} USAGE: source ./helper_scripts/setup.sh \ \n-s storage_account_name \ \n-k key_vault_name \ \n-r resource_group_name \ \n-e [dev] \ \n-l uksouth \ \n-p [plg] \ \n-m env-config\e[0m"
        echo -e "${_green}Example: source ./helper_scripts/setup.sh \ \n-s my_storage_account \ \n-k my_key_vault \ \n-r my_resource_group \ \n-e dev \ \n-l uksouth \ \n-p plg \ \n-m env-config\e[0m"
        return 1
        ;;
    *show.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./helper_scripts/show.sh\e[0m"
        ;;
    *devops_variables.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./helper_scripts/devops_variables.sh -g DevOpsVariableGroupName\e[0m"
        echo -e "${_colour} USAGE: source ./helper_scripts/devops_variables.sh -g DevOpsVariableGroupName -v no_prefix\e[0m"
        echo -e "${_colour} USAGE: source ./helper_scripts/devops_variables.sh -g DevOpsVariableGroupName -v a_prefix\e[0m"
        ;;
    *)
        echo "script file not detected"
        echo "$1"
        ;;
    esac
}

export -f show_usage