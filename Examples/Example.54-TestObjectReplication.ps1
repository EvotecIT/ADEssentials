Clear-Host

Import-Module .\ADEssentials.psd1


<#
$OutputValue = Test-WinADObjectReplicationStatus -Identity $objectToQuery
$OutputValue | Format-Table
$OutputValue = Test-WinADObjectReplicationStatus -Identity $objectToQuery -GlobalCatalog #-SnapshotPath $PSScriptRoot\Snapshot.xml
$OutputValue | Format-Table
#>
$objectToQuery = 'CN=Przemysław Kłys,OU=Default,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
$Output = Test-WinADObjectReplicationStatus -Identity $objectToQuery -GlobalCatalog -SnapshotPath $PSScriptRoot\Snapshot.xml #-ClearSnapshot
$Output | Format-Table

return

$Output['Summary'][$objectToQuery] | Format-Table
$Output['Summary'][$objectToQuery].Values | ForEach-Object { [PSCustomObject] $_ } | Out-HtmlView -ScrollX -Filtering

$objectToQuery = 'CN=tcs-admin-pk11,OU=TCS Global 11 Accounts,OU=Global,DC=abb,DC=com'