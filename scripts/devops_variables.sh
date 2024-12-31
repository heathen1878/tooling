#!/bin/bash

# Variables
declare OPTARG
declare OPTIND=1
declare flag=""
declare PREFIX=""
declare VARIABLE_GROUP_NAME=""
declare VARIABLES=""
declare VARIABLE_PREFIX="TF_VAR_"


# Checks
# This is required to export the environment variables to the calling shell
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage "$0"
    exit 1
fi

# Are we in a git repo?
if ! (ls .git/config > /dev/null 2>&1)
then
    _error "You're not in a git repo or do not have a .git/config I can read to determine your AzDo Project"
    return 1
fi

# check script for input parameters
script_name="$(basename "${BASH_SOURCE[0]}")"

if (( $# == 0 ))
then
    _error "No arguments defined"
    echo
    show_usage "$script_name"
    return 1
fi

while getopts "g:v:" flag
do
    case "${flag}" in
        g) 
            VARIABLE_GROUP_NAME="${OPTARG}"
            VARIABLE_GROUP_NAME="$(echo "$VARIABLE_GROUP_NAME" | awk '{print tolower($0)}')"
        ;;
        v)
            PREFIX="${OPTARG}"
            PREFIX="$(echo "$PREFIX" | awk '{print toupper($0)}')"
        ;;
        *)
            show_usage "$script_name"
        ;;
    esac
done

shift "$(( OPTIND - 1 ))"

if [ ${#PREFIX} != 0 ]
then
    if [ "${PREFIX}" == "NO_PREFIX" ]
    then
        VARIABLE_PREFIX=""
    else
        VARIABLE_PREFIX="${PREFIX}"
    fi
fi

# End of checks

# Code flow
VARIABLES=$(az pipelines variable-group list --group-name "$VARIABLE_GROUP_NAME" | jq -c '.[].variables | to_entries[]')

# replace any whitespace as this break bash
for VARIABLE in ${VARIABLES/ /}
do 
    VARIABLE_NAME=$(echo "$VARIABLE" | jq -rc '.key')
    VARIABLE_VALUE=$(echo "$VARIABLE" | jq -rc '.value.value')
       
    VARIABLE_TO_BE_EXPORTED="${VARIABLE_PREFIX}${VARIABLE_NAME}"
    declare "$VARIABLE_TO_BE_EXPORTED"="${VARIABLE_VALUE}"
    export "${VARIABLE_TO_BE_EXPORTED?}"
done