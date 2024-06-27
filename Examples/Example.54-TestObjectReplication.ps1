Clear-Host

Import-Module .\ADEssentials.psd1

$objectToQuery = 'CN=Przemysław Kłys,OU=Default,OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'
$Output = Test-WinADObjectReplicationStatus -Identity $objectToQuery -GlobalCatalog -SnapshotPath $PSScriptRoot\Snapshot.xml #-ClearSnapshot
$Output | Format-Table