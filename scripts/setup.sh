#!/bin/bash 

# variables
declare OPTARG=""
declare OPTIND=1
declare flag=""
declare STORAGE_ACCOUNT=""
declare KEY_VAULT=""
declare KEY_VAULT_RG=""
declare ENVIRONMENT=""
declare LOCATION=""
declare MODULE=""
declare PLATFORM=""
declare SUPPORTED_PLATFORMS=("gbl" "rgl" "plg")
declare SUPPORTED_ENVIRONMENTS=("dev" "tst" "prd" "sbx")
declare TF_CODE="../framework/terraform"
declare ASSOCIATION=""
declare ARM_SUBSCRIPTION_ID=""
declare ARM_TENANT_ID=""
declare PUBLISHED_IP_RANGES="/tools/published_ip_ranges.txt"

# Checks
# This is required to export the environment variables to the calling shell
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage "$0"
    exit 1
fi

# Grab the script execution path to determine where the tooling directory is
# This is used to grab the list of published addresses from Microsoft
MY_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
MY_PATH="$(cd -- "$MY_PATH" && pwd)"
MY_PATH="${MY_PATH%/*}"
MY_PUBLISHED_IP_RANGES=$MY_PATH$PUBLISHED_IP_RANGES

script_name="$(basename "${BASH_SOURCE[0]}")"

# check script for input parameters
if (( $# == 0 ))
then
    _error "No arguments defined"
    echo
    show_usage "$script_name"
    return 1
fi

while getopts "s:k:r:l:e:p:m:t:" flag
do
    case "${flag}" in
        s) # process storage account
            STORAGE_ACCOUNT="${OPTARG}"
            STORAGE_ACCOUNT="$(echo "$STORAGE_ACCOUNT" | awk '{print tolower($0)}')"
        ;;
        k) # process key vault
            KEY_VAULT="${OPTARG}"
            KEY_VAULT="$(echo "$KEY_VAULT" | awk '{print tolower($0)}')"
        ;;
        r) # process resource group
            KEY_VAULT_RG="${OPTARG}"
            KEY_VAULT_RG="$(echo "$KEY_VAULT_RG" | awk '{print tolower($0)}')"
        ;;
        l) # process location
            LOCATION="${OPTARG}"
            LOCATION="$(echo "$LOCATION" | awk '{print tolower($0)}')"
        ;;
        e) # process environment
            ENVIRONMENT="${OPTARG}"
            ENVIRONMENT="$(echo "$ENVIRONMENT" | awk '{print tolower($0)}')"
        ;;
        p) # process platform
            PLATFORM="${OPTARG}"
            PLATFORM="$(echo "$PLATFORM" | awk '{print tolower($0)}')"
        ;;
        m) # process module
            MODULE="${OPTARG}"
            MODULE="$(echo "$MODULE" | awk '{print tolower($0)}')"
        ;;
        t) # process tf code repo
            TF_CODE="${OPTARG}"
        ;;
        ?)
            show_usage
        ;;
    esac
done

shift "$(( OPTIND - 1 ))"

if [ ${#STORAGE_ACCOUNT} == 0 ]
then
    _error "Missing a storage account"
    echo
    show_usage "$script_name"
    return 1
fi

if [ ${#KEY_VAULT} == 0 ]
then
    _error "Missing key vault"
    echo
    show_usage "$script_name"
    return 1
fi

if [ ${#KEY_VAULT_RG} == 0 ]
then
    _error "Missing key vault resource group"
    echo
    show_usage "$script_name"
    return 1
fi

if [ ${#ENVIRONMENT} == 0 ]
then
    _warning "Missing environment - valid for global deployments"
else
    MATCHED=false
    for SUPPORTED_ENVIRONMENTS in "${SUPPORTED_ENVIRONMENTS[@]}"
    do
        if [ "$SUPPORTED_ENVIRONMENTS" == "$ENVIRONMENT" ]
        then
            MATCHED=true
        fi
    done

    if ! $MATCHED
    then 
        echo
        #TODO: Loop through the array of supported environments rather than explicitly list them
        _error "-e must be one of: "
        _error "dev"
        _error "test"
        _error "prd"
        _error "sbx" 
        return 1
    fi
fi

if [ ${#LOCATION} == 0 ]
then
    _error "Missing location"
    show_usage "$script_name"
    return 1
fi

if [ ${#PLATFORM} == 0 ]
then
    _error "Missing platform"
    echo
    show_usage "$script_name"
    return 1
else
    MATCHED=false
    for SUPPORTED_PLATFORMS in "${SUPPORTED_PLATFORMS[@]}"
    do
        if [ "$SUPPORTED_PLATFORMS" == "$PLATFORM" ]
        then
            MATCHED=true
        fi
    done

    if ! $MATCHED
    then
        echo
        #TODO: Loop through the array of supported platforms rather than explicitly list them
        _error "-p must be one of:"
        _error "Global - gbl"
        _error "Regional - rgl"
        _error "Playground - plg"
        return 1
    fi
fi

if [ ${#MODULE} == 0 ]
then
    _error "Missing Terraform module"
    echo
    show_usage "$script_name"
    echo
fi

if [ ${#TF_CODE} != 0 ]
then
    if ! check_path $TF_CODE
    then
        _error "Cannot find $TF_CODE"
    fi
fi

if ! check_file "$MY_PUBLISHED_IP_RANGES"
then
    _error "Cannot find $MY_PUBLISHED_IP_RANGES"
    return 1
fi
# end of checks

# define the association
case $PLATFORM in
    gbl)
        ASSOCIATION="$PLATFORM-$LOCATION"
    ;;
    rgl)
        ASSOCIATION="$PLATFORM-$LOCATION"
        if ! [ ${#ENVIRONMENT} == 0 ]
        then
            ASSOCIATION="$PLATFORM-$LOCATION-$ENVIRONMENT"
        fi
    ;;
    *)
        ASSOCIATION="$PLATFORM-$LOCATION-$ENVIRONMENT"
    ;;
esac

ARM_TENANT_ID=$(az account show | jq -rc '.tenantId')

ARM_SUBSCRIPTION_ID=$(az keyvault secret show --name "$ASSOCIATION" --vault-name "$KEY_VAULT" --only-show-errors 2> /dev/null | jq -rc '.value')
if [ -z "$ARM_SUBSCRIPTION_ID" ]
then
    _error "Cannot find subscription for: $ASSOCIATION"
    return 1
fi

# Get the subscription name
ARM_SUBSCRIPTION_NAME=$(az account list --all | jq --arg SUB "$ARM_SUBSCRIPTION_ID" -rc '.[] | select(.id == $SUB) | .name')

# check for environment configuration directory
if ! check_path "$TF_CODE/configuration/"
then
    _error "Cannot find $TF_CODE/configuration/"
    return 1
fi

# check for root modules directory
if ! check_path "$TF_CODE/root_modules/"
then
    _error "Cannot find $TF_CODE/root_modules"
    return 1
fi

# check for deployment name module
if ! check_path "$TF_CODE/root_modules/$MODULE"
then
    _error "Cannot find $MODULE in $TF_CODE/root_modules/"
    return 1
fi

TERRAFORM_DEPLOYMENT="$TF_CODE/root_modules/$MODULE"

# check for configuration directory and files
case $PLATFORM in
    gbl)
        if ! check_path "$TF_CODE/configuration/global"
        then
            _warning "global not found in $TF_CODE/configuration"
            mkdir -p "$TF_CODE/configuration/global"
        fi
        
        # check for module directory
        if ! check_path "$TF_CODE/configuration/global/$MODULE"
        then
            _warning "$MODULE not found in $TF_CODE/configuration/global"
            mkdir -p "$TF_CODE/configuration/global/$MODULE"
       fi

       TERRAFORM_ENV="$TF_CODE/configuration/global/$MODULE"
       CONTAINER_NAME="$ARM_TENANT_ID"
       STATE_SUBSCRIPTION_ID="$ARM_SUBSCRIPTION_ID"
    ;;
    rgl)
        # check whether the regions directory exists
        if ! check_path "$TF_CODE/configuration/regions"
        then
            _warning "regions not found in $TF_CODE/configuration"
            mkdir -p "$TF_CODE/configuration/regions"
        fi

        # check whether the region directory exists within the regions
        if ! check_path "$TF_CODE/configuration/regions/$LOCATION"
        then
           _warning "$LOCATION not found in $TF_CODE/configuration/regions"
            mkdir -p "$TF_CODE/configuration/regions/$LOCATION"
        fi

        # check whether environment directory exists within the region
        if ! check_path "$TF_CODE/configuration/regions/$LOCATION/$ENVIRONMENT"
        then
            _warning "$ENVIRONMENT not found in $TF_CODE/configuration/regions/$LOCATION"
            mkdir -p "$TF_CODE/configuration/regions/$LOCATION/$ENVIRONMENT"
        fi

        if ! check_path "$TF_CODE/configuration/regions/$LOCATION/$ENVIRONMENT/$MODULE"
        then
            _warning "$MODULE not found in $TF_CODE/configuration/regions/$LOCATION/$ENVIRONMENT"
            mkdir -p "$TF_CODE/configuration/regions/$LOCATION/$ENVIRONMENT/$MODULE"
        fi
          
        TERRAFORM_ENV="$TF_CODE/configuration/regions/$LOCATION/$ENVIRONMENT/$MODULE"
        CONTAINER_NAME="$LOCATION-$ENVIRONMENT"
        
        STATE_SUB="$PLATFORM-$LOCATION-$ENVIRONMENT-state-sub"
        STATE_SUBSCRIPTION_ID="$(az keyvault secret show --name "$STATE_SUB" --vault-name "$KEY_VAULT" --query value --output json 2> /dev/null | sed -e 's/^\"//' -e 's/\"$//')"
        export STATE_SUBSCRIPTION_ID
    ;;
    plg)
        # check whether the platforms directory exists
        if ! check_path "$TF_CODE/configuration/$PLATFORM"
        then
            _warning "$PLATFORM not found in $TF_CODE/configuration"
            mkdir -p "$TF_CODE/configuration/$PLATFORM"
        fi

        # check whether the region directory exists within the platform
        if ! check_path "$TF_CODE/configuration/$PLATFORM/$LOCATION"
        then
           _warning "$LOCATION not found in $TF_CODE/configuration/$PLATFORM"
            mkdir -p "$TF_CODE/configuration/$PLATFORM/$LOCATION"
        fi
        
        # check whether the environment directory exists within the region
        if ! check_path "$TF_CODE/configuration/$PLATFORM/$LOCATION/$ENVIRONMENT"
        then
            _warning "$ENVIRONMENT not found in $TF_CODE/configuration/$PLATFORM/$LOCATION"
            mkdir -p "$TF_CODE/configuration/$PLATFORM/$LOCATION/$ENVIRONMENT"
        fi

        # check for module directory
        if ! check_path "$TF_CODE/configuration/$PLATFORM/$LOCATION/$ENVIRONMENT/$MODULE"
        then
            _warning "$MODULE not found in $TF_CODE/configuration/$PLATFORM/$LOCATION/$ENVIRONMENT"
            mkdir -p "$TF_CODE/configuration/$PLATFORM/$LOCATION/$ENVIRONMENT/$MODULE"
        fi
        
        TERRAFORM_ENV="$TF_CODE/configuration/$PLATFORM/$LOCATION/$ENVIRONMENT/$MODULE"
        CONTAINER_NAME="$LOCATION-$ENVIRONMENT-$PLATFORM"

        STATE_SUB="$PLATFORM-$LOCATION-$ENVIRONMENT-state-sub"
        STATE_SUBSCRIPTION_ID="$(az keyvault secret show --name "$STATE_SUB" --vault-name "$KEY_VAULT" --query value --output json 2> /dev/null | sed -e 's/^\"//' -e 's/\"$//')"
        export STATE_SUBSCRIPTION_ID
    ;;    
esac

case $MODULE in 
    global*)
    TF_VAR_azure_ip_ranges=$(<"$MY_PUBLISHED_IP_RANGES")
    export TF_VAR_azure_ip_ranges
    AZDO_ORG_SERVICE_URL="$(az keyvault secret show --name azdo-service-url --vault-name "$KEY_VAULT" --query value --output json 2> /dev/null | sed -e 's/^\"//' -e 's/\"$//')"
    export AZDO_ORG_SERVICE_URL

    # The Azure DevOps provider requires a PAT token to authenticate if not running in a pipeline
    if [ -z "$TF_BUILD" ]
    then
        read -r -p "Enter your Azure DevOps PAT token: " AZDO_PERSONAL_ACCESS_TOKEN
        export AZDO_PERSONAL_ACCESS_TOKEN
    fi
    ;;
    *)
    AZDO_ORG_SERVICE_URL="$(az keyvault secret show --name azdo-service-url --vault-name "$KEY_VAULT" --query value --output json 2> /dev/null | sed -e 's/^\"//' -e 's/\"$//')"
    export AZDO_ORG_SERVICE_URL

    # The Azure DevOps provider requires a PAT token to authenticate if not running in a pipeline
    if [ -z "$TF_BUILD" ]
    then
        read -r -p "Enter your Azure DevOps PAT token: " AZDO_PERSONAL_ACCESS_TOKEN
        export AZDO_PERSONAL_ACCESS_TOKEN
    fi
    ;;
esac

# Set the Terraform working directory
TF_DATA_DIR=$TERRAFORM_ENV/.terraform

# check whether the container exists within the storage account
CONTAINER_EXISTS=$(az storage container exists --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --auth-mode login --only-show-errors 2> /dev/null | jq -rc .exists)
if [ "$CONTAINER_EXISTS" == "false" ]
then
    _warning "Container: $CONTAINER_NAME not found; creating a container"
    az storage container create --auth-mode login --account-name "$STORAGE_ACCOUNT" --name "$CONTAINER_NAME" > /dev/null 2>&1
fi

# set backend.tfvars values for Terraform AzureRM provider
cat <<EOF >"$TERRAFORM_ENV/backend.tfvars"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
key                  = "$MODULE.tfstate"
use_azuread_auth     = true
subscription_id      = "$STATE_SUBSCRIPTION_ID"
tenant_id            = "$ARM_TENANT_ID"
EOF

output_configuration_name "$PLATFORM" "$LOCATION" "$ENVIRONMENT" "$MODULE"

# export variables
export TF_DATA_DIR
export TERRAFORM_DEPLOYMENT
export TERRAFORM_ENV
export ARM_SUBSCRIPTION_ID
TF_VAR_subscription="$ARM_SUBSCRIPTION_ID"
export TF_VAR_subscription
export ARM_TENANT_ID
TF_VAR_tenant_id="$ARM_TENANT_ID"
export TF_VAR_tenant_id
TF_VAR_location="$LOCATION"
export TF_VAR_location

# export variables for starship
export PLATFORM
export LOCATION
export ENVIRONMENT
export MODULE
export PLATFORM

# If you're not in a pipeline....
if [ -z "$TF_BUILD" ]
then
    echo
    echo "-------------------------------------------------------------------------------------------------" 
    _environment_setup_2_tabs "Terraform Environment setup complete" ""
    echo
    _environment_setup_2_tabs "Terraform Deployment Path:" "$TERRAFORM_DEPLOYMENT"
    _environment_setup_2_tabs "Terraform Configuration Path:" "$TERRAFORM_ENV"
    _environment_setup_3_tabs "Terraform Data Path:" "$TF_DATA_DIR"
    _environment_setup_3_tabs "Azure Subscription Id:" "$ARM_SUBSCRIPTION_ID"
    _environment_setup_2_tabs "Azure Subscription Name:" "$ARM_SUBSCRIPTION_NAME"
fi