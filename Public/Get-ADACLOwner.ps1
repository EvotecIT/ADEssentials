function Get-ADACLOwner {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('Identity')][Array] $ADObject,
        [switch] $Resolve,
        [alias('AddACL')][switch] $IncludeACL #,
        # [System.Collections.IDictionary] $ADAdministrativeGroups,

        # [alias('ForestName')][string] $Forest,
        # [string[]] $ExcludeDomains,
        # [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        # [System.Collections.IDictionary] $ExtendedForestInformation
    )
    Begin {
        #if (-not $Script:ADAdministrativeGroups -and $Resolve) {
        #Write-Verbose "Get-GPOZaurrOwner - Getting ADAdministrativeGroups"
        #$ForestInformation = Get-WinADForestDetails -Extended -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
        #$ADAdministrativeGroups = Get-ADADministrativeGroups -Type DomainAdmins, EnterpriseAdmins -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ForestInformation
        #}
        if (-not $Script:ForestDetails) {
            Write-Verbose "Get-ADACL - Gathering Forest Details"
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
                Write-Warning "Get-ADACLOwner - Object not recognized. Skipping..."
                continue
            }
            <#
            $DNConverted = (ConvertFrom-DistinguishedName -DistinguishedName $DistinguishedName -ToDC) -replace '=' -replace ','
            if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                Write-Verbose "Get-ADACLOwner - Enabling PSDrives for $DistinguishedName to $DNConverted"
                New-ADForestDrives -ForestName $ForestName # -ObjectDN $DistinguishedName
                if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                    Write-Warning "Set-ADACLOwner - Drive $DNConverted not mapped. Terminating..."
                    return
                }
            }
            $PathACL = "$DNConverted`:\$($DistinguishedName)"
            #>

            try {
                #$ACLs = Get-Acl -Path $PathACL -ErrorAction Stop
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
                        Write-Warning "Get-ADACL - Path $PathACL - Error: $($_.Exception.Message)"
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
                #$Identity = ConvertTo-Identity -Identity $Hash.Owner -ExtendedForestInformation $ForestInformation -ADAdministrativeGroups $ADAdministrativeGroups
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
            }
            $Hash['Error'] = $ErrorMessage
            [PSCustomObject] $Hash
        }
    }
    End { }
}