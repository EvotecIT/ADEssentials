function Disable-ADACLInheritance {
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