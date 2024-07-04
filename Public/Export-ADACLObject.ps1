function Export-ADACLObject {
    <#
    .SYNOPSIS
    Exports the Access Control List (ACL) information for a specified Active Directory object.

    .DESCRIPTION
    This function exports the ACL information for a specified Active Directory object. It provides options to include or exclude specific principals and to bundle the ACL information.

    .PARAMETER ADObject
    Specifies the Active Directory object for which to export the ACL information.

    .PARAMETER IncludePrincipal
    Specifies the principal(s) to include in the exported ACL information.

    .PARAMETER ExcludePrincipal
    Specifies the principal(s) to exclude from the exported ACL information.

    .PARAMETER Bundle
    Indicates whether to bundle the ACL information for each object.

    .PARAMETER OneLiner
    Indicates whether to output the ACL information in a single line.

    .EXAMPLE
    Export-ADACLObject -ADObject 'CN=Users,DC=contoso,DC=com' -Bundle
    Exports the ACL information for the 'Users' container in the 'contoso.com' Active Directory.

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][alias('Identity')][string] $ADObject,
        [alias('Principal')][string[]] $IncludePrincipal,
        [string[]] $ExcludePrincipal,
        [switch] $Bundle,
        [switch] $OneLiner
    )
    $ACLOutput = Get-ADACL -ADObject $ADObject -Bundle
    foreach ($ACL in $ACLOutput.ACLAccessRules) {
        $ConvertedIdentity = Convert-Identity -Identity $ACL.Principal -Verbose:$false
        if ($ConvertedIdentity.Error) {
            Write-Warning -Message "Export-ADACLObject - Converting identity $($ACL.Principal) failed with $($ConvertedIdentity.Error). Be warned."
        }

        if ($IncludePrincipal) {
            if ($ConvertedIdentity.Name -notin $IncludePrincipal) {
                continue
            }
        }
        if ($ExcludePrincipal) {
            if ($ConvertedIdentity.Name -in $ExcludePrincipal) {
                continue
            }
        }
        if ($Bundle) {
            [PSCustomObject] @{
                Principal                 = $ACL.Principal
                ActiveDirectoryAccessRule = $ACL.Bundle
                Action                    = 'Copy'
            }
        } else {
            New-ADACLObject -Principal $ACL.Principal -AccessControlType $ACL.AccessControlType -ObjectType $ACL.ObjectTypeName -InheritedObjectType $ACL.InheritedObjectTypeName -AccessRule $ACL.ActiveDirectoryRights -InheritanceType $ACL.InheritanceType -OneLiner:$OneLiner.IsPresent
        }
    }
}