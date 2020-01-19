Import-Module .\ADEssentials.psd1 -Force
Import-Module 'C:\Users\przemyslaw.klys\OneDrive - Evotec\Support\GitHub\PSSharedGoods\PSSharedGoods.psd1' -Force

Set-WinADDiagnostics -Level Basic -Diagnostics 'LDAP Interface Events' -Verbose