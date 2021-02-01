function Remove-WinADDuplicateObject {
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
        $Count++
        try {
            Write-Verbose "Remove-WinADDuplicateObject - [$Count/$($DuplicateObjects.Count)] Deleting $($Duplicate.ConflictDN) / $($Duplicate.DomainName) via GUID: $($Duplicate.ObjectGUID)"
            Remove-ADObject -Identity $Duplicate.ObjectGUID -Recursive -ErrorAction Stop -Confirm:$false -Server $Duplicate.DomainName
        } catch {
            Write-Warning "Remove-WinADDuplicateObject - [$Count/$($DuplicateObjects.Count)] Deleting $($Duplicate.ConflictDN) / $($Duplicate.DomainName) via GUID: $($Duplicate.ObjectGUID) failed with error: $($_.Exception.Message)"
        }
    }
}