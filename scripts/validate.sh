#!/bin/bash

# checks
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage "$0"
    exit 1
fi

if ! check_for_terraform_executable
then
    return 1
fi

# Check whether the TERRAFORM_DEPLOYMENT environment variable exists
if ! check_parameter "$TERRAFORM_DEPLOYMENT" "\$TERRAFORM_DEPLOYMENT"
then
    return 1
fi
# end checks

# flow
if [ -n "$TF_BUILD" ]
then
    echo "Validating $TERRAFORM_DEPLOYMENT"
    terraform -chdir="$TERRAFORM_DEPLOYMENT" validate -no-color
else
    _ok "Validating $TERRAFORM_DEPLOYMENT"
    terraform -chdir="$TERRAFORM_DEPLOYMENT" validate
fi