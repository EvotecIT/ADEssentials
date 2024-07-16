function Add-ACLRule {
    <#
    .SYNOPSIS
    Adds an access control rule to a security descriptor.

    .DESCRIPTION
    The Add-ACLRule function adds an access control rule to a security descriptor. It allows specifying the access rule to add, the security descriptor, and the ACL.

    .PARAMETER AccessRuleToAdd
    Specifies the access rule to add.

    .PARAMETER ntSecurityDescriptor
    Specifies the security descriptor to which the access rule will be added.

    .PARAMETER ACL
    Specifies the ACL to which the access rule will be added.

    .EXAMPLE
    Add-ACLRule -AccessRuleToAdd $rule -ntSecurityDescriptor $securityDescriptor -ACL $acl

    This example adds the access rule $rule to the security descriptor $securityDescriptor and the ACL $acl.

    .NOTES
    This function is designed to handle errors related to identity references that could not be translated.

    #>
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