function Get-WinADPasswordPolicy {
    <#
    .SYNOPSIS
    Get password policies from Active Directory include fine grained password policies

    .DESCRIPTION
    Get password policies from Active Directory include fine grained password policies
    Please keep in mind that reading fine grained password policies requires extended rights
    It's not available to standard users

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER ExcludeDomains
    Exclude domain from search, by default whole forest is scanned

    .PARAMETER IncludeDomains
    Include only specific domains, by default whole forest is scanned

    .PARAMETER NoSorting
    Do not sort output by Precedence

    .PARAMETER ReturnHashtable
    Return hashtable instead of array. Useful for internal processing such as Get-WinADUsers

    .EXAMPLE
    Get-WinADPasswordPolicy | Format-Table

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,

        [switch] $NoSorting,
        [parameter(DontShow)][switch] $ReturnHashtable
    )
    $FineGrainedPolicy = [ordered] @{}

    $ForestInformation = Get-WinADForestDetails -Extended -Forest $Forest -ExcludeDomains $ExcludeDomains -IncludeDomains $IncludeDomains
    $AllPasswordPolicies = foreach ($Domain in $ForestInformation.Domains) {
        $Policies = @(
            Get-ADDefaultDomainPasswordPolicy -Server $ForestInformation['QueryServers'][$Domain].Hostname[0]
            Get-ADFineGrainedPasswordPolicy -Filter * -Server $ForestInformation['QueryServers'][$Domain].Hostname[0]
        )
        foreach ($Policy in $Policies) {
            $FineGrainedPolicy[$Policy.DistinguishedName] = [PSCustomObject] @{
                Name                        = if ($Policy.ObjectClass -contains 'domainDNS') { 'Default' } else { $Policy.Name }
                DomainName                  = $Domain
                Type                        = if ($Policy.ObjectClass -contains 'domainDNS') { 'Default Password Policy' } else { 'Fine Grained Password Policy' }
                Precedence                  = if ($Policy.Precedence) { $Policy.Precedence } else { 99999 }
                MinPasswordLength           = $Policy.MinPasswordLength
                MaxPasswordAge              = $Policy.MaxPasswordAge
                MinPasswordAge              = $Policy.MinPasswordAge
                PasswordHistoryCount        = $Policy.PasswordHistoryCount
                ComplexityEnabled           = $Policy.ComplexityEnabled
                ReversibleEncryptionEnabled = $Policy.ReversibleEncryptionEnabled
                LockoutDuration             = $Policy.LockoutDuration
                LockoutObservationWindow    = $Policy.LockoutObservationWindow
                LockoutThreshold            = $Policy.LockoutThreshold
                AppliesTo                   = $Policy.AppliesTo
                AppliesToCount              = if ($Policy.AppliesTo) { $Policy.AppliesTo.Count } else { 0 }
                AppliesToName               = if ($Policy.AppliesTo) {
                    foreach ($DN in $Policy.AppliesTo) {
                        ConvertFrom-DistinguishedName -DistinguishedName $DN -ToLastName
                    }
                } else {
                    $null
                }
                DistinguishedName           = $Policy.DistinguishedName
            }
            if ($Policy.ObjectClass -contains 'domainDNS') {
                $FineGrainedPolicy[$Domain] = $FineGrainedPolicy[$Policy.DistinguishedName]
                $FineGrainedPolicy[$Domain]
            } else {
                $FineGrainedPolicy[$Policy.DistinguishedName] = $FineGrainedPolicy[$Policy.DistinguishedName]
                $FineGrainedPolicy[$Policy.DistinguishedName]
            }
        }
    }
    if ($ReturnHashtable) {
        $FineGrainedPolicy
    } else {
        if (-not $NoSorting) {
            $AllPasswordPolicies | Sort-Object -Property Precedence
        } else {
            $AllPasswordPolicies
        }
    }
}