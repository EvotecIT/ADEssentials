function New-ActiveDirectoryAccessRule {
    <#
    .SYNOPSIS
    Creates a new Active Directory access rule based on the provided parameters.

    .DESCRIPTION
    This function creates a new Active Directory access rule based on the provided parameters. It allows for flexibility in defining the access rule by specifying various attributes such as object type, inheritance type, inherited object type, access control type, access rule, and identity.

    .PARAMETER ActiveDirectoryAccessRule
    Specifies an existing Active Directory access rule object to use as a template for the new rule.

    .PARAMETER ObjectType
    Specifies the type of object for which the access rule applies.

    .PARAMETER InheritanceType
    Specifies the inheritance type for the access rule.

    .PARAMETER InheritedObjectType
    Specifies the inherited object type for the access rule.

    .PARAMETER AccessControlType
    Specifies the type of access control for the access rule.

    .PARAMETER AccessRule
    Specifies the access rule to apply.

    .PARAMETER Identity
    Specifies the identity to which the access rule applies.

    .EXAMPLE
    New-ActiveDirectoryAccessRule -ObjectType "User" -InheritanceType "All" -AccessControlType "Allow" -AccessRule "Read" -Identity "Domain Admins"
    Creates a new Active Directory access rule allowing "Domain Admins" to read objects of type "User" with inheritance for all child objects.

    .EXAMPLE
    New-ActiveDirectoryAccessRule -ActiveDirectoryAccessRule $existingRule -InheritanceType "None" -AccessControlType "Deny" -AccessRule "Write" -Identity "Guests"
    Creates a new Active Directory access rule based on an existing rule, denying "Guests" the ability to write to objects with no inheritance.

    #>
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
                if (-not $ObjectTypeGuid -and -not $InheritedObjectTypeGuid) {
                    Write-Warning "Add-PrivateACL - Object type '$ObjectType' or '$InheritedObjectType' not found in schema"
                } elseif (-not $ObjectTypeGuid) {
                    Write-Warning "Add-PrivateACL - Object type '$ObjectType' not found in schema"
                } else {
                    Write-Warning "Add-PrivateACL - Object type '$InheritedObjectType' not found in schema"
                }
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