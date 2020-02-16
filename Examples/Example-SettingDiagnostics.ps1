Import-Module .\ADEssentials.psd1 -Force

Set-WinADDiagnostics -Level Basic -Diagnostics 'LDAP Interface Events' -Verbose