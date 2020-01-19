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

Force and AllowClobber aren't really nessecary but they do skip errors in case some appear.

## And to update

```powershell
Update-Module -Name ADEssentials
```

That's it. Whenever there's new version you simply run the command and you can enjoy it. Remember, that you may need to close, reopen PowerShell session if you have already used module before updating it.

**The important thing** is if something works for you on production, keep using it till you test the new version on a test computer. I do changes that may not be big, but big enough that auto-update will break your code. For example, small rename to a parameter and your code stops working! Be responsible!

## Changelog

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
  - [x] Removed PSSharedGoods as dependency for modules published to releases and PowerShellGallery
    - [ ] It's still part of development build. Releases are now merged with PSPublishModule functionality
  - [x] Added PSEventViewer as depenedency as it was missing
  - [x] Fix for Get-WinADDFSHealth.ps1 SYSVol Count (tnx brianmccarty)
- 0.0.22 - 28.10.2019
  - [x] Added some functions
- 0.0.21 - 10.10.2019
  - [x] Fix for Get-WinADLastBackup
- 0.0.7 - 3.08.2019
  - [x] Added Get-WinADLastBackup
