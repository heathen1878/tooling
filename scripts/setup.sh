#!/bin/bash 

# variables
declare OPTARG=""
declare OPTIND=1
declare flag=""
declare MODULE=""
declare SUPPORTED_ENVIRONMENTS=("dev" "test" "preprod" "prod" "sbx")
declare TF_CODE="iac"
declare ENVIRONMENT_VARIABLES=("ARM_SUBSCRIPTION_ID" "ARM_TENANT_ID" "STATE_STORAGE_ACCOUNT" "LOCATION" "ENVIRONMENT" "PLATFORM")

# Checks
# This is required to export the environment variables to the calling shell
if [ "$BASH_SOURCE" == "$0" ]
then
    show_usage "$0"
    exit 1
fi

script_name="$(basename "${BASH_SOURCE[0]}")"

# check script for input parameters
if (( $# == 0 ))
then
    _error "No arguments defined"
    echo
    show_usage "$script_name"
    return 1
fi

# Determine whether required environment variables have been set.
for var in "${ENVIRONMENT_VARIABLES[@]}"
do
    if [[ -z "${!var}" ]]
    then
        case $var in 
            ARM_SUBSCRIPTION_ID)
                _error "Environment variable: '$var' is NOT set!"
                echo
                _info "please set it using export $var=00000000-0000-0000-0000-000000000000"
                return 1
            ;;
            ARM_TENANT_ID)
                _error "Environment variable: '$var' is NOT set!"
                echo
                _info "please set it using export $var=00000000-0000-0000-0000-000000000000"
                return 1
            ;;
            STATE_STORAGE_ACCOUNT)
                _error "Environment variable: '$var' is NOT set!"
                echo
                _info "please set it using export $var=st..."
                return 1
            ;;
            LOCATION)
                _error "Environment variable: '$var' is NOT set!"
                _info "Valid locations are: "
                _environment_check_1_tab "" "uksouth"
                _environment_check_1_tab "" "ukwest"
                echo
                _info "please set it using export $var=..."
                return 1
            ;;
            ENVIRONMENT)
                _error "Environment variable: '$var' is NOT set!"
                _info "Valid environments are: "
                _environment_check_1_tab "" "sbx"
                _environment_check_1_tab "" "dev"
                _environment_check_1_tab "" "test"
                _environment_check_1_tab "" "preprod"
                _environment_check_1_tab "" "prod"
                echo
                _info "please set it using export $var=..."
                return 1
            ;;
            PLATFORM)
                _error "Environment variable: '$var' is NOT set!"
                _info "Valid platforms are: "
                _environment_check_1_tab "" "tooling"
                _environment_check_1_tab "" "evology"
                _environment_check_1_tab "" "cayenne"
                echo
                _info "please set it using export $var=..."
                return 1
            ;;
        esac
    fi
done

# Get the subscription name
ARM_SUBSCRIPTION_NAME=$(az account list --all | jq --arg SUB "$ARM_SUBSCRIPTION_ID" -rc '.[] | select(.id == $SUB) | .name')
STATE_SUBSCRIPTION_NAME=$(az account list --all | jq --arg SUB "$STATE_SUBSCRIPTION_ID" -rc '.[] | select(.id == $SUB) | .name')

# Grab the script execution path to determine where the tooling directory is
# This is used to grab the list of published addresses from Microsoft
# MY_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
# MY_PATH="$(cd -- "$MY_PATH" && pwd)"
# MY_PATH="${MY_PATH%/*}"
# MY_PUBLISHED_IP_RANGES=$MY_PATH$PUBLISHED_IP_RANGES

# -m for module is mandatory whereas -t for terraform is optional...as the default is iac
while getopts "m:t:" flag
do
    case "${flag}" in
        m) # process module
            MODULE="${OPTARG}"
            MODULE="$(echo "$MODULE" | awk '{print tolower($0)}')"
        ;;
        t) # process tf code repo
            TF_CODE="${OPTARG}"
            TF_CODE="$(echo "$TF_CODE" | awk '{print tolower($0)}')"
        ;;
        *)
            show_usage
        ;;
    esac
done

shift "$(( OPTIND - 1 ))"

if [ ${#MODULE} == 0 ]
then
    _error "Missing Terraform module"
    echo
    show_usage "$script_name"
    echo
    return 1
fi

if [ ${#TF_CODE} != 0 ]
then
    if ! check_path $TF_CODE
    then
        _error "Cannot find $TF_CODE"
        return 1
    fi
fi

# if ! check_file "$MY_PUBLISHED_IP_RANGES"
# then
#     _error "Cannot find $MY_PUBLISHED_IP_RANGES"
#     return 1
# fi
# # end of checks

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

TERRAFORM_DEPLOYMENT="${PWD}/$TF_CODE/root_modules/$MODULE"

# check for configuration directories and files
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
        
TERRAFORM_ENV="${PWD}/$TF_CODE/configuration/$PLATFORM/$LOCATION/$ENVIRONMENT/$MODULE"
CONTAINER_NAME="$LOCATION-$ENVIRONMENT-$PLATFORM"

# Set the Terraform working directory
TF_DATA_DIR=$TERRAFORM_ENV/.terraform

# check whether the container exists within the storage account
CONTAINER_EXISTS=$(az storage container exists --name "$CONTAINER_NAME" --account-name "$STATE_STORAGE_ACCOUNT" --auth-mode login --only-show-errors 2> /dev/null | jq -rc .exists)
if [ "$CONTAINER_EXISTS" == "false" ]
then
    _warning "Container: $CONTAINER_NAME not found; creating a container"
    az storage container create --auth-mode login --account-name "$STATE_STORAGE_ACCOUNT" --name "$CONTAINER_NAME" > /dev/null 2>&1
fi

# set backend.tfvars values for Terraform AzureRM provider
cat <<EOF >"$TERRAFORM_ENV/backend.tfvars"
storage_account_name = "$STATE_STORAGE_ACCOUNT"
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
TF_VAR_location="$LOCATION"
export TF_VAR_location

# export variables for starship
export MODULE

# If you're not in a pipeline....
if [ -n "$TF_BUILD" ]
then
    echo
    echo "-------------------------------------------------------------------------------------------------" 
    echo "Terraform Environment setup complete" ""
    echo
    echo "Terraform Deployment Path:" "$TERRAFORM_DEPLOYMENT"
    echo "Terraform Configuration Path:" "$TERRAFORM_ENV"
else
    echo
    echo "-------------------------------------------------------------------------------------------------" 
    _environment_setup_2_tabs "Terraform Environment setup complete" ""
    echo
    _environment_setup_2_tabs "Terraform Deployment Path:" "$TERRAFORM_DEPLOYMENT"
    _environment_setup_2_tabs "Terraform Configuration Path:" "$TERRAFORM_ENV"
    _environment_setup_3_tabs "Terraform Data Path:" "$TF_DATA_DIR"
    _environment_setup_1_tab "Terraform State Azure Subscription Id:" "$STATE_SUBSCRIPTION_ID"
    _environment_setup_1_tab "Terraform State Subscription Name:" "$ARM_SUBSCRIPTION_NAME"
    _environment_setup_1_tab "Deployment Azure Subscription Id:" "$ARM_SUBSCRIPTION_ID"
    _environment_setup_1_tab "Deployment Azure Subscription Name:" "$ARM_SUBSCRIPTION_NAME"
fi