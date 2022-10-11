function Enable-ADACLInheritance {
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