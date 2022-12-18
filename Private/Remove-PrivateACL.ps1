function Remove-PrivateACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [PSCustomObject] $ACL,
        [string] $Principal,
        [alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [Alias('ObjectTypeName')][string[]] $IncludeObjectTypeName,
        [Alias('InheritedObjectTypeName')][string[]] $IncludeInheritedObjectTypeName,
        [alias('ActiveDirectorySecurityInheritance', 'IncludeActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,
        [switch] $Force,
        [alias('ActiveDirectorySecurity')][System.DirectoryServices.ActiveDirectorySecurity] $NTSecurityDescriptor
    )
    $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $ACL.DistinguishedName
    $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

    $OutputRequiresCommit = @(
        # if access rule is defined with just remove access rule we want to remove
        if ($ntSecurityDescriptor -and $ACL.PSObject.Properties.Name -notcontains 'ACLAccessRules') {
            try {
                # We do last minute filtering here to ensure we don't remove the wrong ACL
                if ($Principal) {
                    $PrincipalRequested = Convert-Identity -Identity $Principal -Verbose:$false
                }
                $SplatFilteredACL = @{
                    # I am not sure on this $ACL, needs testing
                    ACL                                       = $ACL.Bundle
                    Resolve                                   = $true
                    Principal                                 = $Principal
                    #Inherited                                 = $Inherited
                    #NotInherited                              = $NotInherited
                    AccessControlType                         = $AccessControlType
                    IncludeObjectTypeName                     = $IncludeObjectTypeName
                    IncludeInheritedObjectTypeName            = $IncludeInheritedObjectTypeName
                    #ExcludeObjectTypeName                     = $ExcludeObjectTypeName
                    #ExcludeInheritedObjectTypeName            = $ExcludeInheritedObjectTypeName
                    #IncludeActiveDirectoryRights              = $IncludeActiveDirectoryRights
                    #ExcludeActiveDirectoryRights              = $ExcludeActiveDirectoryRights
                    IncludeActiveDirectorySecurityInheritance = $InheritanceType
                    ExcludeActiveDirectorySecurityInheritance = $ExcludeActiveDirectorySecurityInheritance
                    PrincipalRequested                        = $PrincipalRequested
                    Bundle                                    = $Bundle
                }
                Remove-EmptyValue -Hashtable $SplatFilteredACL
                $CheckAgainstFilters = Get-FilteredACL @SplatFilteredACL
                if (-not $CheckAgainstFilters) {
                    continue
                }
                # Now we do remove the ACL
                Write-Verbose -Message "Remove-ADACL - Removing access from $($ACL.CanonicalName) (type: $($ACL.ObjectClass), IsInherited: $($ACL.IsInherited)) for $($ACL.Principal) / $($ACL.ActiveDirectoryRights) / $($ACL.AccessControlType) / $($ACL.ObjectTypeName) / $($ACL.InheritanceType) / $($ACL.InheritedObjectTypeName)"
                #Write-Verbose -Message "Remove-ADACL - Removing access from $($Rule.CanonicalName) (type: $($Rule.ObjectClass), IsInherited: $($Rule.IsInherited)) for $($Rule.Principal) / $($Rule.ActiveDirectoryRights) / $($Rule.AccessControlType) / $($Rule.ObjectTypeName) / $($Rule.InheritanceType) / $($Rule.InheritedObjectTypeName)"
                if ($ACL.IsInherited) {
                    if ($Force) {
                        # isProtected -  true to protect the access rules associated with this ObjectSecurity object from inheritance; false to allow inheritance.
                        # preserveInheritance - true to preserve inherited access rules; false to remove inherited access rules. This parameter is ignored if isProtected is false.
                        $ntSecurityDescriptor.SetAccessRuleProtection($true, $true)
                    } else {
                        Write-Warning "Remove-ADACL - Rule for $($ACL.Principal) / $($ACL.ActiveDirectoryRights) / $($ACL.AccessControlType) / $($ACL.ObjectTypeName) / $($ACL.InheritanceType) / $($ACL.InheritedObjectTypeName) is inherited. Use -Force to remove it."
                        continue
                    }
                }
                $ntSecurityDescriptor.RemoveAccessRuleSpecific($ACL.Bundle)
                $true
            } catch {
                Write-Warning "Remove-ADACL - Removing access from $($ACL.CanonicalName) (type: $($ACL.ObjectClass), IsInherited: $($ACL.IsInherited)) failed: $($_.Exception.Message)"
                $false
            }
        } elseif ($ACL.PSObject.Properties.Name -contains 'ACLAccessRules') {
            foreach ($Rule in $ACL.ACLAccessRules) {
                # We do last minute filtering here to ensure we don't remove the wrong ACL
                if ($Principal) {
                    $PrincipalRequested = Convert-Identity -Identity $Principal -Verbose:$false
                }
                $SplatFilteredACL = @{
                    ACL                                       = $Rule.Bundle
                    Resolve                                   = $true
                    Principal                                 = $Principal
                    #Inherited                                 = $Inherited
                    #NotInherited                              = $NotInherited
                    AccessControlType                         = $AccessControlType
                    IncludeObjectTypeName                     = $IncludeObjectTypeName
                    IncludeInheritedObjectTypeName            = $IncludeInheritedObjectTypeName
                    #ExcludeObjectTypeName                     = $ExcludeObjectTypeName
                    #ExcludeInheritedObjectTypeName            = $ExcludeInheritedObjectTypeName
                    #IncludeActiveDirectoryRights              = $IncludeActiveDirectoryRights
                    #ExcludeActiveDirectoryRights              = $ExcludeActiveDirectoryRights
                    IncludeActiveDirectorySecurityInheritance = $InheritanceType
                    ExcludeActiveDirectorySecurityInheritance = $ExcludeActiveDirectorySecurityInheritance
                    PrincipalRequested                        = $PrincipalRequested
                    Bundle                                    = $Bundle
                }
                Remove-EmptyValue -Hashtable $SplatFilteredACL
                $CheckAgainstFilters = Get-FilteredACL @SplatFilteredACL
                if (-not $CheckAgainstFilters) {
                    continue
                }
                # Now we do remove the ACL
                $ntSecurityDescriptor = $ACL.ACL
                try {
                    Write-Verbose -Message "Remove-ADACL - Removing access from $($Rule.CanonicalName) (type: $($Rule.ObjectClass), IsInherited: $($Rule.IsInherited)) for $($Rule.Principal) / $($Rule.ActiveDirectoryRights) / $($Rule.AccessControlType) / $($Rule.ObjectTypeName) / $($Rule.InheritanceType) / $($Rule.InheritedObjectTypeName)"
                    if ($Rule.IsInherited) {
                        if ($Force) {
                            # isProtected -  true to protect the access rules associated with this ObjectSecurity object from inheritance; false to allow inheritance.
                            # preserveInheritance - true to preserve inherited access rules; false to remove inherited access rules. This parameter is ignored if isProtected is false.
                            $ntSecurityDescriptor.SetAccessRuleProtection($true, $true)
                        } else {
                            Write-Warning "Remove-ADACL - Rule for $($Rule.Principal) / $($Rule.ActiveDirectoryRights) / $($Rule.AccessControlType) / $($Rule.ObjectTypeName) / $($Rule.InheritanceType) / $($Rule.InheritedObjectTypeName) is inherited. Use -Force to remove it."
                            continue
                        }
                    }
                    $ntSecurityDescriptor.RemoveAccessRuleSpecific($Rule.Bundle)
                    #Write-Verbose -Message "Remove-ADACL - Removing access for $($Identity) / $AccessControlType / $Rule"
                    $true
                } catch {
                    Write-Warning "Remove-ADACL - Removing access from $($Rule.CanonicalName) (type: $($Rule.ObjectClass), IsInherited: $($Rule.IsInherited)) failed: $($_.Exception.Message)"
                    $false
                }
            }
        } else {
            $AllRights = $false
            $ntSecurityDescriptor = $ACL.ACL
            # ACL not provided, we need to get all ourselves
            if ($Principal -like '*-*-*-*') {
                $Identity = [System.Security.Principal.SecurityIdentifier]::new($Principal)
            } else {
                [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
            }

            if ($ObjectType -and $InheritanceType -and $AccessRule -and $AccessControlType) {
                $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
                if ($ObjectTypeGuid) {
                    $AccessRuleToRemove = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType, $ObjectTypeGuid, $InheritanceType)
                } else {
                    Write-Warning "Remove-PrivateACL - Object type '$ObjectType' not found in schema"
                    return
                }
            } elseif ($ObjectType -and $AccessRule -and $AccessControlType) {
                $ObjectTypeGuid = Convert-ADSchemaToGuid -SchemaName $ObjectType
                if ($ObjectTypeGuid) {
                    $AccessRuleToRemove = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType, $ObjectTypeGuid)
                } else {
                    Write-Warning "Remove-PrivateACL - Object type '$ObjectType' not found in schema"
                    return
                }
            } elseif ($AccessRule -and $AccessControlType) {
                $AccessRuleToRemove = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $AccessRule, $AccessControlType)
            } else {
                # this is kind of special we fix it later on, it means user requersted Identity, AccessControlType but nothing else
                # Since there's no direct option with ActiveDirectoryAccessRule we fix it using RemoveAccess
                $AllRights = $true
            }
            try {
                if ($AllRights) {
                    Write-Verbose "Remove-ADACL - Removing access for $($Identity) / $AccessControlType / All Rights"
                    $ntSecurityDescriptor.RemoveAccess($Identity, $AccessControlType)
                } else {
                    Write-Verbose "Remove-ADACL - Removing access for $($AccessRuleToRemove.IdentityReference) / $($AccessRuleToRemove.ActiveDirectoryRights) / $($AccessRuleToRemove.AccessControlType) / $($AccessRuleToRemove.ObjectType) / $($AccessRuleToRemove.InheritanceType) to $($ACL.DistinguishedName)"
                    $ntSecurityDescriptor.RemoveAccessRule($AccessRuleToRemove)
                }
                $true
            } catch {
                Write-Warning "Remove-ADACL - Error removing permissions for $($Identity) / $($AccessControlType) due to error: $($_.Exception.Message)"
                $false
            }
        }

    )
    if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
        Write-Verbose "Remove-ADACL - Saving permissions for $($ACL.DistinguishedName)"
        try {
            Set-ADObject -Identity $ACL.DistinguishedName -Replace @{ ntSecurityDescriptor = $ntSecurityDescriptor } -ErrorAction Stop -Server $QueryServer
            # Set-Acl -Path $ACL.Path -AclObject $ntSecurityDescriptor -ErrorAction Stop
        } catch {
            Write-Warning "Remove-ADACL - Saving permissions for $($ACL.DistinguishedName) failed: $($_.Exception.Message)"
        }
    } elseif ($OutputRequiresCommit -contains $false) {
        Write-Warning "Remove-ADACL - Skipping saving permissions for $($ACL.DistinguishedName) due to errors."
    } else {
        Write-Verbose "Remove-ADACL - No changes for $($ACL.DistinguishedName)"
    }
}