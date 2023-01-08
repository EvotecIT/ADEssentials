﻿Clear-Host
Import-Module $PSScriptRoot\..\..\ADEssentials.psd1 -Force

$Splat = @{
    Resolve           = $True
    Bundle            = $true
    ADObject          = 'OU=Accounts02,OU=Tier2,DC=ad,DC=evotec,DC=xyz'
    AccessControlType = 'Allow'
    Principal         = 'mmmm@ad.evotec.pl'
    #Principal         = 'przemyslaw.klys'
}
# $ACL1 = Get-ADACL @Splat
# $ACL1 | Format-Table

$Principal = 'mmmm@ad.evotec.pl'
$ACL = Get-ADACL -ADObject 'OU=Accounts02,OU=Tier2,DC=ad,DC=evotec,DC=xyz' -Bundle #-Verbose:$VerbosePreference
if ($ACL) {
    Remove-ADACL -ACL $ACL -Principal $Principal -AccessControlType Allow -Verbose -WhatIf
}