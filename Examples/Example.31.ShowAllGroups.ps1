Import-Module .\ADEssentials.psd1 -Force

$Output = Get-WinADGroups
$Output | Format-Table