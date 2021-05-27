Import-Module .\ADEssentials.psd1 -Force

$Output = Get-WinADAllUsers -PerDomain
$Output | Format-Table