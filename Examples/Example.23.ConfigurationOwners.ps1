Import-Module .\ADEssentials.psd1 -Force

#Get-WinADForestObjectsPermissions -ObjectType 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipals' | Format-Table

Get-WinADForestObjectsPermissions -ContainerType 'sites' -Owner | Format-Table