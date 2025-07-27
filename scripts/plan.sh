#!/bin/bash 

# variables
planName="$(date +%Y-%m-%d_%H-%M-%S).tfplan"

# checks
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage "$0"
    exit 1
fi

# Check whether the TERRAFORM_ENV environment variable exists
if ! check_parameter "$TERRAFORM_ENV" "\$TERRAFORM_ENV"
then
    return 1
fi

# Check whether the TERRAFORM_DEPLOYMENT environment variable exists
if ! check_parameter "$TERRAFORM_DEPLOYMENT" "\$TERRAFORM_DEPLOYMENT"
then
    return 1
fi
# end of checks

if [ -n "$TF_BUILD" ]
then
    # automation mode
    if check_file "$TERRAFORM_ENV"/env.tfvars
    then
        terraform -chdir="$TERRAFORM_DEPLOYMENT" plan -var-file="$TERRAFORM_ENV"/env.tfvars -out="$TERRAFORM_DEPLOYMENT/$planName" -detailed-exitcode -no-color
    else
        terraform -chdir="$TERRAFORM_DEPLOYMENT" plan -out="$TERRAFORM_DEPLOYMENT/$planName" -detailed-exitcode -no-color
    fi
else
    if check_file "$TERRAFORM_ENV"/env.tfvars
    then
        terraform -chdir="$TERRAFORM_DEPLOYMENT" plan -var-file="$TERRAFORM_ENV"/env.tfvars -out="$TERRAFORM_DEPLOYMENT/$planName" -detailed-exitcode
    else
        terraform -chdir="$TERRAFORM_DEPLOYMENT" plan -out="$TERRAFORM_DEPLOYMENT/$planName" -detailed-exitcode
    fi
fi
EXITCODE=$?

case $EXITCODE in
    0)
        return 0
    ;;
    1)
        echo "Error planning"
        return 1
    ;;
    2)
        return 0
    ;;
esac