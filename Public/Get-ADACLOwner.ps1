function Get-ADACLOwner {
    [cmdletBinding()]
    param(
        [Array] $ADObject,
        [switch] $Resolve,
        [System.Collections.IDictionary] $ADAdministrativeGroups,

        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    Begin {
        if (-not $ExtendedForestInformation) {
            $ForestInformation = Get-WinADForestDetails -Extended -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
        } else {
            $ForestInformation = $ExtendedForestInformation
        }
        if (-not $ADAdministrativeGroups -and $Resolve) {
            #Write-Verbose "Get-GPOZaurrOwner - Getting ADAdministrativeGroups"
            $ADAdministrativeGroups = Get-ADADministrativeGroups -Type DomainAdmins, EnterpriseAdmins -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
        }
    }
    Process {
        foreach ($Object in $ADObject) {
            if ($Object -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -or $Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
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
            $ACLs = Get-Acl -Path $PathACL -ErrorAction Stop
            $Hash = [ordered] @{
                DistinguishedName = $DistinguishedName
                Owner             = $ACLs.Owner
                ACLs              = $ACLs
            }
            if ($Resolve) {
                #$Identity = ConvertTo-Identity -Identity $Hash.Owner -ExtendedForestInformation $ForestInformation -ADAdministrativeGroups $ADAdministrativeGroups
                $Identity = Convert-Identity -Identity $Hash.Owner
                if ($Identity) {
                    $Hash['OwnerName'] = $Identity.Name
                    $Hash['OwnerSid'] = $Identity.SID
                    $Hash['OwnerType'] = $Identity.Type
                    #$Hash['OwnerClass'] = $Identity.Class
                } else {
                    $Hash['OwnerName'] = ''
                    $Hash['OwnerSid'] = ''
                    $Hash['OwnerType'] = ''
                    #$Hash['OwnerClass'] = ''
                }
            }
            [PSCustomObject] $Hash
        }

    }
    End { }
}