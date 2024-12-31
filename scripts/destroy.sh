#!/bin/bash

if [ -z "$TERRAFORM_ENV" ] || [ -z "$TERRAFORM_DEPLOYMENT" ]
then
    echo "\$TERRAFORM_ENV or \$TERRAFORM_DEPLOYMENT is empty, please run setup.sh first."
else
    planName="$(date +%Y-%m-%d_%H-%M-%S).plan"
   
    #CODE_VERSION=$( git branch | grep '*' | sed 's/\* //' )-$( git rev-parse --short HEAD )

    if [ -z "$TERRAFORM_NAMING_NS" ] || [ -z "$TERRAFORM_NAMING_ENV" ]; then
        terraform -chdir="$TERRAFORM_DEPLOYMENT" plan -destroy \
        -var-file="$TERRAFORM_ENV/env.tfvars" \
        -out="$TERRAFORM_ENV/plans/$planName"
    else
        terraform -chdir="$TERRAFORM_DEPLOYMENT" plan -destroy \
        -var-file="$TERRAFORM_ENV/env.tfvars" \
        -out="$TERRAFORM_ENV/plans/$planName"
    fi

    echo "WARNING: If you run apply.sh now, this plan will be applied automatically - you've been warned!"
fi