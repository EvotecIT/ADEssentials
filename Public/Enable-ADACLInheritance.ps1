function Enable-ADACLInheritance {
    <#
    .SYNOPSIS
    Enables inheritance of access control entries (ACEs) from parent objects for one or more Active Directory objects or security principals.

    .DESCRIPTION
    The Enable-ADACLInheritance function enables inheritance of ACEs from parent objects for one or more Active Directory objects or security principals.
    This function can be used to ensure that child objects inherit ACEs from parent objects.

    .PARAMETER ADObject
    Specifies one or more Active Directory objects or security principals to enable inheritance of ACEs from parent objects.

    .PARAMETER ACL
    Specifies one or more access control lists (ACLs) to enable inheritance of ACEs from parent objects.

    .EXAMPLE
    Enable-ADACLInheritance -ADObject 'CN=TestOU,DC=contoso,DC=com'

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ADObject')]
    param(
        [parameter(ParameterSetName = 'ADObject', Mandatory)][alias('Identity')][Array] $ADObject,
        [parameter(ParameterSetName = 'ACL', Mandatory)][Array] $ACL
    )
    if ($ACL) {
        Set-ADACLInheritance -Inheritance 'Enabled' -ACL $ACL
    } else {
        Set-ADACLInheritance -Inheritance 'Enabled' -ADObject $ADObject
    }
}