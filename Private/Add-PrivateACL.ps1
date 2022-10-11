function Add-PrivateACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [PSCustomObject] $ACL,
        [string] $Principal,
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [string] $ObjectType,
        [nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType
    )
    $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $ACL.DistinguishedName
    $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

    if ($Principal -like '*/*') {
        $SplittedName = $Principal -split '/'
        [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($SplittedName[0], $SplittedName[1])
    } else {
        [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
    }

    $OutputRequiresCommit = foreach ($Rule in $AccessRule) {
        if ($ObjectType -and $InheritanceType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            if ($ObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType, $ObjectTypeGuid, $InheritanceType)
            } else {
                Write-Warning "Object type '$ObjectType' not found in schema"
                return
            }
        } elseif ($ObjectType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            if ($ObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType, $ObjectTypeGuid)
            } else {
                Write-Warning "Object type '$ObjectType' not found in schema"
                return
            }
        } else {
            $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType)
        }
        try {
            Write-Verbose "Add-ADACL - Adding access for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) / $($AccessRuleToAdd.AccessControlType) / $($AccessRuleToAdd.ObjectType) / $($AccessRuleToAdd.InheritanceType) to $($ACL.DistinguishedName)"
            $ACL.ACL.AddAccessRule($AccessRuleToAdd)
            $true
        } catch {
            Write-Warning "Add-ADACL - Error adding permissions for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) due to error: $($_.Exception.Message)"
            $false
        }
    }
    if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
        Write-Verbose "Add-ADACL - Saving permissions for $($ACL.DistinguishedName)"
        #Set-Acl -Path $ACL.Path -AclObject $ACL.ACL -ErrorAction Stop
        Set-ADObject -Identity $ACL.DistinguishedName -Replace @{ ntSecurityDescriptor = $ACL.ACL } -ErrorAction Stop -Server $QueryServer
    } elseif ($OutputRequiresCommit -contains $false) {
        Write-Warning "Add-ADACL - Skipping saving permissions for $($ACL.DistinguishedName) due to errors."
    }
}