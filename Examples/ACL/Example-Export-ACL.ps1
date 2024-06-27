Clear-Host
Import-Module $PSScriptRoot\..\..\ADEssentials.psd1 -Force

Export-ADACLObject -ADObject 'DC=ad,DC=evotec,DC=xyz' -OneLiner -ExcludePrincipal 'BUILTIN\Pre-Windows 2000 Compatible Access' -Bundle | Format-Table