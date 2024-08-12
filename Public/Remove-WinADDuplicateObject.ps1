function Remove-WinADDuplicateObject {
    <#
    .SYNOPSIS
    Removes duplicate objects from Active Directory based on specified criteria.

    .DESCRIPTION
    This cmdlet identifies and removes duplicate objects from Active Directory based on the provided parameters. It first retrieves a list of duplicate objects using Get-WinADDuplicateObject, then iterates through the list to remove each object. If an object is protected from accidental deletion, it attempts to remove the protection before deletion.

    .PARAMETER Forest
    Specifies the name of the forest to search for duplicate objects. This parameter is optional.

    .PARAMETER ExcludeDomains
    Specifies an array of domain names to exclude from the search for duplicate objects.

    .PARAMETER IncludeDomains
    Specifies an array of domain names to include in the search for duplicate objects.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest, such as domain controllers or other forest-specific details.

    .PARAMETER PartialMatchDistinguishedName
    Specifies a partial distinguished name to match when searching for duplicate objects.

    .PARAMETER IncludeObjectClass
    Specifies an array of object classes to include in the search for duplicate objects.

    .PARAMETER ExcludeObjectClass
    Specifies an array of object classes to exclude from the search for duplicate objects.

    .PARAMETER LimitProcessing
    Specifies the maximum number of duplicate objects to process for removal. The default is to process all found duplicates.

    .EXAMPLE
    Remove-WinADDuplicateObject -Forest "example.local" -IncludeDomains "example.local", "subdomain.example.local" -IncludeObjectClass "User", "Group" -LimitProcessing 10

    This example removes up to 10 duplicate user and group objects from the "example.local" and "subdomain.example.local" domains in the "example.local" forest.

    .EXAMPLE
    Remove-WinADDuplicateObject -ExcludeDomains "example.local" -PartialMatchDistinguishedName "OU=Finance,"

    This example removes duplicate objects with a distinguished name containing "OU=Finance," from all domains except "example.local".
    #>
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation,

        [string] $PartialMatchDistinguishedName,
        [string[]] $IncludeObjectClass,
        [string[]] $ExcludeObjectClass,

        [int] $LimitProcessing = [int32]::MaxValue
    )

    $getWinADDuplicateObjectSplat = @{
        Forest                        = $Forest
        ExcludeDomains                = $ExcludeDomains
        IncludeDomains                = $IncludeDomains
        IncludeObjectClass            = $IncludeObjectClass
        ExcludeObjectClass            = $ExcludeObjectClass
        PartialMatchDistinguishedName = $PartialMatchDistinguishedName
    }
    $Count = 0
    $DuplicateObjects = Get-WinADDuplicateObject @getWinADDuplicateObjectSplat
    foreach ($Duplicate in $DuplicateObjects | Select-Object -First $LimitProcessing) {
        If ($Duplicate.ProtectedFromAccidentalDeletion -eq $true) {
            Try {
                Set-ADObject -Identity $($Duplicate.ObjectGUID) -ProtectedFromAccidentalDeletion $false -ErrorAction Stop -Server $Duplicate.Server
            } Catch {
                Write-Warning "Skipped object GUID: $($Duplicate.ObjectGUID) from deletion, failed to remove ProtectedFromAccidentalDeletion"
                Write-Verbose "Error message $($_.Exception.Message)"
                Continue
            }
        }
        $Count++
        try {
            Write-Verbose "Remove-WinADDuplicateObject - [$Count/$($DuplicateObjects.Count)] Deleting $($Duplicate.ConflictDN) / $($Duplicate.DomainName) via GUID: $($Duplicate.ObjectGUID)"
            Remove-ADObject -Identity $Duplicate.ObjectGUID -Recursive -ErrorAction Stop -Confirm:$false -Server $Duplicate.Server
        } catch {
            Write-Warning "Remove-WinADDuplicateObject - [$Count/$($DuplicateObjects.Count)] Deleting $($Duplicate.ConflictDN) / $($Duplicate.DomainName) via GUID: $($Duplicate.ObjectGUID) failed with error: $($_.Exception.Message)"
        }
    }
}