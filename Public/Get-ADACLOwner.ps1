function Get-ADACLOwner {
    <#
    .SYNOPSIS
    Gets owner from given Active Directory object

    .DESCRIPTION
    Gets owner from given Active Directory object

    .PARAMETER ADObject
    Active Directory object to get owner from

    .PARAMETER Resolve
    Resolves owner to provide more details about said owner

    .PARAMETER IncludeACL
    Include additional ACL information along with owner

    .PARAMETER IncludeOwnerType
    Include only specific Owner Type, by default all Owner Types are included

    .PARAMETER ExcludeOwnerType
    Exclude specific Owner Type, by default all Owner Types are included

    .EXAMPLE
    Get-ADACLOwner -ADObject 'CN=Policies,CN=System,DC=ad,DC=evotec,DC=xyz' -Resolve | Format-Table

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('Identity')][Array] $ADObject,
        [switch] $Resolve,
        [alias('AddACL')][switch] $IncludeACL,
        [validateSet('WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown')][string[]] $IncludeOwnerType,
        [validateSet('WellKnownAdministrative', 'Administrative', 'NotAdministrative', 'Unknown')][string[]] $ExcludeOwnerType
    )
    Begin {
        if (-not $Script:ForestDetails) {
            Write-Verbose "Get-ADACLOwner - Gathering Forest Details"
            $Script:ForestDetails = Get-WinADForestDetails
        }
    }
    Process {
        foreach ($Object in $ADObject) {
            $ADObjectData = $null
            if ($Object -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -or $Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
                # if object already has proper security descriptor we don't need to do additional querying
                if ($Object.ntSecurityDescriptor) {
                    $ADObjectData = $Object
                }
                [string] $DistinguishedName = $Object.DistinguishedName
                [string] $CanonicalName = $Object.CanonicalName
                [string] $ObjectClass = $Object.ObjectClass
            } elseif ($Object -is [string]) {
                [string] $DistinguishedName = $Object
                [string] $CanonicalName = ''
                [string] $ObjectClass = ''
            } else {
                if ($Object.ntSecurityDescriptor) {
                    $ADObjectData = $Object
                    [string] $DistinguishedName = $Object.DistinguishedName
                    [string] $CanonicalName = $Object.CanonicalName
                    if ($CanonicalName) {
                        $CanonicalName = $CanonicalName.TrimEnd('/')
                    }
                    [string] $ObjectClass = $Object.ObjectClass
                } else {
                    Write-Warning "Get-ADACLOwner - Object not recognized. Skipping..."
                    continue
                }
            }
            try {
                if (-not $ADObjectData) {
                    $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $DistinguishedName
                    $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]
                    try {
                        $ADObjectData = Get-ADObject -Identity $DistinguishedName -Properties ntSecurityDescriptor, CanonicalName, ObjectClass -ErrorAction Stop -Server $QueryServer
                        # Since we already request an object we might as well use the data and overwrite it if people use the string
                        $ObjectClass = $ADObjectData.ObjectClass
                        $CanonicalName = $ADObjectData.CanonicalName
                        # Real ACL
                        $ACLs = $ADObjectData.ntSecurityDescriptor
                    } catch {
                        Write-Warning "Get-ADACLOwner - Path $PathACL - Error: $($_.Exception.Message)"
                        continue
                    }
                } else {
                    # Real ACL
                    $ACLs = $ADObjectData.ntSecurityDescriptor
                }
                $Hash = [ordered] @{
                    DistinguishedName = $DistinguishedName
                    CanonicalName     = $CanonicalName
                    ObjectClass       = $ObjectClass
                    Owner             = $ACLs.Owner
                }
                $ErrorMessage = ''
            } catch {
                $ACLs = $null
                $Hash = [ordered] @{
                    DistinguishedName = $DistinguishedName
                    CanonicalName     = $CanonicalName
                    ObjectClass       = $ObjectClass
                    Owner             = $null
                }
                $ErrorMessage = $_.Exception.Message
            }
            if ($IncludeACL) {
                $Hash['ACLs'] = $ACLs
            }
            if ($Resolve) {
                if ($null -eq $Hash.Owner) {
                    $Identity = $null
                } else {
                    $Identity = Convert-Identity -Identity $Hash.Owner -Verbose:$false
                }
                if ($Identity) {
                    $Hash['OwnerName'] = $Identity.Name
                    $Hash['OwnerSid'] = $Identity.SID
                    $Hash['OwnerType'] = $Identity.Type
                } else {
                    $Hash['OwnerName'] = ''
                    $Hash['OwnerSid'] = ''
                    $Hash['OwnerType'] = ''
                }

                if ($PSBoundParameters.ContainsKey('IncludeOwnerType')) {
                    if ($Hash['OwnerType'] -in $IncludeOwnerType) {

                    } else {
                        continue
                    }
                }
                if ($PSBoundParameters.ContainsKey('ExcludeOwnerType')) {
                    if ($Hash['OwnerType'] -in $ExcludeOwnerType) {
                        continue
                    }
                }
            }
            $Hash['Error'] = $ErrorMessage
            [PSCustomObject] $Hash
        }
    }
    End { }
}