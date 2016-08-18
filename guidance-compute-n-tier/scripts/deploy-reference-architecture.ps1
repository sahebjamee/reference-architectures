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

$resourceGroupName = 'app1-dev-rg'

$templateRootUri = New-Object System.Uri -ArgumentList @('https://raw.githubusercontent.com/mspnp/arm-building-blocks/kirpas/vm-name-fix/ARMBuildingBlocks/Templates/')

# Deployer templates for respective resources
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'buildingBlocks/vnet-n-subnet/azuredeploy.json')
$loadBalancedVmSetTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json')
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json')
$networkSecurityGroupTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'resources/Microsoft.Network/networkSecurityGroups/networkSecurityGroups.json')

# Template parameters for respective deployments
$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\Parameters', $OSType.ToLower(), 'virtualNetwork.parameters.json')
$businessTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\Parameters', $OSType.ToLower(), 'businessTier.parameters.json')
$dataTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\Parameters', $OSType.ToLower(), 'dataTier.parameters.json')
$webTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\Parameters', $OSType.ToLower(), 'webTier.parameters.json')
$managementTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\Parameters', $OSType.ToLower(), 'managementTier.parameters.json')
$networkSecurityGroupParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\Parameters', $OSType.ToLower(), 'networkSecurityGroup.parameters.json')

# Login to Azure and select your subscription
Login-AzureRmAccount | Out-Null
Select-AzureRmSubscription -SubscriptionId $SubscriptionId | Out-Null

# Create the resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

Write-Host "Deploying virtual network..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersFile

Write-Host "Deploying business tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-biz-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $businessTierParametersFile

Write-Host "Deploying data tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-biz-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $dataTierParametersFile

Write-Host "Deploying web tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-biz-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $webTierParametersFile

Write-Host "Deploying management tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-biz-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementTierParametersFile

Write-Host "Deploying network security group"
New-AzureRmResourceGroupDeployment -Name "ra-ntier-vm-nsg-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $networkSecurityGroupTemplate.AbsoluteUri -TemplateParameterFile $networkSecurityGroupParametersFile
