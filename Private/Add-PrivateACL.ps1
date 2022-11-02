function Add-PrivateACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [PSCustomObject] $ACL,
        [string] $ADObject,
        [string] $Principal,
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [string] $ObjectType,
        [string] $InheritedObjectType,
        [nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,
        [System.DirectoryServices.ActiveDirectorySecurity] $ntSecurityDescriptor
    )
    if ($ACL) {
        $ADObject = $ACL.DistinguishedName
    } else {
        if (-not $ADObject) {
            Write-Warning "Add-PrivateACL - No ACL or ADObject specified"
            return
        }
    }

    $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $ADObject
    if (-not $DomainName) {
        Write-Warning -Message "Add-PrivateACL - Unable to determine domain name for $($ADObject)"
        return
    }
    $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

    if ($Principal -like '*/*') {
        $SplittedName = $Principal -split '/'
        [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($SplittedName[0], $SplittedName[1])
    } else {
        [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
    }

    $OutputRequiresCommit = foreach ($Rule in $AccessRule) {
        if ($ObjectType -and $InheritanceType -and $InheritedObjectType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            $InheritedObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $InheritedObjectType
            if ($ObjectTypeGuid -and $InheritedObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType, $ObjectTypeGuid, $InheritanceType, $InheritedObjectTypeGuid)
            } else {
                Write-Warning "Add-PrivateACL - Object type '$ObjectType' not found in schema"
                return
            }
        } elseif ($ObjectType -and $InheritanceType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            if ($ObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType, $ObjectTypeGuid, $InheritanceType)
            } else {
                Write-Warning "Add-PrivateACL - Object type '$ObjectType' not found in schema"
                return
            }
        } elseif ($ObjectType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            if ($ObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType, $ObjectTypeGuid)
            } else {
                Write-Warning "Add-PrivateACL - Object type '$ObjectType' not found in schema"
                return
            }
        } else {
            $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType)
        }
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
            $true
        } catch {
            Write-Warning "Add-ADACL - Error adding permissions for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) due to error: $($_.Exception.Message)"
            $false
        }
    }
    if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
        Write-Verbose "Add-ADACL - Saving permissions for $($ADObject)"
        #Set-Acl -Path $ACL.Path -AclObject $ACL.ACL -ErrorAction Stop

        Set-ADObject -Identity $ADObject -Replace @{ ntSecurityDescriptor = $ntSecurityDescriptor } -ErrorAction Stop -Server $QueryServer
    } elseif ($OutputRequiresCommit -contains $false) {
        Write-Warning "Add-ADACL - Skipping saving permissions for $($ADObject) due to errors."
    }
}