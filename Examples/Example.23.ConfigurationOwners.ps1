Import-Module .\ADEssentials.psd1 -Force

#Get-WinADACLConfiguration -ObjectType 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipal' | Format-Table

Get-WinADACLConfiguration -ObjectType site -Owner -Verbose | Format-Table

Repair-WinADACLConfigurationOwner -ObjectType site -Verbose -WhatIf