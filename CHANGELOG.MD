#### 0.0.219 - 2024.08.23
- Improve `Get-WinADSiteCoverage`
- Added `Show-WinADSitesCoverage`

#### 0.0.218 - 2024.08.13
- Improve `Get-WinADSiteCoverage` by adding verbose messages on count

#### 0.0.217 - 2024.08.12
##### What's new
- Added `Get-WinADDomainControllerNetLogonSettings`
- Added `Set-WinADDomainControllerNetLogonSettings`
- Added `Get-WinADDomainControllerNTDSSettings`
- Added `Get-WinADSiteCoverage`

##### What's Changed
* Help created by @neztach in https://github.com/EvotecIT/ADEssentials/pull/47

##### New Contributors
* @neztach made their first contribution in https://github.com/EvotecIT/ADEssentials/pull/47

#### 0.0.216
- Improves `Test-Ldap` to handle error reporting properly in some cases and retry count as expected
- Improve `Show-WinADGroupMember` and `Show-WinADGroupMemberOf` and `Show-WinADGroupCritical` by adding ability to filter diagram via `EnableDiagramFilteringButton`

#### 0.0.215
- Add `EnableDiagramFiltering`,`DiagramFilteringMinimumCharacters` and `ScrollX` to `Show-WinADGroupMember` and `Show-WinADGroupMemberOf` and `Show-WinADGroupCritical` to allow better filtering and scrolling

#### 0.0.214
- Bugfix for `Test-LDAP`

#### 0.0.213
- Improve & Simplify `Test-LDAP` logic
- Add few fields in `Test-LDAP` for easier assesment

#### 0.0.212 - 2024.05.22
- Fix for `Test-WinADObjectReplicationStatus`

#### 0.0.211 - 2024.05.22
- Improve and simplify `Test-WinADObjectReplicationStatus`

#### 0.0.210 - 2024.05.21
- Improve `Compare-WinADGlobalCatalogObjects` on reporting
- Improve `Invoke-ADEssentials`: `GlobalCatalogComparison` on reporting

#### 0.0.209 - 2024.05.13
- Improve `Compare-WinADGlobalCatalogObjects` on reporting
- Improve `Invoke-ADEssentials`: `GlobalCatalogComparison` on reporting

#### 0.0.208 - 2024.05.13
- Improve `Compare-WinADGlobalCatalogObjects` on reporting
- Improve `Invoke-ADEssentials`: `GlobalCatalogComparison` on reporting

#### 0.0.207 - 2024.05.09
- Improve `Compare-WinADGlobalCatalogObjects` on reporting
- Improve `Invoke-ADEssentials`: `GlobalCatalogComparison` on reporting
- Removed reverse search and made it ignore objects updated lass than 24 hours ago

#### 0.0.206 - 2024.05.08
- Improve `Compare-WinADGlobalCatalogObjects` on reporting (remove ignored objects as not nessecary / added reverse search)
- Improve `Invoke-ADEssentials`: `GlobalCatalogComparison` on reporting (remove ignored objects as not nessecary / added reverse search)

#### 0.0.205 - 2024.05.01
- Improve `Invoke-PingCastle`

#### 0.0.204 - 2024.05.01
- Improvements to `Compare-WinADGlobalCatalogObjects` on reporting
- Added `Compare-PingCastleReport` to compare 2 PingCastle reports (XML files)
- Added `Invoke-PingCastle` to run PingCastle report (requires PingCastle installed)
- Added `Get-PingCastleReport` to read XML file from PingCastle

#### 0.0.203 - 2024.04.30
- Improvements to `Compare-WinADGlobalCatalogObjects` on error handling and reporting

#### 0.0.202 - 2024.04.30
- Improvements to `Compare-WinADGlobalCatalogObjects` on error handling and reporting

#### 0.0.201 - 2024.04.30
- Improvements to `Compare-WinADGlobalCatalogObjects` on error handling

#### 0.0.200 - 2024.04.29
- Improvements to `Compare-WinADGlobalCatalogObjects` on error handling

#### 0.0.199 - 2024.04.29
- Improvements to `Compare-WinADGlobalCatalogObjects` on reporting

#### 0.0.198 - 2024.04.29
- Improvements to `Compare-WinADGlobalCatalogObjects` to skip source server

#### 0.0.197 - 2024.04.29
- Improve `Compare-WinADGlobalCatalogObjects` by adding `IncludeDomains`,`ExcludeDomains`,`Forest`

#### 0.0.196 - 2024.04.28
- Added `Compare-WinADGlobalCatalogObjects`
- Added new type to `Invoke-ADEssentials`: `GlobalCatalogComparison`

#### 0.0.195 - 2024.04.24
- Improve `Get-WinADForestReplicationSummary` by enhancing UniqueWarnings and fixing minor issues

#### 0.0.194 - 2024.04.24
- Improve `Get-WinADForestReplicationSummary` by providing UniqueWarnings and missing replication errors

#### 0.0.193 - 2024.04.23
- Fixes [#44](https://github.com/EvotecIT/ADEssentials/issues/44)

#### 0.0.192 - 2024.04.17
- Improve `Get-WinADForestReplicationSummary` with more information

#### 0.0.191 - 2024.04.16
- Renamed with aliases preserved:
  - Renamed `Get-WinDnsIPAddresses` to `Get-WinADDNSIPAddresses`
  - Renamed `Get-WinDnsRecords` to `Get-WinADDNSRecords`
  - Renamed `Get-WinDnsZones` to `Get-WinADDNSZones`
- Improve Laps and Bitlocker reporting in `Invoke-ADEssentials`
- Added `Get-WinADomainControllerrGenerationId`
- Added `Get-WinADForestReplicationSummary` wrapper around `repadmin /replsummary`
- Added `Get-WinADDomainControllerGenerationId` to get GenerationId for Domain Controllers (VM ID)
- Copied from `PSWinDocumentation.DNS`
  - Copied from `PSWinDocumentation.DNS` - `Get-WinADDnsInformation` as is with function rename to minimize dependencies for Testimo and further improvements
  - Copied from `PSWinDocumentation.DNS` - `Get-WinADDnsServerForwarder` as is with function rename to minimize dependencies for Testimo and further improvements
  - Copied from `PSWinDocumentation.DNS` - `Get-WinADDnsServerScavenging` as is with function rename to minimize dependencies for Testimo and further improvements
  - Copied from `PSWinDocumentation.DNS` - `Get-WinADDnsServerZones` as is with function rename to minimize dependencies for Testimo and further improvements

#### 0.0.190 - 2024.03.07
- Added `Test-WinADDNSResolving` - This command will test DNS resolving for given domain and record type. It will return all DNS servers that were used to resolve the query and the result of the query.

#### 0.0.189 - 2024.02.29
- Improved `Get-WinADGroupMember` to handle empty groups and prevent null returns
- Improved `Get-WinADPrivilegedObjects` to handle empty groups and prevent null returns

#### 0.0.187 - 2024.02.19
- Update `Test-WinADObjectReplicationStatus` with additional error handling

#### 0.0.187 - 2024.02.19
- Update `Test-WinADObjectReplicationStatus` with additional error handling

#### 0.0.186 - 2024.02.07
- Update `Get-WinADDuplicateObject` with additional error handling

#### 0.0.185 - 2024.01.25
- Improves `Test-LDAP` to ignore test for GC LDAP if server is not Global Catalog. Related queries return `$null`

#### 0.0.184 - 2024.01.24
- Improves `Test-LDAP` to allow querying for `Identity`
- Improves `Get-WinADDuplicateObject` by
- Improves `Remove-WinADDuplicateObject` to adjust for changes in `Get-WinADDuplicateObject`
- Modify `Test-DNSNameServers` to convert scriptblock filtering to string
- Modify `New-ADSite` to convert scriptblock filtering to string
- Modify `Get-WinADUsersForeignSecurityPrincipalList` to convert scriptblock filtering to string
- Modify `Get-WinDNSRecords` to convert scriptblock filtering to string
- Modify `Get-WinDNSIPAddresses` to convert scriptblock filtering to string
- Convert * to '*' in multiple functions

#### 0.0.182 - 2024.01.03
- Improves `Test-LDAP` when using credential parameter

#### 0.0.181 - 2024.01.02
- Fixes `Test-LDAP`

#### 0.0.180 - 2024.01.02
- Fixes `Test-LDAP`

#### 0.0.179 - 2023.12.20
- Improve `Get-WinADKerberosAccount`
- Improve `Show-WinADKerberosAccount`

#### 0.0.178 - 2023.12.18
- Improve `Get-WinADKerberosAccount` WIP
- Improve `Show-WinADKerberosAccount` WIP

#### 0.0.177 - 2023.12.17
- Improve `Get-WinADKerberosAccount` WIP
- Improve `Show-WinADKerberosAccount` WIP

#### 0.0.176
- Improve `Get-WinADKerberosAccount` WIP
- Improve `Show-WinADKerberosAccount` WIP

#### 0.0.175
- Added `Request-ChangePasswordAtLogon` - This command will find all users that have expired password and set them to change password at next logon. This is useful for example for Azure AD Connect where you want to force users to change password on next logon.
- Added `Request-DisableOnAccountExpiration` - This command will find all users that have expired account and set them to be disabled. This is useful for example for Azure AD Connect where you want to disable users that have expired account.
- Added `Get-WinADKerberosAccount` WIP
- Adddd `Show-WinADKerberosAccount` WIP

#### 0.0.174
- Improve `Get-WinADUsers` error handling
- Improve `Test-LDAP` parameters handling
- Fixes issue when providing IncludeDomainControllers that would sometime return null value
- Added `Update-LastLogonTimestamp` - to impersonate user and update LastLogonTimestamp without requring to log-in (Domain Admins only, without ProtectedUsers group)
- Improvements to `Find-WinADObjectDifference`
- Added `Get-WinADDFSTopology`

#### 0.0.173
- Improvements to `Find-WinADObjectDifference`

#### 0.0.172
- Improvements to `Show-WinADObjectDifference`
- Improvements to `Find-WinADObjectDifference`

#### 0.0.171 - 2023.11.20
- Renamed `Sync-DomainController` to `Sync-WinADDomainController` (aliased)
- Added `Get-WinADSiteOptions`
- Added `Show-WinADDNSRecords`
- Improved `Get-WinDNSRecords` to display tombstoned DNS records
- Added `Get-WinDNSZones`, requires improvements
- Added `Find-WinADObjectDifference`
- Added `Show-WinADObjectDifference`
- Added `Get-WinADDomainControllerOption`
- Improved `Get-WinADForestControllerInformation` with more information
- Fixed `Get-WinADForestSubnet` not working under certain parameters
- Added `Set-WinADDomainControllerOption`
- Added `Test-WinADObjectReplicationStatus` *work in progress*

#### 0.0.170 - 2023.10.22
- `Enable-ADACLInheritance` - improve documentation
- `Restore-ADACLDefault` - added new function to restore default ACL permissions
- `Set-ADACLInheritance` - improve documentation

#### 0.0.169 - 2023.10.13
- Improvements to `Invoke-ADEssentials` to LAPS report counting
- Improvements to `Get-WinADBitlockerLapsSummary` changed to True/False/Null

#### 0.0.168 - 2023.10.13
- Improvements to `Invoke-ADEssentials` to LAPS report

#### 0.0.167 - 2023.10.13
- Update `Remove-ADACL` to better handle `ProtectedFromDeletion`
- Improvements to `Invoke-ADEssentials` to LAPS report
- Improvements to `Get-WinADBitlockerLapsSummary` true/false changed to 'Yes','No', 'N/A'

#### 0.0.166 - 2023.10.09
- Update `Set-ADACLinheritance` / `Disable-ADACLInheritance`

#### 0.0.165 - 2023.09.13
- Update `Get-WinADForestControllerInformation` - Remove AzureADKerberos account from DomainControllers

#### 0.0.164 - 2023.08.12
- Fixes detection of contacts inside groups `Get-WinADGroupMember`, `Get-WinADObject`

#### 0.0.163 - 2023.08.03
- Improve HTML reports

#### 0.0.162 - 2023.08.02
- Improve output of `Get-WinADComputers` **Possibly breaking change** when using no parameters
- Add `WindowsLAPS` detection in `Get-WinADForestOptionalFeatures`
- Add `WindowsLAPS` detection in `Get-WinADComputerACLLAPS`
- `Invoke-ADEssentials -Type Laps, LapsACL, LapsAndBitLocker -Online` by adding WindowsLAPS

#### 0.0.161 - 2023.07.02
- `Get-WinADObject` - added support for `contact`, `inetOrgPerson`
- `Show-WinADGroupMember/Show-WinADGroupMemberOf` - added support for `contact`, `inetOrgPerson`
- `Get-WinADGroupMember/Get-WinADGroupMemberOf` - added more verbose logging so you can see what's going on in more details
- Small text improvement to `Invoke-ADESsentials` `Computers` report
- Added `PasswordPolicies` to `Invoke-ADEssentials`
- Added `Get-WinADPasswordPolicy` (make sure you have rights to read FineGrainedPasswordPolicy)
- Improved `Get-WinADUsers` adding password policies to it, and who's affected with which policy
- Improved `Invoke-ADEssentials` by improving `Users` report
- Bump `PSWriteHTML` dependency for better HTML output

```powershell
Get-WinADPasswordPolicy | Format-Table

Invoke-ADEssentials -Type Users,PasswordPolicies -Verbose -FilePath $PSScriptRoot\Reports\UsersAndPasswordPolicies.html -Online
```

#### 0.0.160 - 2023.05.24
- Improves OperatingSystemVersion in multiple report by updating PSSharedGoods

#### 0.0.159 - 2023.05.16
- Improve `Get-WinADACLForest` by adding ability to export directly to Excel

#### 0.0.158 - 2023.05.10
- Improve `Laps` report in Invoke-ADEssentials

#### 0.0.157
- Improve `Users` report in Invoke-ADEssentials
- Improve `Get-WinADUser`

#### 0.0.156
- Improve `Laps` report in Invoke-ADEssentials
- Improve `LapsACL` report in Invoke-ADEssentials
- Improve `Computers` report in Invoke-ADEssentials
- Improve `Users` report in Invoke-ADessentials

#### 0.0.154 - 2023.04.20
- Improve `Laps` report in Invoke-ADEssentials
- Improve `LapsACL` report in Invoke-ADEssentials
- Improve `Computers` report in Invoke-ADEssentials
- Improve `Users` report in Invoke-ADessentials

#### 0.0.154 - 2023.03.29
- Improve `Laps` report in Invoke-ADEssentials
- Improve `LapsACL` report in Invoke-ADEssentials
- Improve `Computers` report in Invoke-ADEssentials

#### 0.0.153 - 2023.03.28
- Improve `Laps` report in Invoke-ADEssentials

#### 0.0.152 - 2023.03.27
- Fix AccountTrustedForDelegation
- Add `AccountDelegation` report to Invoke-ADEssentials
- Improve `Laps` report in Invoke-ADEssentials with some charts

#### 0.0.151 - 2023.01.10
- Fixes `Add-ADACL` in some conditions would fail to add ACLs
- Improve `Set-ADACL` to return Warnings and Errors as part of the final object (used in )
- Add `Force` to `New-ADACLObject` to reset cache (used in DelegationModel)
- Add `ObjectType` and `InheritedObjectType` to have argument completers for `New-ADACLObject`
- Added temporary workaround for Remove-ADACL for ProtectedFromDeletion

#### 0.0.149
- Improves Invoke-ADEssentials with `SplitReports` switch
- Improves Invoke-ADEssentials Users and Computers report by adding conditional formatting
- Improves Invoke-ADEssentials Users report - it was running unnsecary queries
- Add `Get-WinADGroups` function
- Add `Groups` report to Invoke-ADEssentials
- Small improvement for `Get-WinADObject` with check for empty Identity
- Improve performance of `Get-WinADUsers`
- General ACL Improvements *Work in progress*
  - Improve `Add-ADACL` function by allowing more control
  - Improve `Get-ADACL` function to act properly in edge cases
  - Add `Set-ADACLInheritance` function
  - Add `Enable-ADACLInheritance` and `Disable-ADACLInheritance` functions which use `Set-ADACLInheritance`
  - Added `New-ADACLObject` and `Export-ADACLObject`, for use within `Set-ADACL` *Work in progress*
  - Added `Set-ADACL` function which uses `Remove-ADACL` and `Add-ADACL` to allow more control *Work in progress*
  - Improve `Remove-ADACL` function by allowing more control *Work in progress*

#### 0.0.148 - 2022.08.07
- Fixes `Get-WinADDFSHealth` IsPDC

#### 0.0.147 - 2022.08.06
- Added `Show-WinADDNSRecords` command.
- Improved `Show-WinADGroupMember` by adding SkipDiagram option if all you care about is the data
- Improved `Show-WinADGroupMemberOf` by adding SkipDiagram option if all you care about is the data
- Improved `Show-WinADGroupCritical` by adding SkipDiagram option if all you care about is the data
- Improved some documentation for commands above

#### 0.0.146 - 2022.07.26
- Improved `Get-WinADGroupMember`
- Improved `Show-WinADGroupMember` to show tab even if the group is empty
- Added `Show-WinADGroupCritical` to show critical group members in an easy way
- Improved `Get-WinDNSRecords` - renamed some properties to take less space in the reports, renamed RecordType
- Added `Get-WinDNSIPAddresses`

#### 0.0.145 - 2022.07.25
- Improved `Get-WinDNSRecords` by adding `ListTimestamps`

#### 0.0.144 - 2022.07.24
- Improved error handling `Get-WinDNSRecords`

#### 0.0.143 - 2022.07.22
- Added `Get-WinDNSRecords`

#### 0.0.142 - 2022.07.20
- Added `Test-WinADVulnerableSchemaClass` mostly for Testimo usage

#### 0.0.141 - 2022.06.11
- Fixes Cannot index into a null array [#11](https://github.com/EvotecIT/ADEssentials/issues/11)
- Fixes `Get-WinADGroupMember` function doesn't handle special characters in group name [#26](https://github.com/EvotecIT/ADEssentials/issues/26)
- Add support for `GroupManagedServiceAccount` and `ManagedServiceAccount` in `Get-WinADObject` [#27](https://github.com/EvotecIT/ADEssentials/issues/27)
- Fixes `Get-WinADPrivilegedObjects` incorrectly identifying group as orphaned [#28](https://github.com/EvotecIT/ADEssentials/issues/28)

#### 0.0.140 - 2022.02.24
- Added `Show-WinADUserSecurity` - WIP (not usable)

#### 0.0.139 - 2022.01.25
- Added `Show-WinADSites` - WIP (not usable)
- Added `Show-WinADOrganization` - WIP (not usable)
#### 0.0.138 - 2021.11.30
- Improved `Get-WinADDuplicateSPN`
- Fixes to PSD1
#### 0.0.137 - 2021.11.28
- Added `Get-WinADDuplicateSPN` which Detects and lists duplicate Service Principal Names (SPNs) in the Active Directory Domain.
#### 0.0.136 - 2021.11.26
- Added `ForestACLOwners` report to Invoke-ADEssentials
- Added `Set-WinADForestACLOwner` to auto-fix ownership of ADForest ACLs
- Improvements `Get-ADACLOwner` to better filtering
- Improvements `Get-WinADACLForest` to better filtering
#### 0.0.135 - 2021.10.24
- Added `Get-WinADProtocol`
#### 0.0.134 - 2021.10.17
- Improved `Get-WinADACLForest`
#### 0.0.133 - 2021.10.10
- Improved `Get-WinADACLForest` by adding SearchBase parameter
#### 0.0.132 - 2021.10.09
- Improved `Get-ADACL`
#### 0.0.131 - 2021.10.09
- Improved `Get-WinADForestControllerInformation` - fixes [Limit Resolve-DnsName results to Answer section #18](https://github.com/EvotecIT/ADEssentials/pull/18/files) - tnx rmbolger
- Improved `Show-WinADGroupMember/Show-WinADGroupMemberOf` - in some where Name would be identical wrong connections would be made
- Improved `Get-WinADGroupMember/Get-WinADGroupMemberOf` - added GroupParentDN to better graph the tree
- Improved `Get-ADACL/Add-ADACL/Remove-ADACL/Get-ADACLOwner/Get-WinADACLForest` - worked out different method - still work to do
- Added `New-ADSite` - tnx guzzd - [Added the ability to copy ACL from one OU to another with one command](https://github.com/EvotecIT/ADEssentials/pull/15/files)
- Added `Copy-ADOUSecurity` - tnx guzzd - [Added the ability to copy ACL from one OU to another with one command](https://github.com/EvotecIT/ADEssentials/pull/15/files)
#### 0.0.130 - 2021.05.30
- 📦 Added `Get-WinADComputerACLLAPS`
- ℹ Improved `Invoke-ADEssentials`
#### 0.0.129 - 2021.05.28
- ℹ Improved `Get-ADACL` with Principal parameter
#### 0.0.128 - 2021.05.27
- ℹ Improved `Get-WinADUsers`
- ℹ Improved `Get-WinADComputers`
- 📦 Added `Get-WinADDHCP`
- ℹ Improved `Invoke-ADEssentials`
#### 0.0.128 (prerelease Alpha01) - 2021.05.20
- 📦 Added `Get-WinADUsers`
- 📦 Added `Get-WinADComputers`
- 📦 Added `Get-WinADServiceAccount`
- 📦 Added `Invoke-ADEssentials`
- ℹ Improved `Show-WinADGroupMember` to show NETBIOS name in the tabs to distinguish between two domains
#### 0.0.127 - 2021.04.21
- ℹ Improved `Get-WinADBitlockerLapsSummary` moved some fields around
#### 0.0.125 - 2021.04.21
- 🐛 Improved `Get-WinADDelegatedAccounts`
#### 0.0.125 - 2021.04.21
- ☑ Added `Get-WinADDelegatedAccounts`
#### 0.0.124 - 2021.03.23
- ☑ Added `Get-DNSServerIP` - adds ability to read DNS server on given computer/server for static IP - may change in future
- ☑ Added `Set-DNSServerIP` - adds ability to replace DNS server on given computer/server for static IP - may change in future
- ☑ Improved `Get-WinADForestSubnet` to skip IPV6 verification as there is no code behind it
- ☑ Improved `Get-WinADobject` - adds properties property where one can specify `LastLogonDate`, `PasswordLastSet`, `AccountExpirationDate`
#### 0.0.123 - 2021.03.02
- ☑ Improved `Get-WinADForestSites`
#### 0.0.122 - 2021.02.25
- ☑ Improved `Get-WinADForestSites`
- ☑ Added `Get-WinADForestSubnet`
#### 0.0.121 - 2021.02.25
- ☑ Improved `Get-WinADForestSites`
#### 0.0.120 - 2021.02.24
- ☑ Improved `Get-WinADForestControllerInformation`
#### 0.0.119 - 2021.02.22
- ☑ Improved `Test-LDAP`
#### 0.0.118 - 2021.02.22
- ☑ Improved `Test-LDAP`
#### 0.0.117 - 2021.02.19
- ☑ Improved `Test-LDAP`
#### 0.0.116 - 2021.02.18
- ☑ Improved `Get-WinADACLForest`
- ☑ Improved `Test-LDAP`
#### 0.0.115 - 2021.02.17
- ☑ Improved `Test-LDAP`
#### 0.0.114 - 2021.02.17
- ☑ Improved `Get-ADACL`
- ☑ Improved `Get-ADACLOwner`
- ☑ Added `Get-WinADACLForest`
#### 0.0.113 - 2021.02.17
- ☑ Improved `Get-WinADACLConfiguration`
- ☑ Added `Repair-WinADACLConfigurationOwner`
#### 0.0.112 - 2021.02.05
- ☑ Improved `Get-WinADACLConfiguration`
#### 0.0.111 - 2021.02.05
- ☑ Added `Get-WinADACLConfiguration`
#### 0.0.110 - 2021.02.03
- ☑ Improved/fixed `Get-WinADPrivilegedObjects`
#### 0.0.109 - 2021.02.01
- ☑ Improved `Remove-WinADDuplicateObject`
#### 0.0.108 - 2021.01.27
- ☑ Improved `Get-WinADForestControllerInformation`
#### 0.0.107 - 2021.01.21
- ☑ Improved `Get-WinADForestControllerInformation`
#### 0.0.106 - 2021.01.21
- ☑ Improved `Get-WinADForestControllerInformation`
- ☑ Improved `Repair-WinADForestControllerInformation`
#### 0.0.105 - 2021.01.20
- ☑ Added `Get-WinADForestControllerInformation`
- ☑ Added `Repair-WinADForestControllerInformation`
#### 0.0.104 - 2021.01.19
- ☑ Compatible with **PowerShell 5.1** and **7.1** and **7.2** (Windows only)
- ☑ Removed dependency on **GroupPolicy** module
- ☑ Removed `Get-WinADGPOMissingPermissions` -> Please use [GPOZaurr](https://github.com/EvotecIT/GPOZaurr) to deal with GPOs
  - ☑ `Invoke-GPOZaurr -Type GPOPermissions` provides better solution
- ☑ Removed `Get-WinADGPOSysvolFolders` -> Please use [GPOZaurr](https://github.com/EvotecIT/GPOZaurr) to deal with GPOs
  - ☑ `Get-GPOZaurrBroken` or `Invoke-GPOZaurr -Type GPOBroken` provides better solution
- ☑ Improved `Get-WinADFSHealth` to remove GroupPolicy module
- ☑ Improved `Test-ADSiteLinks`
#### 0.0.103 - 3.12.2020
- ☑ Improve error handling `Remove-ADACL`
#### 0.0.102 - 8.11.2020
- ☑ Updated libraries
- ☑ 0.0.100 was removed from PSGallery due to PSGallery issues
#### 0.0.100 - 29.10.2020
- ☑ `Get-WinADForestObjectsConflict` removed
- ☑ `Get-WinADForestObjectsConflict` added as alias to `Get-WinADDuplicateObject`
- ☑ Improved `Get-WinADDuplicateObject`
- ☑ `Get-WinADDuplicateObject` expanded with parameters `NoPostProcessing`, `Extended`, `ExcludeObjectClass`, `IncludeObjectClass`
#### 0.0.99 - 14.10.2020
- ☑ Fix for `Show-WinADTrust`
#### 0.0.98 - 05.10.2020
- ☑ Added parameters `SelfOnly` / `AdditionalStatistics` to `Get-WinADGroupMember`
  - [ ] This shows maximum level of nesting on Self object, nested groups count, nested security groups count, nested distribution groups copunt
#### 0.0.97 - 30.09.2020
- ☑ Update to `Repair-WinADEmailAddress` treating proxy addresses case sensitive
  - ☑ Replacement for Sort-Object -Unique which removes primary SMTP: if it's duplicate of smtp:
#### 0.0.96 - 30.09.2020
- ☑ Update to `Repair-WinADEmailAddress`
  - ☑ Fixes Primary Proxy Email if it's missing but not requested by user
#### 0.0.95 - 30.09.2020
- ☑ Update to `Repair-WinADEmailAddress`
  - ☑ Added ability to add secondary email addresses
  - ☑ Added ability to not change primary email address
#### 0.0.94 - 28.09.2020
- ☑ `Show-WinADGroupMember` support for input from `Get-WinADGroupMember`
#### 0.0.93 - 23.09.2020
- ☑ Added detection of indirect circular to `Get-WinADGroupMember` to prevent infinite loops
- ☑ Renamed Circular to DirectCircular to accomodate IndirectCircular in `Get-WinADGroupMember`
- ☑ Updated Show-WinADGroupMember to better visualize circular membership
#### 0.0.92 - 23.09.2020
- ☑ Some visual improvements to `Show-WinADGroupMember`/`Show-WinADGroupMemberOf`
- ☑ Added `IncludeObjectTypeName`,`ExcludeObjectTypeName`,`IncludeInheritedObjectTypeName`,`ExcludeInheritedObjectTypeName` to `Get-ADACL`
- ☑ Added `ADRightsAsArray` to `Get-ADACL`
- ☑ Added `AccessControlType` to `Get-ADACL`
- ☑ Improvements to `Get-WinADObject` and all cmdlets that rely on it
- ☑ Improvements to `Get-ADACL`
- ☑ Improvements to PSD1
#### 0.0.91 - 14.09.2020
- ☑ Added ability to define own conditions/rules to `Show-WinADGroupMember`,`Show-WinADGroupMemberOf` using `PSWriteHTML` options
#### 0.0.90 - 13.09.2020
- ☑ Updates to `Get-WinADTrust` for better verbose
- ☑ Updates to `Show-WinADTrust` visual parts
- ☑ Updates to `Get-WinADObject` for better verbose
#### 0.0.89 - 13.09.2020
- ☑ Updates to `Get-WinADTrust` (**Work in progress**)
- ☑ Updates to `Show-WinADTrust` (**Work in progress**)
#### 0.0.88 - 12.09.2020
- ☑ Updates to `Get-WinADTrust` (**Work in progress**)
- ☑ Updates to `Get-ADObject`
- ☑ Updates to `Show-WinADTrust` (**Work in progress**)
#### 0.0.87 - 12.09.2020
- ☑ Rewritten `Get-WinADTrust` to use ADSI instead of ActiveDirectory module (**Work in progress**)
  - ☑ Added objects testing, trust testing, included suffix status
  - ☑ Added recursive switch
- ☑ Renamed old `Get-WinADTrust` to `Get-WinADTrustLegacy` just in case for now
- ☑ Added `Show-WinADTrust` (**Work in progress**)
#### 0.0.86 - 9.09.2020
- ☑ Some improvements to `Get-WinADDFSHealth`
#### 0.0.85 - 9.09.2020
- ☑ Some improvements to `Get-WinADTrust`
- ☑ Some improvements to `Get-WinADDFSHealth` - added `SkipGPO`, `SkipAutodection`
- ☑ Added `Get-WinADForest` adsi based
- ☑ Added `Get-WinADDomain` adsi based
- ☑ Added HideHTML switch for Get-WinADGroupMember
- ☑ Added HideHTML switch for Get-WinADGroupMemberOf
#### 0.0.84 - 2.09.2020 - [Visually display Active Directory Nested Group Membership using PowerShell](https://evotec.xyz/visually-display-active-directory-nested-group-membership-using-powershell/)
- ☑ `ActiveDirectory`/`GroupPolicy` are now optional to not block module from working without RSAT (for commands that work without it)
- ☑ Made `Show-WinADGroupMember`, `Show-WinADGroupMemberOf` work offline by default
#### 0.0.83 - 2.09.2020
- ☑ Updated `Show-WinADGroupMemberOf` removed `Hide` parameters as there is nothing to hide
#### 0.0.82 - 2.09.2020
- ☑ Updated `Show-WinADGroupMember` renaming parameters from `Remove` to `Hide` which is original intention to hide them on diagram
- ☑ Updated `Show-WinADGroupMemberOf` renaming parameters from `Remove` to `Hide` which is original intention to hide them on diagram
#### 0.0.81 - 2.09.2020
- Improvements
#### 0.0.80 - 1.09.2020
- Improvements
#### 0.0.79 - 1.09.2020
- Improvements
#### 0.0.78 - 1.09.2020
- Improvements
#### 0.0.77 - 1.09.2020
- ☑ Performance improvements to `Get-WinADObject` - new switch added `IncludeGroupMembership`
- ☑ Small fixes to `Get-WinADObjectMember`
- ☑ Small fixes to `Get-WinADGroupMember`
#### 0.0.76 - 1.09.2020
- ☑ Improvements in verbose for `Get-WinADObjectMember` to track down issues
#### 0.0.75 - 1.09.2020
- ☑ Improvements `Show-WinADGroupMember`
- ☑ Improvements `Get-WinADObjectMember`
- ☑ Improvements `Show-WinADObjectMember`
#### 0.0.74 - 31.08.2020
- ☑ Improvements to `Show-WinADGroupMember` (alias `Show-ADGroupMember`)
- ☑ Added `Get-WinADObjectMember`
- ☑ Added `Show-WinADObjectMember`
#### 0.0.73 - 31.08.2020
- ☑ Improvements to `Show-WinADGroupMember` (alias `Show-ADGroupMember`)
#### 0.0.72 - 31.08.2020
- ☑ Improvements to `Show-WinADGroupMember` (alias `Show-ADGroupMember`)
#### 0.0.71 - 30.08.2020
- ☑ Improvements to `Get-WinADObject`
#### 0.0.70 - 29.08.2020
- ☑ Improvements to `Get-WinADObject`
- ☑ Improvements to `Get-WinADGroupMember`
#### 0.0.69 - 28.08.2020
- ☑ Improvements to `Get-WinADGroupMember`
#### 0.0.68 - 28.08.2020
- ☑ Improvements to `Get-WinADGroupMember`
#### 0.0.67 - 26.08.2020
- ☑ Added experimental `Get-WinADObject`
- ☑ Replaced experimental `Get-WinADGroupMember`
#### 0.0.66 - 14.08.2020
- ☑ Fixes to `Get-WinADProxyAddresses` - detects broken email address (for example one with ",")
- ☑ Rewritten to `Repair-WinADEmailAddress` - was getting too complicated
#### 0.0.65 - 23.07.2020
- ☑ Fixed bug `Get-WinADSharePermission`
#### 0.0.64 - 23.07.2020
- ☑ Improvements to `Get-WinADSharePermission`
#### 0.0.63 - 22.07.2020
- ☑ Improvements to `Get-WinADGroupMember`
- ☑ Signed module
#### 0.0.62 - 6.07.2020
- ☑ Improvements to `Get-WinADGroupMember`
#### 0.0.61 - 6.07.2020
- ☑ Improvements to `Get-WinADGroupMember`
#### 0.0.61 - 3.07.2020
- ☑ Improvements to `Get-WinADGroupMember`
#### 0.0.60 - 2.07.2020
- ☑ Fix for `Get-WinADGroupMember`
#### 0.0.59 - 2.07.2020
- ☑ Added `Get-WinADDuplicateObject`
- ☑ Added `Remove-WinADDuplicateObject` - doesn't solve some issues, but should help with most. Use with `WhatIf`
- ☑ Added `Get-WinADGroupMember`
#### 0.0.58 - 24.06.2020
- ☑ Added `Get-WinADWellKnownFolders`
#### 0.0.57 - 17.05.2020
- ☑ Improved `Remove-WinADSharePermission` (`foreach-object` to `foreach`)
- ☑ Improved `Get-WinADGPOSysvolFolders` error handling
#### 0.0.56 - 15.05.2020
- ☑ Improved `Get-ADACLOwner` error handling
#### 0.0.55 - 12.05.2020
- ☑ Improved/Renamed experimental `Get-WinADShare` to `Get-WinADSharePermission` - work in progress
- ☑ Improved/Renamed experimantal `Set-WinADShare` to `Get-WinADSharePermission` - work in progress
#### 0.0.54 - 10.05.2020
- ☑ Small update to `Remove-ADACL`
#### 0.0.53 - 9.05.2020
- ☑ Fix for `Get-WinADTrusts`
- ☑ Added experimantal `Get-ADACLOwner` - work in progress
- ☑ Added experimental `Get-WinADShare` - work in progress
- ☑ Added experimantal (not ready) `Set-WinADShare`- work in progress
#### 0.0.51 - 28.04.2020
- ☑ Disabled WhatIf for `New-PSDrive` (for use within `New-ADForestDrives`)
- ☑ Added `Get-ADACLOwner`
#### 0.0.50 - 23.04.2020
- ☑ Fix for bug where some functions from other modules were not merged correctly (`Copy-Dictionary`) causing problems if `PSSharedGoods` was not installed
#### 0.0.48 - 12.04.2020
- ☑ Improvements
#### 0.0.47 - 12.04.2020
- ☑ Added `Set-ADACLOwner` - experimental support
#### 0.0.46 - 11.04.2020
- ☑ Added `Get-WinADForestSites`
- ☑ Added `Get-WinADForestOptionalFeatures`
- ☑ Added `Get-WinADForestSchemaProperties`
- ☑ Renamed `Get-WinADPriviligedObjects` to `Get-WinADPrivilegedObjects` - tnx Subnet192 [#5](https://github.com/EvotecIT/ADEssentials/pull/5)
- ☑ Fix to `Get-WinADPrivilegedObjects` - tnx Subnet192 [#5](https://github.com/EvotecIT/ADEssentials/pull/5)
- ☑ Improvement `Get-WinADDFSHealth` for DFS edge cases (may be subject to language issue)
- ☑ Improvement of all commands for detecting forest/domain/dcs
- ☑ Added `Remove-ADACL` - experimantal support
- ☑ Added `Add-ADACL` - experimantal support
#### 0.0.45 - 13.03.2020
- ☑ Improvement to commands to support different Forests
#### 0.0.44 - 3.03.2020
- ☑ Improvement to Get-ADACL
#### 0.0.43 - 3.03.2020
- ☑ Improvement to Get-ADACL
#### 0.0.42 - 27.02.2020
- ☑ Fixes for Get-ADACL
- ☑ Fixes for Get-WinADProxyAddresses
- Not really useful yet
  - ☑ Added Get-WinADUserPrincipalName
  - ☑ Added Rename-WinADUserPrincipalName
#### 0.0.41 - 20.02.2020
- ☑ Get-WinADGPOMissingPermissions updates to support SID instead (should work multi-language)
#### 0.0.40 - 19.02.2020
- ☑ Updates to Get-WinADGPOMissingPermissions
#### 0.0.39 - 19.02.2020
- ☑ Fix for Get-WinADGPOMissingPermissions for multiple domains
#### 0.0.38 - 16.02.2020
- Updates to PSSharedGoods code/PSEventViewer
#### 0.0.37 - 12.02.2020
- Added ExtendedForestInformation input to provide a way for Testimo to use
- Enhancements to Get-ADACL
#### 0.0.36 - 26.01.2020
- Fixes for Get-ADACL (via PSSharedGoods integrated)
#### 0.0.35 - 23.01.2020
- Fixes for Get-ADACL
#### 0.0.34 - 19.01.2020
- Small fixes
#### 0.0.33 - 19.01.2020
- ☑ Added Get-WinADLdapBindingsSummary
#### 0.0.32 - 19.01.2020
- Small fixes
#### 0.0.30 - 19.01.2020
- ☑ Reworked most of the code to support forest/including/excluding domains and including/excluding DC's - needs testing
- ☑ Added Get-ADACL
- ☑ Added Get-WinADTrusts
- ☑ Added Set-WinADDiagnostics
#### 0.0.29 - 04.01.2020
- ☑ Added Get-WinADTombstoneLifetime / Set-WinADTombstoneLifetime
#### 0.0.28 - 26.12.2019
- ☑ Added Get-WinADForestRoles (copied from PSWinDocumentation.AD)
#### 0.0.27 - 16.12.2019
- ☑ Fixes for Get-WINADFSHealth
#### 0.0.26 - 18.11.2019
- ☑ Added Get-WinADForestObjectsConflict to find conflicting objects
#### 0.0.25 - 15.11.2019
- ☑ Added two new commands for fixing and reading Proxy Addresses
#### 0.0.23 - 11.11.2019
- ☑ Removed PSSharedGoods as a dependency for modules published to releases and PowerShellGallery
  - [ ] It's still part of development build. Releases are now merged with PSPublishModule functionality
- ☑ Added PSEventViewer as a dependency as it was missing
- ☑ Fix for Get-WinADDFSHealth.ps1 SYSVol Count (tnx brianmccarty)
#### 0.0.22 - 28.10.2019
- ☑ Added some functions
#### 0.0.21 - 10.10.2019
- ☑ Fix for Get-WinADLastBackup
#### 0.0.7 - 3.08.2019
- ☑ Added Get-WinADLastBackup