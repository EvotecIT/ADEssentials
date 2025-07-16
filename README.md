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
  <a href="https://evo.yt/discord"><img src="https://img.shields.io/discord/508328927853281280?style=flat-square&label=discord%20chat"></a>
</p>

# ADEssentials

**ADEssentials** PowerShell module contains a set of commands that are useful for day to day activities when working with Active Directory.
It's also an essential part of [GPOZaurr](https://github.com/EvotecIT/GPOZaurr) and [Testimo](https://github.com/EvotecIT/Testimo).

Following links contain description of some of the features possible with this module

- [Finding duplicate DNS entries using PowerShell](https://evotec.xyz/finding-duplicate-dns-entries-using-powershell/)
- [Finding duplicate DNS records by IP Address using PowerShell](https://evotec.xyz/finding-duplicate-dns-records-by-ip-adress-using-powershell/)
- [Finding duplicate SPN with PowerShell](https://evotec.xyz/finding-duplicate-spn-with-powershell/)
- [Monitoring LDAPS connectivity/certificate with PowerShell](https://evotec.xyz/monitoring-ldaps-connectivity-certificate-with-powershell/)
- [Visually display Active Directory Nested Group Membership using PowerShell](https://evotec.xyz/visually-display-active-directory-nested-group-membership-using-powershell/)
- [Visually display Active Directory Trusts using PowerShell](https://evotec.xyz/visually-display-active-directory-trusts-using-powershell/)
- [Active Directory DFS Health Check with PowerShell](https://evotec.xyz/active-directory-dfs-health-check-with-powershell/)
- [Four commands to help you track down insecure LDAP Bindings before March 2020](https://evotec.xyz/four-commands-to-help-you-track-down-insecure-ldap-bindings-before-march-2020/)

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