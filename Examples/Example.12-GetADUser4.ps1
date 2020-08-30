Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

# This is very slow, we need to improve
@(
    Get-WinADObject -Identity 'NT AUTHORITY\INTERACTIVE'
    Get-WinADObject -Identity 'INTERACTIVE'
    Get-WinADObject -Identity 'NT AUTHORITY\IUSR'
    Get-WinADObject -Identity 'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
    Get-WinADObject -Identity 'S-1-5-4'
    Get-WinADObject -Identity 'S-1-5-11'
    Get-WinADObject -Identity 'EVOTEC\Domain Admins'
) | Format-Table *

return

@(
    Convert-Identity -Identity 'NT AUTHORITY\INTERACTIVE'
    Convert-Identity -Identity 'INTERACTIVE'
    Convert-Identity -Identity 'EVOTEC\Domain Admins'
    Convert-Identity -Identity 'EVOTECPL\Domain Admins'
) | Format-Table