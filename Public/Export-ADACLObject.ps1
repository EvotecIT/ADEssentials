function Export-ADACLObject {
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