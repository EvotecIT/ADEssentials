function Test-WinADObjectReplicationStatus {
    <#
    .SYNOPSIS
    Tests the replication status of a Windows Active Directory object across domain controllers.

    .DESCRIPTION
    This cmdlet queries the specified object across all domain controllers in the forest, including global catalogs if specified, to check its replication status. It returns a custom object with details about the object's properties and any errors encountered during the query.

    .PARAMETER Identity
    The identity of the object to test. This can be a distinguished name, GUID, or SAM account name.

    .PARAMETER Forest
    The name of the forest to query. If not specified, the current forest is used.

    .PARAMETER ExcludeDomains
    An array of domain names to exclude from the query.

    .PARAMETER IncludeDomains
    An array of domain names to include in the query. If not specified, all domains in the forest are queried.

    .PARAMETER GlobalCatalog
    A switch parameter to include global catalogs in the query.

    .EXAMPLE
    Test-WinADObjectReplicationStatus -Identity "CN=User,DC=example,DC=com"

    .EXAMPLE
    Test-WinADObjectReplicationStatus -Identity "CN=User,DC=example,DC=com" -GlobalCatalog

    .NOTES
    This cmdlet is useful for monitoring the replication status of critical objects across the domain controllers in a forest.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Standard')]
    param(
        [Parameter(ParameterSetName = 'Standard')]
        [string] $Identity,

        [Parameter(ParameterSetName = 'Standard')]
        [alias('ForestName')][string] $Forest,

        [Parameter(ParameterSetName = 'Standard')]
        [string[]] $ExcludeDomains,

        [Parameter(ParameterSetName = 'Standard')]
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,

        [Parameter(ParameterSetName = 'Standard')]
        [switch] $GlobalCatalog
    )

    $ObjectInformation = Get-WinADObject -Identity $Identity
    if ($null -eq $ObjectInformation) {
        Write-Warning "Test-WinADObjectReplicationStatus - Object not found. Try again later or check the object does exists."
        return
    }
    $DomainFromIdentity = $ObjectInformation.Domain
    $DistinguishedName = $ObjectInformation.DistinguishedName

    $ForestInformation = Get-WinADForestDetails -Extended -PreferWritable
    if ($GlobalCatalog) {
        [Array] $GCs = foreach ($DC in $ForestInformation.ForestDomainControllers) {
            if ($DC.IsGlobalCatalog) {
                $DC
            }
        }
    } else {
        [Array] $GCs = foreach ($DC in $ForestInformation.ForestDomainControllers) {
            if ($DC.Domain -eq $DomainFromIdentity) {
                $DC
            }
        }
    }
    $ResultsCached = [ordered] @{}
    $Results = foreach ($GC in $GCs) {
        # Query the specific object on each GC
        Try {
            if ($GlobalCatalog) {
                Write-Verbose -Message "Test-WinADObjectReplicationStatus - Querying $($GC.HostName) on port 3268 for $DistinguishedName"
                $ObjectInfo = Get-ADObject -Identity $DistinguishedName -Server "$($GC.HostName):3268" -Properties * -ErrorAction Stop
            } else {
                Write-Verbose -Message "Test-WinADObjectReplicationStatus - Querying $($GC.HostName) for $DistinguishedName"
                $ObjectInfo = Get-ADObject -Identity $DistinguishedName -Server $GC.HostName -Properties * -ErrorAction Stop
            }
            $ErrorValue = $null
        } catch {
            $ObjectInfo = $null
            Write-Warning "Test-WinADObjectReplicationStatus - Error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
            $ErrorValue = $_.Exception.Message.Replace([System.Environment]::NewLine, '')
        }
        if ($ObjectInfo) {
            $PreparedObject = [PSCustomObject] @{
                DomainController   = $GC.HostName
                Domain             = $GC.Domain
                UserAccountControl = $ObjectInfo.userAccountCOntrol
                Created            = $ObjectInfo.Created
                uSNChanged         = $ObjectInfo.uSNChanged
                uSNCreated         = $ObjectInfo.uSNCreated
                whenCreated        = $ObjectInfo.whenCreated
                WhenChanged        = $ObjectInfo.WhenChanged
                Error              = $ErrorValue
            }
            $ResultsCached[$GC.HostName] = $PreparedObject
            $PreparedObject
        } else {
            $PreparedObject = [PSCustomObject] @{
                DomainController   = $GC.HostName
                Domain             = $GC.Domain
                UserAccountControl = $null
                Created            = $null
                uSNChanged         = $null
                uSNCreated         = $null
                whenCreated        = $null
                WhenChanged        = $null
                Error              = $ErrorValue
            }
            $ResultsCached[$GC.HostName] = $PreparedObject
            $PreparedObject
        }
    }

    $SortedResults = $Results | Sort-Object -Property WhenChanged
    $FistResult = $SortedResults | Where-Object { $null -ne $_.WhenChanged } | Select-Object -First 1
    $Output = foreach ($Result in $SortedResults) {
        [PSCustomObject] @{
            SamAccountName   = $ObjectInformation.SamAccountName
            DomainController = $Result.DomainController
            Domain           = $Result.Domain
            WhenCreated      = $Result.whenCreated
            WhenChanged      = $Result.WhenChanged
            TimeSinceFirst   = if ($Result.WhenChanged) { $Result.WhenChanged - $FistResult.WhenChanged } else { $null }
            Error            = $Result.Error
        }
    }
    $Output | Sort-Object -Property WhenChanged -Descending
}