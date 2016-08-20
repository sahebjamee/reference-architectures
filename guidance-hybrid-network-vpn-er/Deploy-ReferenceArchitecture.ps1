#
# Deploy_ReferenceArchitecture.ps1
#
param(
  [Parameter(Mandatory=$true)]
  $SubscriptionId,
  [Parameter(Mandatory=$false)]
  $Location = "Central US",
  [Parameter(Mandatory=$true)]
  [ValidateSet("Circuit", "Network")]
  $Mode
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

$templateRootUri = New-Object System.Uri -ArgumentList @($templateRootUriString)

$expressRouteCircuitTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/resources/Microsoft.Network/expressRouteCircuits/expressRouteCircuit.json")
$expressRouteCircuitParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\expressRouteCircuit.parameters.json")

$virtualNetworkTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vnet-n-subnet/azuredeploy.json")
$virtualNetworkParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetwork.parameters.json")

$expressRouteGatewayTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$expressRouteGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetworkGateway-expressRoute.parameters.json")

$virtualNetworkGatewayTemplate = New-Object System.Uri -ArgumentList @($templateRootUri, "templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json")
$virtualNetworkGatewayParametersFile = [System.IO.Path]::Combine($PSScriptRoot, "parameters\virtualNetworkGateway-vpn.parameters.json")

$resourceGroupName = "ra-hybrid-vpn-er-rg"
# Login to Azure and select your subscription
Login-AzureRmAccount -SubscriptionId $SubscriptionId | Out-Null

$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -Location $Location -ErrorAction SilentlyContinue
if ($resourceGroup -eq $null) {
  # Create the resource group
  $resourceGroup = New-AzureRmResourceGroup -Name $resourceGroupName -Location $Location
}

if ($Mode -eq "Circuit") {
  Write-Host "Creating ExpressRoute circuit..."
  New-AzureRmResourceGroupDeployment -Name "ra-hybrid-er-circuit-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $expressRouteCircuitTemplate.AbsoluteUri -TemplateParameterFile $expressRouteCircuitParametersFile
}
elseif ($Mode -eq "Network") {
  Write-Host "Deploying virtual network..."
  New-AzureRmResourceGroupDeployment -Name "ra-hybrid-er-vnet-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkParametersFile

  Write-Host "Deploying expressroute gateway..."
  New-AzureRmResourceGroupDeployment -Name "ra-hybrid-er-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $expressRouteGatewayTemplate.AbsoluteUri -TemplateParameterFile $expressRouteGatewayParametersFile

  Write-Host "Deploying virtual network gateway..."
  New-AzureRmResourceGroupDeployment -Name "ra-hybrid-vpn-deployment" -ResourceGroupName $resourceGroup.ResourceGroupName `
    -TemplateUri $virtualNetworkGatewayTemplate.AbsoluteUri -TemplateParameterFile $virtualNetworkGatewayParametersFile
}
