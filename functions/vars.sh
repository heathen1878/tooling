#!/bin/bash

function check_namespace_environment_parameter() {
    
    if [[ $1 != *'-'* ]]; then
        _error "Namespace-environment parameter is not in the correct format"
        return 1
    fi

}

function check_deployment_parameter() {

    if [[ ! -d $PWD/root_modules/$DEPLOYMENT_NAME ]]; then
        _error "Cannot find deployment directory"
        return 1
    fi

}

function check_parameter() {

    if [ -z "$1" ]; then
        _error "$2 is empty, please ensure ./scripts/setup.sh has been run"
        return 1
    fi
}

export -f check_namespace_environment_parameter
export -f check_deployment_parameter
export -f check_parameter