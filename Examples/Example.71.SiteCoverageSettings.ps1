Import-Module .\ADEssentials.psd1 -Force

Get-WinADSiteCoverage | Format-Table *

Get-WinADDomainControllerNetLogonSettings -DomainController 'AD1'

Set-WinADDomainControllerNetLogonSettings -DomainController 'AD1' -SiteCoverage 'Default-First-Site-Name' -GCSiteCoverage 'Default-First-Site-Name', 'AD1' -WhatIf
Get-WinADDomainControllerNetLogonSettings -DomainController 'AD1'

Set-WinADDomainControllerNetLogonSettings -DomainController 'AD1' -SiteCoverage $null -GCSiteCoverage $null -WhatIf