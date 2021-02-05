Import-Module .\ADEssentials.psd1 -Force

#Get-WinADACLConfiguration -ObjectType 'interSiteTransport', 'siteLink', 'wellKnownSecurityPrincipals' | Format-Table

Get-WinADACLConfiguration -ContainerType 'sites' -Owner | Format-Table