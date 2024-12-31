#!/bin/bash

# variables
declare OPTARG=""
declare OPTIND=1
declare flag=""
declare TENANT=""

# Checks
# This is required to export the environment variables to the calling shell
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage
    exit 1
fi
# end checks

# Microsoft have introduced a change that breaks this script, so i've set this configuration for now as a workaround
core_login_experience_v2=$(az config get core.login_experience_v2 --only-show-errors | jq -rc .value)
az config set core.login_experience_v2=off

while getopts ":t:" flag
do
    case "$flag" in
    t)
        TENANT=$OPTARG
        ;;
    ?)
        TENANT=""
        ;;
    esac
done

if [ "$TENANT" ]
then
    echo -e "\033[32mAuthenticating against tenant: $TENANT \033[0m"
    if az login --tenant "$TENANT" --query "sort_by([].{Name:name, Subscription:id, Tenant:tenantId},&Name)" --output table --only-show-errors --use-device-code
    then
        tick
    else
        cross
    fi

else
    echo -e "\033[32mAuthenticating Az Cli\033[0m"
    if az login --query "sort_by([].{Name:name, Subscription:id, Tenant:tenantId},&Name)" --output table --only-show-errors --use-device-code
    then
        tick
    else
        cross
    fi
fi

ARM_TENANT_ID=$(az account show | jq -rc '.tenantId')
TF_VAR_tenant_id="$ARM_TENANT_ID"
export TF_VAR_tenant_id
export ARM_TENANT_ID

# Reverting the core login experience
az config set core.login_experience_v2="$core_login_experience_v2"