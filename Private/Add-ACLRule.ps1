function Add-ACLRule {
    [CmdletBinding()]
    param(
        $AccessRuleToAdd,
        $ntSecurityDescriptor,
        $ACL
    )
    try {
        Write-Verbose "Add-ADACL - Adding access for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) / $($AccessRuleToAdd.AccessControlType) / $($AccessRuleToAdd.ObjectType) / $($AccessRuleToAdd.InheritanceType) to $($ACL.DistinguishedName)"
        if ($ACL.ACL) {
            $ntSecurityDescriptor = $ACL.ACL
        } elseif ($ntSecurityDescriptor) {

        } else {
            Write-Warning "Add-PrivateACL - No ACL or ntSecurityDescriptor specified"
            return
        }
        $ntSecurityDescriptor.AddAccessRule($AccessRuleToAdd)
        @{ Success = $true; Reason = $null }
    } catch {
        if ($_.Exception.Message -like "*Some or all identity references could not be translated.*") {
            Write-Warning "Add-ADACL - Error adding permissions for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) due to error: $($_.Exception.Message). Retrying with SID"
            # $SplittedName = $Principal -split '/'
            # [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.SecurityIdentifier]::new($SplittedName[1])
            # $ResolvedIdenity = Convert-Identity -Identity $Principal

            #$AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType)
            #$ntSecurityDescriptor.AddAccessRule($AccessRuleToAdd)
            @{ Success = $false; Reason = "Identity" }
        } else {
            Write-Warning "Add-ADACL - Error adding permissions for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) due to error: $($_.Exception.Message)"
            @{ Success = $false; Reason = $($_.Exception.Message) }
        }
    }
}