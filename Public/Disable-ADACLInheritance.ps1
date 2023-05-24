function Disable-ADACLInheritance {
    <#
    .SYNOPSIS
    Disables inheritance of access control entries (ACEs) from parent objects for one or more Active Directory objects or security principals.

    .DESCRIPTION
    The Disable-ADACLInheritance function disables inheritance of ACEs from parent objects for one or more Active Directory objects or security principals. This function can be used to prevent unwanted ACEs from being inherited by child objects.

    .PARAMETER ADObject
    Specifies one or more Active Directory objects or security principals to disable inheritance of ACEs from parent objects. This parameter is mandatory when the 'ADObject' parameter set is used.

    .PARAMETER ACL
    Specifies one or more access control lists (ACLs) to disable inheritance of ACEs from parent objects. This parameter is mandatory when the 'ACL' parameter set is used.

    .PARAMETER RemoveInheritedAccessRules
    Indicates whether to remove inherited ACEs from the object or principal. If this switch is specified, inherited ACEs are removed from the object or principal. If this switch is not specified, inherited ACEs are retained on the object or principal.

    .EXAMPLE
    Disable-ADACLInheritance -ADObject 'CN=TestOU,DC=contoso,DC=com'

    This example disables inheritance of ACEs from the parent object for the 'TestOU' organizational unit in the 'contoso.com' domain.

    .EXAMPLE
    Disable-ADACLInheritance -ACL $ACL -RemoveInheritedAccessRules

    This example disables inheritance of ACEs from parent objects for the ACL specified in the $ACL variable, and removes any inherited ACEs from the object or principal.

    .NOTES

    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ADObject')]
    param(
        [parameter(ParameterSetName = 'ADObject', Mandatory)][alias('Identity')][Array] $ADObject,
        [parameter(ParameterSetName = 'ACL', Mandatory)][Array] $ACL,

        [switch] $RemoveInheritedAccessRules
    )
    if ($ACL) {
        Set-ADACLInheritance -Inheritance 'Disabled' -ACL $ACL -RemoveInheritedAccessRules:$RemoveInheritedAccessRules.IsPresent
    } else {
        Set-ADACLInheritance -Inheritance 'Disabled' -ADObject $ADObject -RemoveInheritedAccessRules:$RemoveInheritedAccessRules.IsPresentF
    }
}