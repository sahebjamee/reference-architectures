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

$ErrorActionPreference = "Stop"

$templateRootUriString = $env:TEMPLATE_ROOT_URI
if ($templateRootUriString -eq $null) {
  $templateRootUriString = "https://raw.githubusercontent.com/mspnp/template-building-blocks/master/"
}

if (![System.Uri]::IsWellFormedUriString($templateRootUriString, [System.UriKind]::Absolute)) {
  throw "Invalid value for TEMPLATE_ROOT_URI: $env:TEMPLATE_ROOT_URI"
}

Write-Host
Write-Host "Using $templateRootUriString to locate templates"
Write-Host

# Deployer templates for respective resources
$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)
$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/vnet-n-subnet/azuredeploy.json')
$loadBalancedVmSetTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/loadBalancer-backend-n-vm/azuredeploy.json')
$virtualMachineTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json')
$networkSecurityGroupTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, 'templates/buildingBlocks/networkSecurityGroups/azuredeploy.json')

# Template parameters for respective deployments
$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\parameters', $OSType.ToLower(), 'virtualNetwork.parameters.json')
$businessTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\parameters', $OSType.ToLower(), 'businessTier.parameters.json')
$dataTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\parameters', $OSType.ToLower(), 'dataTier.parameters.json')
$webTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\parameters', $OSType.ToLower(), 'webTier.parameters.json')
$managementTierParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\parameters', $OSType.ToLower(), 'managementTier.parameters.json')
$networkSecurityGroupParametersFile = [System.IO.Path]::Combine($PSScriptRoot, '..\parameters', $OSType.ToLower(), 'networkSecurityGroups.parameters.json')

$resourceGroupName = "ra-ntier-vm-rg"

# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

# Create the resource group
$resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location

Write-Host "Deploying virtual network..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersFile

Write-Host "Deploying business tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-biz-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $businessTierParametersFile

Write-Host "Deploying data tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-data-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $dataTierParametersFile

Write-Host "Deploying web tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-web-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $loadBalancedVmSetTemplate.AbsoluteUri -TemplateParameterFile $webTierParametersFile

Write-Host "Deploying management tier..."
New-AzureRmResourceGroupDeployment -Name "ra-ntier-mgmt-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualMachineTemplate.AbsoluteUri -TemplateParameterFile $managementTierParametersFile

Write-Host "Deploying network security group"
New-AzureRmResourceGroupDeployment -Name "ra-ntier-nsg-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $networkSecurityGroupTemplate.AbsoluteUri -TemplateParameterFile $networkSecurityGroupParametersFile
