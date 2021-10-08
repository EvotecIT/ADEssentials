function Remove-ADACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [alias('Identity')][Array] $ADObject,
        [Array] $ACL,
        [string] $Principal,
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    )
    if (-not $Script:ForestDetails) {
        Write-Verbose "Remove-ADACL - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }
    if ($PSBoundParameters.ContainsKey('ADObject')) {
        foreach ($Object in $ADObject) {
            $MYACL = Get-ADACL -ADObject $Object -Verbose -NotInherited -Bundle
            foreach ($SubACL in $MYACL) {
                $removePrivateACLSplat = @{
                    ACL               = $SubACL
                    Principal         = $Principal
                    AccessRule        = $AccessRule
                    AccessControlType = $AccessControlType
                    WhatIf            = $WhatIfPreference
                }
                Remove-EmptyValue -Hashtable $removePrivateACLSplat
                Remove-PrivateACL @removePrivateACLSplat
            }
        }
    } elseif ($PSBoundParameters.ContainsKey('ACL')) {
        foreach ($SubACL in $ACL) {
            $removePrivateACLSplat = @{
                ACL               = $SubACL
                Principal         = $Principal
                AccessRule        = $AccessRule
                AccessControlType = $AccessControlType
                WhatIf            = $WhatIfPreference
            }
            Remove-EmptyValue -Hashtable $removePrivateACLSplat
            Remove-PrivateACL @removePrivateACLSplat
        }
    }
}