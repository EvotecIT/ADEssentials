Import-Module .\ADEssentials.psd1 -Force

$DCs = @(
    Get-WinADBitlockerLapsSummary -SearchBase "OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz"
    Get-WinADBitlockerLapsSummary -SearchBase "OU=Domain Controllers,DC=ad,DC=evotec,DC=pl"
)

$Dcs | Format-Table Name, Domain, *WindowsLaps*