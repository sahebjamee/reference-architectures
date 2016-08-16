
# error handling or interruption via ctrl-c.
# line number and error code of executed command is passed to errhandle function

trap 'errhandle $LINENO $?' SIGINT ERR

errhandle()
{
  echo "Error or Interruption at line ${1} exit code ${2} "
  exit ${2}
}

############################################################################

############################################################################
## Command Arguments
############################################################################
function validate() {
    for i in "${@:2}"; do
      if [[ "$1" == "$i" ]]
      then
        return 1
      fi
    done
    
    return 0
}

function validateNotEmpty() {
    if [[ "$1" != "" ]]
    then
      return 1
    else
      return 0
    fi
}

############################################################################
## Command Arguments
############################################################################

URI_BASE=https://raw.githubusercontent.com/mspnp/blueprints/master/ARMBuildingBlocks

# Default parameter values
BASE_NAME=
SUBSCRIPTION=
LOCATION=centralus
OS_TYPE=Windows
ADMIN_USER_NAME=adminUser
ADMIN_PASSWORD=adminP@ssw0rd

NTWK_RESOURCE_GROUP=${BASE_NAME}-ntwk-rg

# VPN parameter defaults
INPUT_ON_PREMISES_PUBLIC_IP=11.22.33.44
INPUT_ON_PREMISES_ADDRESS_SPACE=192.168.0.0/24
INPUT_VPN_IPSEC_SHARED_KEY=myipsecsharedkey123

# VNet parameter defaults
VNET_PREFIX=10.0.0.0/16
VNET_MGMT_SUBNET_PREFIX=10.0.0.0/24
VNET_NVA_FE_SUBNET_PREFIX=10.0.1.0/24
VNET_NVA_BE_SUBNET_PREFIX=10.0.2.0/24
VNET_WEB_SUBNET_PREFIX=10.0.3.0/24
VNET_BIZ_SUBNET_PREFIX=10.0.4.0/24
VNET_DB_SUBNET_PREFIX=10.0.5.0/24
VNET_GATEWAY_SUBNET_ADDRESS_PREFIX=10.0.255.224/27

# the following variables are used in the creation of vpn, web/biz/db tier, but not using in vnet creation
MGMT_JUMPBOX_IP_ADDRESS=10.0.0.254
NVA_FE_ILB_IP_ADDRESS=10.0.1.254
WEB_ILB_IP_ADDRESS=10.0.3.254
BIZ_ILB_IP_ADDRESS=10.0.4.254
DB_ILB_IP_ADDRESS=10.0.5.254

WEB_NUMBER_VMS=2
BIZ_NUMBER_VMS=2
DB_NUMBER_VMS=2

if validateNotEmpty ${SUBSCRIPTION};
then
  echo "A value for SUBSCRIPTION must be provided"
  exit
fi

if validateNotEmpty ${BASE_NAME};
then
  echo "A value for BASE_NAME must be provided"
  exit
fi

echo
echo
echo azure config mode arm
     azure config mode arm
############################################################################
## Create vNet and Subnets for mgmt, nva-fe, nva-be, web, biz, db
############################################################################


TEMPLATE_URI=${URI_BASE}/guidance-hybrid-network-secure-vnet/Templates/ra-vnet-subnets-udr-nsg/azuredeploy.json

RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
ON_PREM_NET_PREFIX=${INPUT_ON_PREMISES_ADDRESS_SPACE}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"onpremNetPrefix\":{\"value\":\"${ON_PREM_NET_PREFIX}\"},\"vnetPrefix\":{\"value\":\"${VNET_PREFIX}\"},\"vnetMgmtSubnetPrefix\":{\"value\":\"${VNET_MGMT_SUBNET_PREFIX}\"},\"vnetNvaFeSubnetPrefix\":{\"value\":\"${VNET_NVA_FE_SUBNET_PREFIX}\"},\"vnetNvaBeSubnetPrefix\":{\"value\":\"${VNET_NVA_BE_SUBNET_PREFIX}\"},\"vnetWebSubnetPrefix\":{\"value\":\"${VNET_WEB_SUBNET_PREFIX}\"},\"vnetBizSubnetPrefix\":{\"value\":\"${VNET_BIZ_SUBNET_PREFIX}\"},\"vnetDbSubnetPrefix\":{\"value\":\"${VNET_DB_SUBNET_PREFIX}\"},\"vnetGwSubnetPrefix\":{\"value\":\"${VNET_GATEWAY_SUBNET_ADDRESS_PREFIX}\"}}"

echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
	 
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

# the following variables are used in the above resource group, you need to use them later to create web/biz/db tier. don't change their values.
DEPLOYED_VNET_NAME=${BASE_NAME}-vnet
DEPLOYED_MGMT_SUBNET_NAME_PREFIX=mgmt
DEPLOYED_NVA_FE_SUBNET_NAME_PREFIX=nva-fe
DEPLOYED_NVA_BE_SUBNET_NAME_PREFIX=nva-be
DEPLOYED_WEB_SUBNET_NAME_PREFIX=web
DEPLOYED_BIZ_SUBNET_NAME_PREFIX=biz
DEPLOYED_DB_SUBNET_NAME_PREFIX=db

DEPLOYED_WEB_SUBNET_NAME=${BASE_NAME}-web-sn
DEPLOYED_BIZ_SUBNET_NAME=${BASE_NAME}-biz-sn
DEPLOYED_DB_SUBNET_NAME=${BASE_NAME}-db-sn

DEPLOYED_WEB_UDR_NAME=${BASE_NAME}-web-udr
DEPLOYED_BIZ_UDR_NAME=${BASE_NAME}-biz-udr
DEPLOYED_DB_UDR_NAME=${BASE_NAME}-db-udr


############################################################################
## Create ILB and VMs in web, biz, db
############################################################################
# create web tier
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-ilb-backend-http-https.json
SUBNET_NAME_PREFIX=${DEPLOYED_WEB_SUBNET_NAME_PREFIX}
ILB_IP_ADDRESS=${WEB_ILB_IP_ADDRESS}
NUMBER_VMS=${WEB_NUMBER_VMS}

RESOURCE_GROUP=${BASE_NAME}-${SUBNET_NAME_PREFIX}-tier-rg
VM_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VM_COMPUTER_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VNET_RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
VNET_NAME=${DEPLOYED_VNET_NAME}
SUBNET_NAME=${DEPLOYED_WEB_SUBNET_NAME}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vnetResourceGroup\":{\"value\":\"${VNET_RESOURCE_GROUP}\"},\"vnetName\":{\"value\":\"${VNET_NAME}\"},\"subnetName\":{\"value\":\"${SUBNET_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"subnetNamePrefix\":{\"value\":\"${SUBNET_NAME_PREFIX}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"osType\":{\"value\":\"${OS_TYPE}\"},\"numberVMs\":{\"value\":${NUMBER_VMS}},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerNamePrefix\":{\"value\":\"${VM_COMPUTER_NAME_PREFIX}\"}}"

echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

# install iis/apache to web vms
for i in `seq 1 ${NUMBER_VMS}`;
do
	VM_NAME=${BASE_NAME}-${VM_NAME_PREFIX}${i}-vm
	PARAMETERS="{\"vmName\":{\"value\":\"${VM_NAME}\"}}"
	if [ "${OS_TYPE}" == "Windows" ]; then
		TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-vm-iis.json
		echo
		echo
		echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
		     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
	fi
	if [ "${OS_TYPE}" == "Ubuntu" ]; then
		TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-vm-apache.json
		echo
		echo
		echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
		     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
	fi
done  

# create biz tier
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-ilb-backend-http-https.json
SUBNET_NAME_PREFIX=${DEPLOYED_BIZ_SUBNET_NAME_PREFIX}
ILB_IP_ADDRESS=${BIZ_ILB_IP_ADDRESS}
NUMBER_VMS=${BIZ_NUMBER_VMS}

RESOURCE_GROUP=${BASE_NAME}-${SUBNET_NAME_PREFIX}-tier-rg
VM_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VM_COMPUTER_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VNET_RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
VNET_NAME=${DEPLOYED_VNET_NAME}
SUBNET_NAME=${DEPLOYED_BIZ_SUBNET_NAME}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vnetResourceGroup\":{\"value\":\"${VNET_RESOURCE_GROUP}\"},\"vnetName\":{\"value\":\"${VNET_NAME}\"},\"subnetName\":{\"value\":\"${SUBNET_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"subnetNamePrefix\":{\"value\":\"${SUBNET_NAME_PREFIX}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"osType\":{\"value\":\"${OS_TYPE}\"},\"numberVMs\":{\"value\":${NUMBER_VMS}},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerNamePrefix\":{\"value\":\"${VM_COMPUTER_NAME_PREFIX}\"}}"

echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

# create db tier
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-ilb-backend-http-https.json
SUBNET_NAME_PREFIX=${DEPLOYED_DB_SUBNET_NAME_PREFIX}
ILB_IP_ADDRESS=${DB_ILB_IP_ADDRESS}
NUMBER_VMS=${DB_NUMBER_VMS}

RESOURCE_GROUP=${BASE_NAME}-${SUBNET_NAME_PREFIX}-tier-rg
VM_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VM_COMPUTER_NAME_PREFIX=${SUBNET_NAME_PREFIX}
VNET_RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
VNET_NAME=${DEPLOYED_VNET_NAME}
SUBNET_NAME=${DEPLOYED_DB_SUBNET_NAME}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vnetResourceGroup\":{\"value\":\"${VNET_RESOURCE_GROUP}\"},\"vnetName\":{\"value\":\"${VNET_NAME}\"},\"subnetName\":{\"value\":\"${SUBNET_NAME}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"subnetNamePrefix\":{\"value\":\"${SUBNET_NAME_PREFIX}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"osType\":{\"value\":\"${OS_TYPE}\"},\"numberVMs\":{\"value\":${NUMBER_VMS}},\"vmNamePrefix\":{\"value\":\"${VM_NAME_PREFIX}\"},\"vmComputerNamePrefix\":{\"value\":\"${VM_COMPUTER_NAME_PREFIX}\"}}"

echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

############################################################################
## Create ILB and VMs in nva subnet and jumbox in management subnet
############################################################################
MGMT_RESOURCE_GROUP=${BASE_NAME}-mgmt-rg
RESOURCE_GROUP=${MGMT_RESOURCE_GROUP}
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/ibb-nvas-mgmt.json

MGMT_SUBNET_NAME_PREFIX=${DEPLOYED_MGMT_SUBNET_NAME_PREFIX}
NVA_FE_SUBNET_NAME_PREFIX=${DEPLOYED_NVA_FE_SUBNET_NAME_PREFIX}
NVA_BE_SUBNET_NAME_PREFIX=${DEPLOYED_NVA_BE_SUBNET_NAME_PREFIX}

MGMT_SUBNET_PREFIX=${VNET_MGMT_SUBNET_PREFIX}
VNET_PREFIX=${VNET_PREFIX}

FE_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${NVA_FE_SUBNET_NAME_PREFIX}-sn
BE_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${NVA_BE_SUBNET_NAME_PREFIX}-sn
MGMT_SUBNET_ID=/subscriptions/${SUBSCRIPTION}/resourceGroups/${NTWK_RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${BASE_NAME}-vnet/subnets/${BASE_NAME}-${MGMT_SUBNET_NAME_PREFIX}-sn
ILB_IP_ADDRESS=${NVA_FE_ILB_IP_ADDRESS}
JUMPBOX_IP_ADDRESS=${MGMT_JUMPBOX_IP_ADDRESS}
VM_SIZE=Standard_DS3
JUMPBOX_OS_TYPE=${OS_TYPE}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vnetPrefix\":{\"value\":\"${VNET_PREFIX}\"},\"mgmtSubnetPrefix\":{\"value\":\"${MGMT_SUBNET_PREFIX}\"},\"feSubnetId\":{\"value\":\"${FE_SUBNET_ID}\"},\"beSubnetId\":{\"value\":\"${BE_SUBNET_ID}\"},\"mgmtSubnetId\":{\"value\":\"${MGMT_SUBNET_ID}\"},\"ilbIpAddress\":{\"value\":\"${ILB_IP_ADDRESS}\"},\"jumpboxIpAddress\":{\"value\":\"${JUMPBOX_IP_ADDRESS}\"},\"adminUsername\":{\"value\":\"${ADMIN_USER_NAME}\"},\"adminPassword\":{\"value\":\"${ADMIN_PASSWORD}\"},\"jumpboxOSType\":{\"value\":\"${JUMPBOX_OS_TYPE}\"},\"vmSize\":{\"value\":\"${VM_SIZE}\"}}"
echo
echo
echo azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
     azure group create --name ${RESOURCE_GROUP} --location ${LOCATION} --subscription ${SUBSCRIPTION}
echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}


#the folloiwng parameters are from the mgmt tier, and is needed for vpn creation
DEPLOYED_GW_UDR_NAME=${BASE_NAME}-gw-udr

############################################################################
## Create VPN Gateway and VPN connection to connect to on premises network
############################################################################
TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-vpn-gateway-connection.json

RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
GATEWAY_SUBNET_ADDRESS_PREFIX=${VNET_GATEWAY_SUBNET_ADDRESS_PREFIX}
VNET_NAME=${DEPLOYED_VNET_NAME}
UDR_NAME=${DEPLOYED_GW_UDR_NAME}
VPN_TYPE=RouteBased
UDR_RESOURCE_GROUP=${MGMT_RESOURCE_GROUP}
ON_PREMISES_PIP=${INPUT_ON_PREMISES_PUBLIC_IP}
ON_PREMISES_ADDRESS_SPACE=${INPUT_ON_PREMISES_ADDRESS_SPACE}
SHARED_KEY=${INPUT_VPN_IPSEC_SHARED_KEY}
PARAMETERS="{\"baseName\":{\"value\":\"${BASE_NAME}\"},\"vnetName\":{\"value\":\"${VNET_NAME}\"},\"gatewaySubnetAddressPrefix\":{\"value\":\"${GATEWAY_SUBNET_ADDRESS_PREFIX}\"},\"vpnType\":{\"value\":\"${VPN_TYPE}\"},\"udrName\":{\"value\":\"${UDR_NAME}\"},\"udrResourceGroup\":{\"value\":\"${UDR_RESOURCE_GROUP}\"},\"onPremisesPIP\":{\"value\":\"${ON_PREMISES_PIP}\"},\"onPremisesAddressSpace\":{\"value\":\"${ON_PREMISES_ADDRESS_SPACE}\"},\"sharedKey\":{\"value\":\"${SHARED_KEY}\"}}"

echo
echo
echo azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
     azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}

############################################################################
## UnComment the following lines to enable forced tunneling in web/biz/db tier
#TEMPLATE_URI=${URI_BASE}/ARMBuildingBlocks/Templates/bb-ntwk-forced-tunneling.json
#RESOURCE_GROUP=${NTWK_RESOURCE_GROUP}
#WEB_UDR_NAME=${DEPLOYED_WEB_UDR_NAME}
#BIZ_UDR_NAME=${DEPLOYED_BIZ_UDR_NAME}
#DB_UDR_NAME=${DEPLOYED_DB_UDR_NAME}
#PARAMETERS="{\"webUdrName\":{\"value\":\"${WEB_UDR_NAME}\"},\"bizUdrName\":{\"value\":\"${BIZ_UDR_NAME}\"},\"dbUdrName\":{\"value\":\"${DB_UDR_NAME}\"}}"
#azure group deployment create --template-uri ${TEMPLATE_URI} -g ${RESOURCE_GROUP} -p ${PARAMETERS}
############################################################################

