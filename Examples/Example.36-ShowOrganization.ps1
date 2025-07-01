Import-Module .\ADEssentials.psd1 -Force

#$Output = Get-WinADOrganization -Verbose
#$Output.Domains | Format-Table -AutoSize *
#$Output.OrganizationalUnits['ad.evotec.xyz'][0]

Show-WinADOrganization -FilePath $PSScriptRoot\Reports\Organization.html