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
    #[System.Enum]::GetValues([System.DirectoryServices.ActiveDirectoryRights])
    #[System.DirectoryServices.ActiveDirectoryRights]::CreateChild
    #[System.DirectoryServices.ActiveDirectoryRights]::DeleteChild
    #[System.DirectoryServices.ActiveDirectoryRights]::ListChildren
    #[System.DirectoryServices.ActiveDirectoryRights]::Self
    #[System.DirectoryServices.ActiveDirectoryRights]::ReadProperty
    #[System.DirectoryServices.ActiveDirectoryRights]::WriteProperty
    #[System.DirectoryServices.ActiveDirectoryRights]::DeleteTree
    #[System.DirectoryServices.ActiveDirectoryRights]::ListObject
    #[System.DirectoryServices.ActiveDirectoryRights]::ExtendeRdight
    #[System.DirectoryServices.ActiveDirectoryRights]::Delete
    #[System.DirectoryServices.ActiveDirectoryRights]::ReadControl
    #[System.DirectoryServices.ActiveDirectoryRights]::GenericExecute
    #[System.DirectoryServices.ActiveDirectoryRights]::GenericWrite
    #[System.DirectoryServices.ActiveDirectoryRights]::GenericRead
    #[System.DirectoryServices.ActiveDirectoryRights]::WriteDacl
    #[System.DirectoryServices.ActiveDirectoryRights]::WriteOwner
    #[System.DirectoryServices.ActiveDirectoryRights]::GenericAll
    #[System.DirectoryServices.ActiveDirectoryRights]::Synchronize
    #[System.DirectoryServices.ActiveDirectoryRights]::AccessSystemSecurity

    #if ($Principal -like "*\*") {

    #} elseif ($Principal -like "*@*") {
    #$Server = Get-ADDomainController -Service GlobalCatalog -Discover
    #$User = Get-ADUser -Ldapfilter "(ObjectClass=user)(UserPrincipalName=mmmm@ad.evotec.pl)" -Server "$($Server.HostName):3268"
    #$User = Get-ADUser -Filter { UserPrincipalName -eq $Principal } -Server "$($Server.HostName):3268"
    #}
    foreach ($SubACL in $ACL) {
        #$OutputRequiresCommit = foreach ($ACLAccessRule in $SubACL.ACLAccessRules) {
        #if ($ByIdentity) {
        #if ($ACLAccessRule.Principal -eq $Principal) {
        #$AccessRule
        #[System.Security.Principal.IdentityReference] $Identity = $ACLAccessRule.Bundle.IdentityReference
        $OutputRequiresCommit = @(
            [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
            if (-not $AccessRule) {
                # if access rule is not defined this means we want to remove user/group totally
                #Write-Verbose "Remove-ADACL - Removing access for $($ACLAccessRule.Principal) / $($ACLAccessRule.ActiveDirectoryRights)"
                Write-Verbose "Remove-ADACL - Removing access for $($Identity) / All Rights"
                try {
                    $SubACL.ACL.RemoveAccess($Identity, $AccessControlType)
                    $true
                } catch {
                    $false
                }
            } else {
                # if access rule is defined with just remove access rule we want to remove
                foreach ($Rule in $AccessRule) {
                    $AccessRuleToRemove = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType)
                    Write-Verbose "Remove-ADACL - Removing access for $($AccessRuleToRemove.IdentityReference) / $($AccessRuleToRemove.ActiveDirectoryRights)"
                    $SubACL.ACL.RemoveAccessRule($AccessRuleToRemove)
                }
            }
        )
        #}
        #}
        #}
        if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
            Write-Verbose "Remove-ADACL - Saving permissions for $($SubACL.DistinguishedName)"
            Set-Acl -Path $SubACL.Path -AclObject $SubACL.ACL -ErrorAction Stop
        } elseif ($OutputRequiresCommit -contains $false) {
            Write-Warning "Remove-ADACL - Skipping saving permissions for $($SubACL.DistinguishedName) due to errors."
        }
    }
}