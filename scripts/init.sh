#!/bin/bash

# Checks
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage "$0"
    exit 1
fi

if ! check_for_terraform_executable
then
    return 1
fi

# check whether the TERRAFORM_ENV environment variable exists
if ! check_parameter "$TERRAFORM_ENV" "\$TERRAFORM_ENV"
then
    return 1
fi

# Check whether the TERRAFORM_DEPLOYMENT environment variable exists
if ! check_parameter "$TERRAFORM_DEPLOYMENT" "\$TERRAFORM_DEPLOYMENT"
then
    return 1
fi

# Check whether the terraform-cache exists or not
if [ ! -d "$HOME/.terraform-cache" ]
then 
    mkdir "$HOME/.terraform-cache";
fi

# cache terraform plugins so they're not repeatedly downloaded
TF_PLUGIN_CACHE_DIR="$HOME/.terraform-cache"
export TF_PLUGIN_CACHE_DIR

_ok "Plugin cache set to : $TF_PLUGIN_CACHE_DIR"
# end of checks

terraform -chdir="$TERRAFORM_DEPLOYMENT" init -input=false -backend-config="$TERRAFORM_ENV"/backend.tfvars
