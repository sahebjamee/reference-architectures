#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "Central US",
  [Parameter(Mandatory=$false)]
  [ValidateSet("Windows", "Linux")]
  $OSType = "Linux"
)

$templateRootUri = New-Object System.Uri -ArgumentList @("https://raw.githubusercontent.com/mspnp/arm-building-blocks/master/")
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "ARMBuildingBlocks/Templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "ARMBuildingBlocks/Templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json")
$networkSecurityGroupTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "ARMBuildingBlocks/Templates/buildingBlocks/networkSecurityGroups/azuredeploy.json")
$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "..\Parameters", $OSType.ToLower(), "virtualNetwork.parameters.json")
$virtualMachineParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "..\Parameters", $OSType.ToLower(), "virtualMachine.parameters.json")
$networkSecurityGroupParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "..\Parameters", $OSType.ToLower(), "networkSecurityGroups.parameters.json")

$resourceGroupName = "app1-dev-rg"
# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

# Create the resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

Write-Host "Deploying virtual network..."
New-AzureRmResourceGroupDeployment -Name "ra-multi-vm-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersFile

Write-Host "Deploying virtual machine..."
New-AzureRmResourceGroupDeployment -Name "ra-multi-vm-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $virtualMachineParametersFile

Write-Host "Deploying network security group..."
New-AzureRmResourceGroupDeployment -Name "ra-multi-vm-nsg-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $networkSecurityGroupTemplate.AbsoluteUri -TemplateParameterFile $networkSecurityGroupParametersFile
