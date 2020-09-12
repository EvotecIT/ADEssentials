<p align="center">
  <a href="https://www.powershellgallery.com/packages/ADEssentials"><img src="https://img.shields.io/powershellgallery/v/ADEssentials.svg"></a>
  <a href="https://www.powershellgallery.com/packages/ADEssentials"><img src="https://img.shields.io/powershellgallery/vpre/ADEssentials.svg?label=powershell%20gallery%20preview&colorB=yellow"></a>
  <a href="https://github.com/EvotecIT/ADEssentials"><img src="https://img.shields.io/github/license/EvotecIT/ADEssentials.svg"></a>
</p>

<p align="center">
  <a href="https://www.powershellgallery.com/packages/ADEssentials"><img src="https://img.shields.io/powershellgallery/p/ADEssentials.svg"></a>
  <a href="https://github.com/EvotecIT/ADEssentials"><img src="https://img.shields.io/github/languages/top/evotecit/ADEssentials.svg"></a>
  <a href="https://github.com/EvotecIT/ADEssentials"><img src="https://img.shields.io/github/languages/code-size/evotecit/ADEssentials.svg"></a>
  <a href="https://www.powershellgallery.com/packages/ADEssentials"><img src="https://img.shields.io/powershellgallery/dt/ADEssentials.svg"></a>
</p>

<p align="center">
  <a href="https://twitter.com/PrzemyslawKlys"><img src="https://img.shields.io/twitter/follow/PrzemyslawKlys.svg?label=Twitter%20%40PrzemyslawKlys&style=social"></a>
  <a href="https://evotec.xyz/hub"><img src="https://img.shields.io/badge/Blog-evotec.xyz-2A6496.svg"></a>
  <a href="https://www.linkedin.com/in/pklys"><img src="https://img.shields.io/badge/LinkedIn-pklys-0077B5.svg?logo=LinkedIn"></a>
</p>

# ADEssentials

## To install

```powershell
Install-Module -Name ADEssentials -AllowClobber -Force
```

Force and AllowClobber aren't necessary, but they do skip errors in case some appear.

## And to update

```powershell
Update-Module -Name ADEssentials
```

That's it. Whenever there's a new version, you run the command, and you can enjoy it. Remember that you may need to close, reopen PowerShell session if you have already used module before updating it.

**The essential thing** is if something works for you on production, keep using it till you test the new version on a test computer. I do changes that may not be big, but big enough that auto-update may break your code. For example, small rename to a parameter and your code stops working! Be responsible!

## Changelog

- 0.0.88 - 12.09.2020
  - [x] Updates to `Get-WinADTrust`
  - [x] Updates to `Get-ADObject`
  - [x] Updates to `Show-WinADTrust`
- 0.0.87 - 12.09.2020
  - [x] Rewritten `Get-WinADTrust` to use ADSI instead of ActiveDirectory module (**Work in progress**)
    - [x] Added objects testing, trust testing, included suffix status
    - [x] Added recursive switch
  - [x] Renamed old `Get-WinADTrust` to `Get-WinADTrustLegacy` just in case for now
  - [x] Added `Show-WinADTrust` (**Work in progress**)
- 0.0.86 - 9.09.2020
  - [x] Some improvements to `Get-WinADDFSHealth`
- 0.0.85 - 9.09.2020
  - [x] Some improvements to `Get-WinADTrust`
  - [x] Some improvements to `Get-WinADDFSHealth` - added `SkipGPO`, `SkipAutodection`
  - [x] Added `Get-WinADForest` adsi based
  - [x] Added `Get-WinADDomain` adsi based
  - [x] Added HideHTML switch for Get-WinADGroupMember
  - [x] Added HideHTML switch for Get-WinADGroupMemberOf
- 0.0.84 - 2.09.2020 - [Visually display Active Directory Nested Group Membership using PowerShell](https://evotec.xyz/visually-display-active-directory-nested-group-membership-using-powershell/)
  - [x] `ActiveDirectory`/`GroupPolicy` are now optional to not block module from working without RSAT (for commands that work without it)
  - [x] Made `Show-WinADGroupMember`, `Show-WinADGroupMemberOf` work offline by default
- 0.0.83 - 2.09.2020
  - [x] Updated `Show-WinADGroupMemberOf` removed `Hide` parameters as there is nothing to hide
- 0.0.82 - 2.09.2020
  - [x] Updated `Show-WinADGroupMember` renaming parameters from `Remove` to `Hide` which is original intention to hide them on diagram
  - [x] Updated `Show-WinADGroupMemberOf` renaming parameters from `Remove` to `Hide` which is original intention to hide them on diagram
- 0.0.81 - 2.09.2020
  - Improvements
- 0.0.80 - 1.09.2020
  - Improvements
- 0.0.79 - 1.09.2020
  - Improvements
- 0.0.78 - 1.09.2020
  - Improvements
- 0.0.77 - 1.09.2020
  - [x] Performance improvements to `Get-WinADObject` - new switch added `IncludeGroupMembership`
  - [x] Small fixes to `Get-WinADObjectMember`
  - [x] Small fixes to `Get-WinADGroupMember`
- 0.0.76 - 1.09.2020
  - [x] Improvements in verbose for `Get-WinADObjectMember` to track down issues
- 0.0.75 - 1.09.2020
  - [x] Improvements `Show-WinADGroupMember`
  - [x] Improvements `Get-WinADObjectMember`
  - [x] Improvements `Show-WinADObjectMember`
- 0.0.74 - 31.08.2020
  - [x] Improvements to `Show-WinADGroupMember` (alias `Show-ADGroupMember`)
  - [x] Added `Get-WinADObjectMember`
  - [x] Added `Show-WinADObjectMember`
- 0.0.73 - 31.08.2020
  - [x] Improvements to `Show-WinADGroupMember` (alias `Show-ADGroupMember`)
- 0.0.72 - 31.08.2020
  - [x] Improvements to `Show-WinADGroupMember` (alias `Show-ADGroupMember`)
- 0.0.71 - 30.08.2020
  - [x] Improvements to `Get-WinADObject`
- 0.0.70 - 29.08.2020
  - [x] Improvements to `Get-WinADObject`
  - [x] Improvements to `Get-WinADGroupMember`
- 0.0.69 - 28.08.2020
  - [x] Improvements to `Get-WinADGroupMember`
- 0.0.68 - 28.08.2020
  - [x] Improvements to `Get-WinADGroupMember`
- 0.0.67 - 26.08.2020
  - [x] Added experimental `Get-WinADObject`
  - [x] Replaced experimental `Get-WinADGroupMember`

- 0.0.66 - 14.08.2020
  - [x] Fixes to `Get-WinADProxyAddresses` - detects broken email address (for example one with ",")
  - [x] Rewritten to `Repair-WinADEmailAddress` - was getting too complicated
- 0.0.65 - 23.07.2020
  - [x] Fixed bug `Get-WinADSharePermission`

- 0.0.64 - 23.07.2020
  - [x] Improvements to `Get-WinADSharePermission`

- 0.0.63 - 22.07.2020
  - [x] Improvements to `Get-WinADGroupMember`
  - [x] Signed module
- 0.0.62 - 6.07.2020
  - [x] Improvements to `Get-WinADGroupMember`

- 0.0.61 - 6.07.2020
  - [x] Improvements to `Get-WinADGroupMember`

- 0.0.61 - 3.07.2020
  - [x] Improvements to `Get-WinADGroupMember`

- 0.0.60 - 2.07.2020
  - [x] Fix for `Get-WinADGroupMember`

- 0.0.59 - 2.07.2020
  - [x] Added `Get-WinADDuplicateObject`
  - [x] Added `Remove-WinADDuplicateObject` - doesn't solve some issues, but should help with most. Use with `WhatIf`
  - [x] Added `Get-WinADGroupMember`

- 0.0.58 - 24.06.2020
  - [x] Added `Get-WinADWellKnownFolders`

- 0.0.57 - 17.05.2020
  - [x] Improved `Remove-WinADSharePermission` (`foreach-object` to `foreach`)
  - [x] Improved `Get-WinADGPOSysvolFolders` error handling

- 0.0.56 - 15.05.2020
  - [x] Improved `Get-ADACLOwner` error handling

- 0.0.55 - 12.05.2020
  - [x] Improved/Renamed experimental `Get-WinADShare` to `Get-WinADSharePermission` - work in progress
  - [x] Improved/Renamed experimantal `Set-WinADShare` to `Get-WinADSharePermission` - work in progress

- 0.0.54 - 10.05.2020
  - [x] Small update to `Remove-ADACL`

- 0.0.53 - 9.05.2020
  - [x] Fix for `Get-WinADTrusts`
  - [x] Added experimantal `Get-ADACLOwner` - work in progress
  - [x] Added experimental `Get-WinADShare` - work in progress
  - [x] Added experimantal (not ready) `Set-WinADShare`- work in progress

- 0.0.51 - 28.04.2020
  - [x] Disabled WhatIf for `New-PSDrive` (for use within `New-ADForestDrives`)
  - [x] Added `Get-ADACLOwner`

- 0.0.50 - 23.04.2020
  - [x] Fix for bug where some functions from other modules were not merged correctly (`Copy-Dictionary`) causing problems if `PSSharedGoods` was not installed

- 0.0.48 - 12.04.2020
  - [x] Improvements

- 0.0.47 - 12.04.2020
  - [x] Added `Set-ADACLOwner` - experimental support

- 0.0.46 - 11.04.2020
  - [x] Added `Get-WinADForestSites`
  - [x] Added `Get-WinADForestOptionalFeatures`
  - [x] Added `Get-WinADForestSchemaProperties`
  - [x] Renamed `Get-WinADPriviligedObjects` to `Get-WinADPrivilegedObjects` - tnx Subnet192 [#5](https://github.com/EvotecIT/ADEssentials/pull/5)
  - [x] Fix to `Get-WinADPrivilegedObjects` - tnx Subnet192 [#5](https://github.com/EvotecIT/ADEssentials/pull/5)
  - [x] Improvement `Get-WinADDFSHealth` for DFS edge cases (may be subject to language issue)
  - [x] Improvement of all commands for detecting forest/domain/dcs
  - [x] Added `Remove-ADACL` - experimantal support
  - [x] Added `Add-ADACL` - experimantal support

- 0.0.45 - 13.03.2020
  - [x] Improvement to commands to support different Forests

- 0.0.44 - 3.03.2020
  - [x] Improvement to Get-ADACL

- 0.0.43 - 3.03.2020
  - [x] Improvement to Get-ADACL

- 0.0.42 - 27.02.2020
  - [x] Fixes for Get-ADACL
  - [x] Fixes for Get-WinADProxyAddresses
  - Not really useful yet
    - [x] Added Get-WinADUserPrincipalName
    - [x] Added Rename-WinADUserPrincipalName

- 0.0.41 - 20.02.2020
  - [x] Get-WinADGPOMissingPermissions updates to support SID instead (should work multi-language)

- 0.0.40 - 19.02.2020
  - [x] Updates to Get-WinADGPOMissingPermissions
- 0.0.39 - 19.02.2020
  - [x] Fix for Get-WinADGPOMissingPermissions for multiple domains
- 0.0.38 - 16.02.2020
  - Updates to PSSharedGoods code/PSEventViewer

- 0.0.37 - 12.02.2020
  - Added ExtendedForestInformation input to provide a way for Testimo to use
  - Enhancements to Get-ADACL

- 0.0.36 - 26.01.2020
  - Fixes for Get-ADACL (via PSSharedGoods integrated)

- 0.0.35 - 23.01.2020
  - Fixes for Get-ADACL

- 0.0.34 - 19.01.2020
  - Small fixes
- 0.0.33 - 19.01.2020
  - [x] Added Get-WinADLdapBindingsSummary
- 0.0.32 - 19.01.2020
  - Small fixes

- 0.0.30 - 19.01.2020
  - [x] Reworked most of the code to support forest/including/excluding domains and including/excluding DC's - needs testing
  - [x] Added Get-ADACL
  - [x] Added Get-WinADTrusts
  - [x] Added Set-WinADDiagnostics

- 0.0.29 - 04.01.2020
  - [x] Added Get-WinADTombstoneLifetime / Set-WinADTombstoneLifetime
- 0.0.28 - 26.12.2019
  - [x] Added Get-WinADForestRoles (copied from PSWinDocumentation.AD)
- 0.0.27 - 16.12.2019
  - [x] Fixes for Get-WINADFSHealth
- 0.0.26 - 18.11.2019
  - [x] Added Get-WinADForestObjectsConflict to find conflicting objects
- 0.0.25 - 15.11.2019
  - [x] Added two new commands for fixing and reading Proxy Addresses
- 0.0.23 - 11.11.2019
  - [x] Removed PSSharedGoods as a dependency for modules published to releases and PowerShellGallery
    - [ ] It's still part of development build. Releases are now merged with PSPublishModule functionality
  - [x] Added PSEventViewer as a dependency as it was missing
  - [x] Fix for Get-WinADDFSHealth.ps1 SYSVol Count (tnx brianmccarty)
- 0.0.22 - 28.10.2019
  - [x] Added some functions
- 0.0.21 - 10.10.2019
  - [x] Fix for Get-WinADLastBackup
- 0.0.7 - 3.08.2019
  - [x] Added Get-WinADLastBackup
