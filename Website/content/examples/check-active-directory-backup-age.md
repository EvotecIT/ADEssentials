---
title: "Check Active Directory backup age"
description: "Use ADEssentials to review the last known Active Directory backup state across a forest or selected domains."
layout: docs
---

This example is useful when you need a quick recovery-readiness check before broader Active Directory troubleshooting or change work.

It comes from the source example at `Examples/Example.06-CheckLastBackup.ps1`.

## When to use this pattern

- You need to confirm whether Active Directory backups are recent enough.
- You want a forest-wide check before planning changes.
- You need a narrower check for one or more selected domains.

## Example

```powershell
Import-Module .\ADEssentials.psd1 -Force

# Check the whole forest
$LastBackup = Get-WinADLastBackup
$LastBackup | Format-Table -AutoSize

# Check selected domains
$LastBackup = Get-WinADLastBackup -Domain 'ad.evotec.pl', 'ad.evotec.xyz'
$LastBackup | Format-Table -AutoSize
```

## What this demonstrates

- checking recovery readiness before deeper work
- running both broad and targeted domain checks
- producing a compact table that can be shared with the directory team

## Source

- [Example.06-CheckLastBackup.ps1](https://github.com/EvotecIT/ADEssentials/blob/master/Examples/Example.06-CheckLastBackup.ps1)
