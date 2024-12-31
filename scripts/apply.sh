#!/bin/bash

# checks
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage
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
# end checks

# variables
filePlan=$(find "$TERRAFORM_DEPLOYMENT"/*.tfplan -type f | sort -rn | head -1)

# flow
_ok "Applying latest plan: $filePlan"

if ! (terraform -chdir="$TERRAFORM_DEPLOYMENT" apply -input=false "$filePlan")
then
    return 1
fi
# end of flow