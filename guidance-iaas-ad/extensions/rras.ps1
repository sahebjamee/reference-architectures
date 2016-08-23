Install-WindowsFeature Routing  -IncludeAllSubFeature -IncludeManagementTools
Install-WindowsFeature RSAT-RemoteAccess-PowerShell -IncludeAllSubFeature -IncludeManagementTools
Install-RemoteAccess -VpnType VpnS2S
Stop-Service RemoteAccess
netsh ras set type ipv4rtrtype=LANANDDD ipv6rtrtype=none rastype=none
Start-Service RemoteAccess 
