Import-Module .\ADEssentials.psd1 -Force

@(
    Get-WinADObject -Identity 'S-1-5-21-853615985-2870445339-3163598659-512'
    Get-WinADObject -Identity 'S-1-5-21-3661168273-3802070955-2987026695-512'
    Get-WinADObject -Identity 'S-1-5-21-3661168273-3802070955-2987026695-512' -DomainDistinguishedName 'ad.evotec.pl'
) | Format-Table *