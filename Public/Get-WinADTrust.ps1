function Get-WinADTrust {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER Forest
    Target different Forest, by default current forest is used

    .PARAMETER Recursive
    Parameter description

    .PARAMETER Nesting
    Parameter description

    .PARAMETER UniqueTrusts
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [alias('Get-WinADTrusts')]
    [cmdletBinding()]
    param(
        [string] $Forest,
        [switch] $Recursive,
        [Parameter(DontShow)][int] $Nesting = -1,
        [Parameter(DontShow)][System.Collections.IDictionary] $UniqueTrusts
    )
    Begin {
        if ($Nesting -eq -1) {
            $UniqueTrusts = [ordered]@{}
        }
    }
    Process {
        $Nesting++
        $ForestInformation = Get-WinADForest -Forest $Forest
        [Array] $Trusts = @(
            try {
                $TrustRelationship = $ForestInformation.GetAllTrustRelationships()
                foreach ($Trust in $TrustRelationship) {
                    [ordered] @{
                        Type          = 'Forest'
                        Details       = $Trust
                        ExecuteObject = $ForestInformation
                    }
                }
            } catch {
                Write-Warning "Get-WinADForest - Can't process trusts for $Forest, error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
            }
            foreach ($Domain in $ForestInformation.Domains) {
                $DomainInformation = Get-WinADDomain -Domain $Domain.Name
                try {
                    $TrustRelationship = $DomainInformation.GetAllTrustRelationships()
                    foreach ($Trust in $TrustRelationship) {
                        [ordered] @{
                            Type          = 'Domain'
                            Details       = $Trust
                            ExecuteObject = $DomainInformation
                        }
                    }
                } catch {
                    Write-Warning "Get-WinADForest - Can't process trusts for $Domain, error: $($_.Exception.Message.Replace([System.Environment]::NewLine,''))"
                }
            }
        )
        [Array] $Output = foreach ($Trust in $Trusts) {
            Write-Verbose "Get-WinADTrust - From: $($Trust.Details.SourceName) To: $($Trust.Details.TargetName) Nesting: $Nesting"
            $UniqueID1 = -join ($Trust.Details.SourceName, $Trust.Details.TargetName)
            $UniqueID2 = -join ($Trust.Details.TargetName, $Trust.Details.SourceName)
            if (-not $UniqueTrusts[$UniqueID1]) {
                $UniqueTrusts[$UniqueID1] = $true
            } else {
                Write-Verbose "Get-WinADTrust - Trust already on the list (From: $($Trust.Details.SourceName) To: $($Trust.Details.TargetName) Nesting: $Nesting)"
                continue
            }
            if (-not $UniqueTrusts[$UniqueID2]) {
                $UniqueTrusts[$UniqueID2] = $true
            } else {
                Write-Verbose "Get-WinADTrust - Trust already on the list (Reverse) (From: $($Trust.Details.TargetName) To: $($Trust.Details.SourceName) Nesting: $Nesting"
                continue
            }
            $TrustObject = Get-WinADTrustObject -Domain $Trust.ExecuteObject.Name -AsHashTable
            # https://github.com/vletoux/pingcastle/issues/9
            if ($TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "Enable TGT DELEGATION") {
                $TGTDelegation = $true
            } elseif ($TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "No TGT DELEGATION") {
                $TGTDelegation = $false
            } else {
                # Assuming all patches are installed (past July 2019)
                $TGTDelegation = $false
            }

            $TrustStatus = Test-DomainTrust -Domain $Trust.Details.SourceName -TrustedDomain $Trust.Details.TargetName
            $GroupExists = Get-WinADObject -Identity 'S-1-5-32-544' -DomainName $Trust.Details.TargetName
            [PsCustomObject] @{
                'TrustSource'             = $Trust.Details.SourceName #$Domain
                'TrustTarget'             = $Trust.Details.TargetName #$Trust.Target
                'TrustDirection'          = $Trust.Details.TrustDirection.ToString() #$Trust.Direction.ToString()
                'TrustBase'               = $Trust.Type
                'TrustType'               = $Trust.Details.TrustType.ToString()
                'TrustTypeAD'             = $TrustObject[$Trust.Details.TargetName].TrustType
                'Level'                   = $Nesting
                'SuffixesIncluded'        = (($Trust.Details.TopLevelNames | Where-Object { $_.Status -eq 'Enabled' }).Name) -join ', '
                'SuffixesExcluded'        = $Trust.Details.ExcludedTopLevelNames.Name
                'TrustAttributes'         = $TrustObject[$Trust.Details.TargetName].TrustAttributes -join ', '
                'TrustStatus'             = $TrustStatus.TrustStatus
                'QueryStatus'             = if ($GroupExists) { 'OK' } else { 'NOT OK' }
                'ForestTransitive'        = $TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "Forest Transitive"
                'SelectiveAuthentication' = $TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "Cross Organization"
                #'SIDFilteringForestAware' = $null
                'SIDFilteringQuarantined' = $TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "Quarantined Domain"
                'DisallowTransitivity'    = $TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "Non Transitive"
                'IntraForest'             = $TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "Within Forest"
                #'IsTreeParent'            = $null #$Trust.IsTreeParent
                #'IsTreeRoot'              = $Trust.Details.TrustType.ToString() -eq 'TreeRoot'
                'IsTGTDelegationEnabled'  = $TGTDelegation
                #'TrustedPolicy'           = $null #$Trust.TrustedPolicy
                #'TrustingPolicy'          = $null #$Trust.TrustingPolicy
                'UplevelOnly'             = $TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "UpLevel Only"
                'UsesAESKeys'             = $TrustObject[$Trust.Details.TargetName].msDSSupportedEncryptionTypes -contains "AES128-CTS-HMAC-SHA1-96" -or $TrustObject[$Trust.Details.TargetName].msDSSupportedEncryptionTypes -contains 'AES256-CTS-HMAC-SHA1-96'
                'UsesRC4Encryption'       = $TrustObject[$Trust.Details.TargetName].TrustAttributes -contains "Uses RC4 Encryption"
                'EncryptionTypes'         = $TrustObject[$Trust.Details.TargetName].msDSSupportedEncryptionTypes -join ', '
                'TrustSourceDC'           = $TrustStatus.TrustSourceDC
                'TrustTargetDC'           = $TrustStatus.TrustTargetDC
                'ObjectGUID'              = $TrustObject[$Trust.Details.TargetName].ObjectGuid
                'ObjectSID'               = $TrustObject[$Trust.Details.TargetName].ObjectSID
                'Created'                 = $TrustObject[$Trust.Details.TargetName].WhenCreated
                'Modified'                = $TrustObject[$Trust.Details.TargetName].WhenChanged
                'TrustDirectionText'      = $TrustObject[$Trust.Details.TargetName].TrustDirectionText
                'TrustTypeText'           = $TrustObject[$Trust.Details.TargetName].TrustTypeText
                'AdditionalInformation'   = [ordered] @{
                    'msDSSupportedEncryptionTypes' = $TrustObject[$Trust.Details.TargetName].msDSSupportedEncryptionTypes
                    'msDSTrustForestTrustInfo'     = $TrustObject[$Trust.Details.TargetName].msDSTrustForestTrustInfo
                    'SuffixesInclude'              = $Trust.Details.TopLevelNames
                    'SuffixesExclude'              = $Trust.Details.ExcludedTopLevelNames
                    'TrustObject'                  = $TrustObject
                    'GroupExists'                  = $GroupExists
                }
            }
        }
        if ($Output -and $Output.Count -gt 0) {
            $Output
        }
        if ($Recursive) {
            foreach ($Trust in $Output) {
                if ($Trust.TrustType -notin 'TreeRoot', 'ParentChild') {
                    Get-WinADTrust -Forest $Trust.TrustTarget -Recursive -Nesting $Nesting -UniqueTrusts $UniqueTrusts
                }
            }
        }
    }
}