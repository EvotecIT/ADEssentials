function Remove-PrivateACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [PSCustomObject] $ACL,
        [string] $Principal,
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType
    )
    $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $ACL.DistinguishedName
    $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

    if ($Principal -like '*-*-*-*') {
        $Identity = [System.Security.Principal.SecurityIdentifier]::new($Principal)
    } else {
        [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
    }
    $OutputRequiresCommit = @(
        if (-not $AccessRule) {
            # if access rule is not defined this means we want to remove user/group totally
            #Write-Verbose "Remove-ADACL - Removing access for $($ACLAccessRule.Principal) / $($ACLAccessRule.ActiveDirectoryRights)"
            Write-Verbose "Remove-ADACL - Removing access for $($Identity) / $AccessControlType / All Rights"
            try {
                $ACL.ACL.RemoveAccess($Identity, $AccessControlType)
                $true
            } catch {
                Write-Warning "Remove-ADACL - Removing permissions for $($ACL.DistinguishedName) failed: $($_.Exception.Message)"
                $false
            }
        } else {
            # if access rule is defined with just remove access rule we want to remove
            foreach ($Rule in $AccessRule) {
                $AccessRuleToRemove = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType)
                Write-Verbose "Remove-ADACL - Removing access for $($AccessRuleToRemove.IdentityReference) / $AccessControlType / $($AccessRuleToRemove.ActiveDirectoryRights)"
                try {
                    $ACL.ACL.RemoveAccessRule($AccessRuleToRemove)
                    $true
                } catch {
                    Write-Warning "Remove-ADACL - Removing permissions for $($ACL.DistinguishedName) failed: $($_.Exception.Message)"
                    $false
                }
            }
        }
    )
    if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
        Write-Verbose "Remove-ADACL - Saving permissions for $($ACL.DistinguishedName)"
        try {
            Set-ADObject -Identity $ACL.DistinguishedName -Replace @{ ntSecurityDescriptor = $ACL.ACL } -ErrorAction Stop -Server $QueryServer
            # Set-Acl -Path $ACL.Path -AclObject $ACL.ACL -ErrorAction Stop
        } catch {
            Write-Warning "Remove-ADACL - Saving permissions for $($ACL.DistinguishedName) failed: $($_.Exception.Message)"
        }
    } elseif ($OutputRequiresCommit -contains $false) {
        Write-Warning "Remove-ADACL - Skipping saving permissions for $($ACL.DistinguishedName) due to errors."
    }
}