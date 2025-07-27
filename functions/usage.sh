#!/bin/bash

function show_usage() {

    case "$1" in

    *apply.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/apply.sh\e[0m"
        ;;
    *auth.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/auth.sh -t tenant_guid\e[0m"
        return 1
        ;;
    *init.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/init.sh\e[0m"
        ;;
    *plan.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/plan.sh\e[0m"
        ;;
    *setup.sh)
        _green="\033[1;32m"
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/setup.sh \ \n-m root_module_name \ \n-t path_to_root_modules\e[0m"
        echo -e "${_green}Example: source ./scripts/setup.sh \ \n-m landing_zone \ \n-t ./root_modules\e[0m"
        return 1
        ;;
    *show.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/show.sh\e[0m"
        ;;
    *validate.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/validate.sh\e[0m"
        ;;
    *devops_variables.sh)
        _colour="\033[1;33m‼"
        echo -e "${_colour} USAGE: source ./scripts/devops_variables.sh -g DevOpsVariableGroupName\e[0m"
        echo -e "${_colour} USAGE: source ./scripts/devops_variables.sh -g DevOpsVariableGroupName -v no_prefix\e[0m"
        echo -e "${_colour} USAGE: source ./scripts/devops_variables.sh -g DevOpsVariableGroupName -v a_prefix\e[0m"
        ;;
    *)
        echo "script file not detected"
        echo "$1"
        ;;
    esac
}

export -f show_usage