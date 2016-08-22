#!/bin/bash

RESOURCE_GROUP_NAME="ra-hybrid-vpn-er-rg"
LOCATION="centralus"
MODE=""

TEMPLATE_ROOT_URI=${TEMPLATE_ROOT_URI:="https://raw.githubusercontent.com/mspnp/template-building-blocks/master/"}
# Make sure we have a trailing slash
[[ "${TEMPLATE_ROOT_URI}" != */ ]] && TEMPLATE_ROOT_URI="${TEMPLATE_ROOT_URI}/"

# For validating HTTP URIs only
URI_REGEX="^((?:https?://(?:(?:[a-zA-Z0-9$.+!*(),;?&=_-]|(?:%[a-fA-F0-9]{2})){1,64}(?::(?:[a-zA-Z0-9$.+!*(),;?&=_-]|(?:%[a-fA-F0-9]{2})){1,25})?@)?)?(?:(([a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]([a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF-]{0,61}[a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]){0,1}\.)+[a-zA-Z\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF]{2,63}|((25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[0-9]))))(?::\d{1,5})?)(/(?:(?:[a-zA-Z0-9\x00A0-\xD7FF\xF900-\xFDCF\xFDF0-\xFFEF;/?:@&=#~.+!*(),_-])|(?:%[a-fA-F0-9]{2}))*)?(?:\b|$)$"

validate() {
    for i in "${@:2}"; do
      if [[ "$1" == "$i" ]]
      then
        return 1 
      fi
    done
    
    return 0 
}

validateNotEmpty() {
    if [[ "$1" != "" ]]
    then
      return 1
    else
      return 0
    fi
}

showErrorAndUsage() {
  echo
  if [[ "$1" != "" ]]
  then
    echo "  error:  $1"
    echo
  fi
  echo "  usage:  $(basename ${0}) [options]"
  echo "  options:"
  echo "    -l, --location <location>"
  echo "    -m, --mode <circuit | network>"
  echo "    -s, --subscription <subscription-id>"
  echo
  exit 1
}

if [[ $# < 1 ]]
then
  showErrorAndUsage
fi

while [[ $# > 0 ]]
do
  key="$1"
  case $key in
    -l|--location)
      LOCATION="$2"
      shift
      ;;
    -m|--mode)
      MODE="$2"
      shift
      ;;
    -s|--subscription)
      SUBSCRIPTION_ID="$2"
      shift
      ;;
    *)
      showErrorAndUsage "Unknown option: $1"
    ;;
  esac
  shift
done

if ! [[ $SUBSCRIPTION_ID =~ ^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$  ]];
then
  showErrorAndUsage "Invalid Subscription ID."
fi

if validateNotEmpty $LOCATION;
then
  showErrorAndUsage "Location must be provided."
fi

if validate $MODE "circuit" "network";
then
  showErrorAndUsage "Invalid mode: '${MODE}'.  Valid values are 'circuit' or 'network'."
fi

if grep -P -v $URI_REGEX <<< $TEMPLATE_ROOT_URI > /dev/null
then
  showErrorAndUsage "Invalid value for TEMPLATE_ROOT_URI: ${TEMPLATE_ROOT_URI}"
fi

echo
echo "Using ${TEMPLATE_ROOT_URI} to locate templates"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXPRESS_ROUTE_CIRCUIT_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/resources/Microsoft.Network/expressRouteCircuits/expressRouteCircuit.json"
EXPRESS_ROUTE_CIRCUIT_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/expressRouteCircuit.parameters.json"
EXPRESS_ROUTE_CIRCUIT_DEPLOYMENT_NAME="ra-hybrid-vpn-er-circuit-deployment"

VIRTUAL_NETWORK_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
VIRTUAL_NETWORK_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/virtualNetwork.parameters.json"
VIRTUAL_NETWORK_DEPLOYMENT_NAME="ra-hybrid-vpn-er-vnet-deployment"

EXPRESS_ROUTE_GATEWAY_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"
EXPRESS_ROUTE_GATEWAY_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/virtualNetworkGateway-expressRoute.parameters.json"
EXPRESS_ROUTE_GATEWAY_DEPLOYMENT_NAME="ra-hybrid-er-deployment"

VIRTUAL_NETWORK_GATEWAY_TEMPLATE_URI="${TEMPLATE_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"
VIRTUAL_NETWORK_GATEWAY_PARAMETERS_PATH="${SCRIPT_DIR}/parameters/virtualNetworkGateway-vpn.parameters.json"
VIRTUAL_NETWORK_GATEWAY_DEPLOYMENT_NAME="ra-hybrid-vpn-deployment"

azure config mode arm

if ! RESOURCE_GROUP_OUTPUT=$(azure group show --name $RESOURCE_GROUP_NAME --subscription $SUBSCRIPTION_ID --json 2> /dev/null)
then
  # The resource group doesn't exist, so create the resource group and save the output for later.
  RESOURCE_GROUP_OUTPUT=$(azure group create --name $RESOURCE_GROUP_NAME --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1
fi

if [[ $MODE == "circuit" ]]
then
  echo "Creating ExpressRoute circuit..."
  azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $EXPRESS_ROUTE_CIRCUIT_DEPLOYMENT_NAME \
  --template-uri $EXPRESS_ROUTE_CIRCUIT_TEMPLATE_URI --parameters-file $EXPRESS_ROUTE_CIRCUIT_PARAMETERS_PATH \
  --subscription $SUBSCRIPTION_ID || exit 1
  
  # Display json output
  echo "==================================="

  echo $RESOURCE_GROUP_OUTPUT

  azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $EXPRESS_ROUTE_CIRCUIT_DEPLOYMENT_NAME \
  --subscription $SUBSCRIPTION_ID --json || exit 1

  echo "==================================="
elif [[ $MODE == "network" ]]
then
  # Create the virtual network
  echo "Deploying virtual network..."
  azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_DEPLOYMENT_NAME \
  --template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters-file $VIRTUAL_NETWORK_PARAMETERS_PATH \
  --subscription $SUBSCRIPTION_ID || exit 1

  echo "Deploying expressroute gateway..."
  azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $EXPRESS_ROUTE_GATEWAY_DEPLOYMENT_NAME \
  --template-uri $EXPRESS_ROUTE_GATEWAY_TEMPLATE_URI --parameters-file $EXPRESS_ROUTE_GATEWAY_PARAMETERS_PATH \
  --subscription $SUBSCRIPTION_ID || exit 1

  echo "Deploying virtual network gateway..."
  azure group deployment create --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_GATEWAY_DEPLOYMENT_NAME \
  --template-uri $VIRTUAL_NETWORK_GATEWAY_TEMPLATE_URI --parameters-file $VIRTUAL_NETWORK_GATEWAY_PARAMETERS_PATH \
  --subscription $SUBSCRIPTION_ID || exit 1

  # Display json output
  echo "==================================="

  echo $RESOURCE_GROUP_OUTPUT

  azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_DEPLOYMENT_NAME \
  --subscription $SUBSCRIPTION_ID --json || exit 1

  azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $EXPRESS_ROUTE_GATEWAY_DEPLOYMENT_NAME \
  --subscription $SUBSCRIPTION_ID --json || exit 1

  azure group deployment show --resource-group $RESOURCE_GROUP_NAME --name $VIRTUAL_NETWORK_GATEWAY_DEPLOYMENT_NAME \
  --subscription $SUBSCRIPTION_ID --json || exit 1

  echo "==================================="
fi
