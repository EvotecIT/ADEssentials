function Get-WinADLastBackup {
    <#
    .SYNOPSIS
    Gets Active directory forest or domain last backup time

    .DESCRIPTION
    Gets Active directory forest or domain last backup time

    .PARAMETER Domain
    Optionally you can pass Domains by hand

    .EXAMPLE
    $LastBackup = Get-WinADLastBackup
    $LastBackup | Format-Table -AutoSize

    .EXAMPLE
    $LastBackup = Get-WinADLastBackup -Domain 'ad.evotec.pl'
    $LastBackup | Format-Table -AutoSize

    .NOTES
    General notes
    #>

    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $NameUsed = [System.Collections.Generic.List[string]]::new()
    [DateTime] $CurrentDate = Get-Date

    if (-not $ExtendedForestInformation) {
        $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
    } else {
        $ForestInformation = $ExtendedForestInformation
    }
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]
        try {
            [string[]]$Partitions = (Get-ADRootDSE -Server $QueryServer -ErrorAction Stop).namingContexts
            [System.DirectoryServices.ActiveDirectory.DirectoryContextType] $contextType = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain
            [System.DirectoryServices.ActiveDirectory.DirectoryContext] $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext($contextType, $Domain)
            [System.DirectoryServices.ActiveDirectory.DomainController] $domainController = [System.DirectoryServices.ActiveDirectory.DomainController]::FindOne($context)
        } catch {
            Write-Warning "Get-WinADLastBackup - Failed to gather partitions information for $Domain with error $($_.Exception.Message)"
        }

        $Output = ForEach ($Name in $Partitions) {
            if ($NameUsed -contains $Name) {
                continue
            } else {
                $NameUsed.Add($Name)
            }
            $domainControllerMetadata = $domainController.GetReplicationMetadata($Name)
            $dsaSignature = $domainControllerMetadata.Item("dsaSignature")
            try {
                $LastBackup = [DateTime] $($dsaSignature.LastOriginatingChangeTime)
            } catch {
                $LastBackup = [DateTime]::MinValue
            }
            [PSCustomObject] @{
                Domain            = $Domain
                NamingContext     = $Name
                LastBackup        = $LastBackup
                LastBackupDaysAgo = - (Convert-TimeToDays -StartTime ($CurrentDate) -EndTime ($LastBackup))
            }
        }
        $Output
    }
}