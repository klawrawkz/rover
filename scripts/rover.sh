#!/bin/bash

source /tf/rover/functions.sh

# Initialize the launchpad first with rover
# deploy a landingzone with 
# rover [landingzone_folder_name] [plan | apply | destroy] [parameters]

# capture the current path
export TF_VAR_workspace="sandpit"
current_path=$(pwd)
landingzone_name=$1
tf_action=$2
shift 2

while (( "$#" )); do
        case "$1" in
        -o|--output)
                tf_output_file=$2
                shift 2
                ;;
        -w|--workspace)
                echo "configurting workspace"
                export TF_VAR_workspace=$2
                shift 2
                ;;
        *) # preserve positional arguments
                echo "else $1"

                PARAMS+="$1 "
                shift
                ;;
        esac
done
 
tf_command=$(echo $PARAMS | sed -e 's/^[ \t]*//')
 
echo "tf_action                     : '$(echo ${tf_action})'"
echo "tf_command                    : '$(echo ${tf_command})'"
echo "landingzone                   : '$(echo ${landingzone_name})'"
echo "terraform command output file : '$(echo ${tf_output_file})' "
echo "workspace                     : '$(echo ${TF_VAR_workspace})'"
echo ""

verify_azure_session
verify_parameters

set -e
trap 'error ${LINENO}' ERR

# Trying to retrieve the terraform state storage account id
id=$(az storage account list --query "[?tags.tfstate=='level0']" | jq -r .[0].id)

if [ "${id}" == '' ]; then
        error ${LINENO} "you must login to an Azure subscription first or logout / login again" 2
fi

# Initialise storage account to store remote terraform state
if [ "${id}" == "null" ]; then
        error ${LINENO} "You need to initialise a launchpad first with the command \n
                launchpad /tf/launchpads/launchpad_opensource_light [plan | apply | destroy]" 1000
else    
        echo ""
        echo "Launchpad already installed"
        # get_remote_state_details
        echo ""
fi

if [ "${landingzone_name}" == *"/tf/launchpads/launchpad_opensource"* ]; then

        error ${LINENO} "You need to manage the launchpad using the command \n
                launchpad /tf/launchpads/launchpad_opensource_light [plan | apply | destroy]" 1001

else
        if [ -z "${landingzone_name}" ]; then 
                display_instructions
        else
                if [ "${tf_action}" == "destroy" ]; then
                        destroy_from_remote_state
                else
                        deploy_from_remote_state
                fi
        fi
fi
