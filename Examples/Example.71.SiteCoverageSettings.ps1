Import-Module .\ADEssentials.psd1 -Force

# Show all sites coverage for all domains, in console as object
Get-WinADSiteCoverage -Verbose | Format-Table *

# Show all sites coverage for a specific domain in HTML
Show-WinADSitesCoverage -IncludeDomains 'ad.evotec.xyz' -Verbose

# Get current SiteCoverage and GCSiteCoverage
Get-WinADDomainControllerNetLogonSettings -DomainController 'AD1'

# overwrite SiteCoverage and GCSiteCoverage
Set-WinADDomainControllerNetLogonSettings -DomainController 'AD1' -SiteCoverage 'Default-First-Site-Name' -GCSiteCoverage 'Default-First-Site-Name', 'AD1' -WhatIf

# Get current SiteCoverage and GCSiteCoverage
Get-WinADDomainControllerNetLogonSettings -DomainController 'AD1'

# Remove currently set SiteCoverage and GCSiteCoverage comepletly
Set-WinADDomainControllerNetLogonSettings -DomainController 'AD1' -SiteCoverage $null -GCSiteCoverage $null -WhatIf