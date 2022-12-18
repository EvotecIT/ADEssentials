function New-ActiveDirectoryAccessRule {
    [CmdletBinding()]
    param(
        $ActiveDirectoryAccessRule,
        $ObjectType,
        $InheritanceType,
        $InheritedObjectType,
        $AccessControlType,
        $AccessRule,
        $Identity
    )

    try {
        if ($ActiveDirectoryAccessRule) {
            $AccessRuleToAdd = $ActiveDirectoryAccessRule
        } elseif ($ObjectType -and $InheritanceType -and $InheritedObjectType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            $InheritedObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $InheritedObjectType
            if ($ObjectTypeGuid -and $InheritedObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType, $ObjectTypeGuid, $InheritanceType, $InheritedObjectTypeGuid)
            } else {
                Write-Warning "Add-PrivateACL - Object type '$ObjectType' or '$InheritedObjectType' not found in schema"
                return
            }
        } elseif ($ObjectType -and $InheritanceType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            if ($ObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType, $ObjectTypeGuid, $InheritanceType)
            } else {
                Write-Warning "Add-PrivateACL - Object type '$ObjectType' not found in schema"
                return
            }
        } elseif ($ObjectType) {
            $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
            if ($ObjectTypeGuid) {
                $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType, $ObjectTypeGuid)
            } else {
                Write-Warning "Add-PrivateACL - Object type '$ObjectType' not found in schema"
                return
            }
        } else {
            $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType)
        }
    } catch {
        Write-Warning "Add-PrivateACL - Error creating ActiveDirectoryAccessRule: $_"
        return
    }
    $AccessRuleToAdd
}