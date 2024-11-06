function Repair-WinADBrokenProtectedFromDeletion {
    <#
    .SYNOPSIS
    Repairs Active Directory objects that have broken protection from accidental deletion.

    .DESCRIPTION
    This cmdlet fixes Active Directory objects where the ProtectedFromAccidentalDeletion flag doesn't match the actual ACL settings.
    It processes objects identified by Get-WinADBrokenProtectedFromDeletion and corrects their protection status.

    .PARAMETER Forest
    The name of the forest to process. If not specified, the current forest is used.

    .PARAMETER ExcludeDomains
    Array of domain names to exclude from processing.

    .PARAMETER IncludeDomains
    Array of domain names to include in processing. If not specified, all domains are processed.

    .PARAMETER ExtendedForestInformation
    Dictionary containing cached forest information.

    .PARAMETER Type
    Required. Specifies the types of objects to process. Valid values are:
    - Computer
    - Group
    - User
    - ManagedServiceAccount
    - GroupManagedServiceAccount
    - Contact
    - All

    .PARAMETER Resolve
    Switch to enable name resolution for Everyone permission.
    This is only nessecary if you have non-english AD, as Everyone is not Everyone in all languages.

    .PARAMETER LimitProcessing
    Limits the number of objects to process.

    .EXAMPLE
    Repair-WinADBrokenProtectedFromDeletion -Type User -WhatIf -LimitProcessing 5
    Repairs protection settings for all user objects in the current forest.

    .EXAMPLE
    Repair-WinADBrokenProtectedFromDeletion -Type Computer,Group -Forest "contoso.com" -ExcludeDomains "dev.contoso.com" -WhatIf -LimitProcessing 5
    Repairs protection settings for computer and group objects in the specified forest, excluding the dev domain.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,
        [ValidateSet(
            'Computer',
            'Group',
            'User',
            'ManagedServiceAccount',
            'GroupManagedServiceAccount',
            'Contact',
            'All'
        )][Parameter(Mandatory)][string[]] $Type,
        [switch] $Resolve,
        [int] $LimitProcessing
    )

    $getWinADBrokenProtectedObjectsSplat = @{
        Forest                    = $Forest
        ExcludeDomains            = $ExcludeDomains
        IncludeDomains            = $IncludeDomains
        ExtendedForestInformation = $ExtendedForestInformation
        Type                      = $Type
        Resolve                   = $Resolve.IsPresent
        ReturnBrokenOnly          = $true
        LimitProcessing           = $LimitProcessing
    }

    $BrokenObjects = Get-WinADBrokenProtectedFromDeletion @getWinADBrokenProtectedObjectsSplat
    $ToFix = [ordered]@{}
    foreach ($Object in $BrokenObjects) {
        if (-not $ToFix[$Object.ParentContainer]) {
            Write-Verbose -Message "Repair-WinADBrokenProtectedFromDeletion - Adding $($Object.DistinguishedName) to list of objects to fix for $($Object.ParentContainer)"
            $ToFix[$Object.ParentContainer] = $Object
        } else {
            Write-Verbose -Message "Repair-WinADBrokenProtectedFromDeletion - Skipping $($Object.DistinguishedName) as it's OU $($Object.ParentContainer) is already in the list of objects to fix"
        }
    }
    foreach ($Container in $ToFix.Keys) {
        $Object = $ToFix[$Container]

        Write-Verbose -Message "Repair-WinADBrokenProtectedFromDeletion - Fixing $($Object.DistinguishedName) in $Container"
        try {
            Set-ADObject -ProtectedFromAccidentalDeletion $true -Identity $Object.DistinguishedName -ErrorAction Stop
        } catch {
            if ($ErrorActionPreference -eq 'Stop') {
                throw
            } else {
                Write-Warning -Message "Repair-WinADBrokenProtectedFromDeletion - Error fixing $($Object.DistinguishedName): $($_.Exception.Message)"
            }
        }

    }
}

