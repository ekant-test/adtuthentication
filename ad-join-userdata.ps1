<powershell>

$ErrorActionPreference = "Stop"
# import AWS cmdlets (this can be called multiple times)
Import-Module AWSPowerShell
# better to get region from instance metadata than to guess inputs
$Region = (Get-EC2InstanceMetadata -Category Region | Select-Object -ExpandProperty SystemName)
#only import module on Windows powershell
if ($PSVersionTable.PSEdition -eq "Desktop") {
  Import-Module AWSPowerShell
}
else {
  throw "This script cannot be run on PowerShell $PSVersionTable.PSEdition"
}
# extract instance id from host metadata
$instanceId = (Get-EC2InstanceMetadata -Category InstanceId)
# pet instances typically provide their hostname via automation, if no hostname
# is provided, we assume this is a cattle and hence use instanceId as name
if ([string]::IsNullOrEmpty($ComputerName)) {
  Write-Output "default computer name to instance id ${instanceId}"
  $ComputerName = $instanceId
}
# force the computer name to whatever was provided and restart
if ($ComputerName -ne (hostname)) {
  Write-Output "rename instance ${instanceId} to ${ComputerName}"
  Rename-Computer -NewName $ComputerName -Force
  Restart-Computer -Force
  [Environment]::Exit(0)
}
# if not already domain joined, lets join and restart
if (!(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) {
  Write-Output "domain join instance ${instanceId} with name ${env:COMPUTERNAME}"
  Send-SSMCommand -InstanceId $instanceId -DocumentName "ad-domain-join"
  [Environment]::Exit(0)
}

</powershell>
