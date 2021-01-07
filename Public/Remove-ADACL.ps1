function Remove-ADACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Array] $ACL,
        [string] $Principal,
        #[switch] $ByIdentity,
        #[switch] $Remove,
        #[switch] $RemoveRights,
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    )
    foreach ($SubACL in $ACL) {
        $OutputRequiresCommit = @(
            if ($Principal -like '*-*-*-*') {
                $Identity = [System.Security.Principal.SecurityIdentifier]::new($Principal)
            } else {
                [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
            }
            if (-not $AccessRule) {
                # if access rule is not defined this means we want to remove user/group totally
                #Write-Verbose "Remove-ADACL - Removing access for $($ACLAccessRule.Principal) / $($ACLAccessRule.ActiveDirectoryRights)"
                Write-Verbose "Remove-ADACL - Removing access for $($Identity) / All Rights"
                try {
                    $SubACL.ACL.RemoveAccess($Identity, $AccessControlType)
                    $true
                } catch {
                    Write-Warning "Remove-ADACL - Removing permissions for $($SubACL.DistinguishedName) failed: $($_.Exception.Message)"
                    $false
                }
            } else {
                # if access rule is defined with just remove access rule we want to remove
                foreach ($Rule in $AccessRule) {
                    $AccessRuleToRemove = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType)
                    Write-Verbose "Remove-ADACL - Removing access for $($AccessRuleToRemove.IdentityReference) / $($AccessRuleToRemove.ActiveDirectoryRights)"
                    try {
                        $SubACL.ACL.RemoveAccessRule($AccessRuleToRemove)
                        $true
                    } catch {
                        Write-Warning "Remove-ADACL - Removing permissions for $($SubACL.DistinguishedName) failed: $($_.Exception.Message)"
                        $false
                    }
                }
            }
        )
        if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
            Write-Verbose "Remove-ADACL - Saving permissions for $($SubACL.DistinguishedName)"
            try {
                Set-Acl -Path $SubACL.Path -AclObject $SubACL.ACL -ErrorAction Stop
            } catch {
                Write-Warning "Remove-ADACL - Saving permissions for $($SubACL.DistinguishedName) failed: $($_.Exception.Message)"
            }
        } elseif ($OutputRequiresCommit -contains $false) {
            Write-Warning "Remove-ADACL - Skipping saving permissions for $($SubACL.DistinguishedName) due to errors."
        }
    }
}