Import-Module .\ADEssentials.psd1 -Force

# Tests whole forest
$LastBackup = Get-WinADLastBackup
$LastBackup | Format-Table -AutoSize

# Tests just one or more domains
$LastBackup = Get-WinADLastBackup -Domain 'ad.evotec.pl', 'ad.evotec.xyz'
$LastBackup | Format-Table -AutoSize