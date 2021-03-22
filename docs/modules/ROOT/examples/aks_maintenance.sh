#!/bin/bash

usage () {
    cat <<HELP_USAGE
    This script requires the following arguments:
    $0 <resource-group> <cluster-name> <nodepool-name> [apply]
    Use 'apply' to execute upgrade.
HELP_USAGE
}

if [  $# -le 2 ] 
	then 
		usage
		exit 1
	fi 

if ! command -v jq &> /dev/null
then
    echo "Cannot run $0. This scripts requires 'jq'. Please install 'jq' first!"
    exit
fi

if ! command -v az &> /dev/null
then
    echo "Cannot run $0. This scripts requires 'az'. Please install 'az' first!"
    exit
fi

RESOURCE_GROUP=$1
CLUSTER_NAME=$2
NODE_POOL=$3
APPLY=$4

echo "Checking nodepool image upgrade"
echo "  Resource group: '$RESOURCE_GROUP'";
echo "  Cluster name: '$CLUSTER_NAME'";
echo "  Nodepool: '$NODE_POOL'";


LATEST_VERSION=$(az aks nodepool get-upgrades --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --nodepool-name $NODE_POOL --only-show-errors | jq -r ".latestNodeImageVersion")
CURRENT_VERSION=$(az aks nodepool show --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $NODE_POOL --query nodeImageVersion --only-show-errors | sed 's/"//g')

echo ""
echo "Latest nodepool image version: '$LATEST_VERSION'"
echo "Curent nodepool image version: '$CURRENT_VERSION'"
echo ""

if [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
    echo "-> Nodepool image upgrade required, upgrading.. please wait.."

    if [ "$APPLY" == "apply" ]; then
        az aks nodepool upgrade --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name $NODE_POOL --node-image-only
        echo "-> Nodepool image upgrade done"
    fi
else
    echo "-> Nodepool image upgrade not required"
fi
