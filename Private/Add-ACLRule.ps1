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
            @{ Success = $false; Reason = "Identity" }
        } else {
            Write-Warning "Add-ADACL - Error adding permissions for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) due to error: $($_.Exception.Message)"
            @{ Success = $false; Reason = $($_.Exception.Message) }
        }
    }
}