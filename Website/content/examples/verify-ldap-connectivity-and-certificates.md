---
title: "Verify LDAP connectivity and certificates"
description: "Test LDAP endpoints and certificate validation from a PowerShell-based AD health workflow."
layout: docs
---

This example is useful when you need a quick LDAP verification pass before deeper Active Directory troubleshooting.

It comes from the source example at `Examples/Example.06-TestLDAPPorts.ps1`.

## When to use this pattern

- You need to confirm LDAP connectivity to domain controllers.
- You want to validate certificate-backed LDAP communication.
- You are checking whether a directory issue is network, certificate, or service related.

## Example

```powershell
Import-Module .\ADEssentials.psd1 -Force

Test-LDAP -IncludeDomainControllers 'dc01.corp.example.com' -Identity "krbtgt" -Verbose | Format-List *
Test-LDAP -ComputerName 'corp.example.com' -VerifyCertificate -Verbose | Format-Table
Test-LDAP -VerifyCertificate -Verbose -IncludeDomains 'corp.example.com' | Format-Table
```

## What this demonstrates

- testing specific domain controllers directly
- validating LDAP over certificate-backed channels
- comparing narrow and broad validation runs from the same command family

## Source

- [Example.06-TestLDAPPorts.ps1](https://github.com/EvotecIT/ADEssentials/blob/master/Examples/Example.06-TestLDAPPorts.ps1)
