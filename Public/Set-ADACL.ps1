function Set-ADACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [alias('Identity')][string] $ADObject,
        [Parameter(Mandatory)][Array] $ACLSettings,
        [switch] $Suppress
    )
    $Results = @{
        Add    = [System.Collections.Generic.List[PSCustomObject]]::new()
        Remove = [System.Collections.Generic.List[PSCustomObject]]::new()
        Skip   = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    $CachedACL = [ordered] @{}
    foreach ($ExpectedACL in $ACLSettings) {
        foreach ($Principal in $ExpectedACL.Principal) {
            $ConvertedPrincipal = (Convert-Identity -Identity $Principal).Name
            if (-not $CachedACL[$ConvertedPrincipal]) {
                $CachedACL[$ConvertedPrincipal] = [ordered] @{}
            }
            # user may not provided any action, so we assume 'Set' as default
            $Action = if ($ExpectedACL.Action) { $ExpectedACL.Action } else { 'Set' }
            $ExpectedACL.Action = $Action

            #if ($CachedACL[$Principal]['Action']) {
            $CachedACL[$ConvertedPrincipal]['Action'] = $Action
            #}
            if (-not $CachedACL[$ConvertedPrincipal]['Permissions']) {
                # $CachedACL[$Principal]['Action'][$Action] = [ordered] @{}
                $CachedACL[$ConvertedPrincipal]['Permissions'] = [System.Collections.Generic.List[object]]::new()
            }

            if ($ExpectedACL.Permissions) {
                foreach ($Permission in $ExpectedACL.Permissions) {
                    $CachedACL[$ConvertedPrincipal]['Permissions'].Add($Permission)
                }
            }

        }
    }
    $MainAccessRights = Get-ADACL -ADObject $ADObject -Bundle
    foreach ($CurrentACL in $MainAccessRights.ACLAccessRules) {
        if ($CachedACL[$CurrentACL.Principal]) {
            if ($CachedACL[$CurrentACL.Principal]['Action'] -eq 'Skip') {
                #Write-Verbose "Set-ADACL - Skipping $($CurrentACL.Principal)"
                $Results.Skip.Add(
                    [PSCustomObject] @{
                        Principal         = $CurrentACL.Principal
                        AccessControlType = $CurrentACL.AccessControlType
                        Action            = 'Skip'
                        Permissions       = $CurrentACL
                    }
                )
                continue
            } else {
                Write-Verbose "Set-ADACL - Processing $($CurrentACL.Principal)"
                $DirectMatch = $false
                foreach ($SetPermission in $CachedACL[$CurrentACL.Principal].Permissions) {
                    if ($CurrentACL.AccessControlType -eq $SetPermission.AccessControlType) {

                        if ($CurrentACL.ObjectTypeName -eq $SetPermission.ObjectTypeName) {

                            if ($CurrentACL.ActiveDirectoryRights -eq $SetPermission.ActiveDirectoryRights) {

                                if ($CurrentACL.InheritedObjectTypeName -eq $SetPermission.InheritedObjectTypeName) {

                                    if ($CurrentACL.InheritanceType -eq $SetPermission.InheritanceType) {
                                        $DirectMatch = $true
                                    }
                                }
                            }
                        }
                    }
                }
                if ($DirectMatch) {
                    $Results.Skip.Add(
                        [PSCustomObject] @{
                            Principal         = $CurrentACL.Principal
                            AccessControlType = $CurrentACL.AccessControlType
                            Action            = 'Skip'
                            Permissions       = $CurrentACL
                        }
                    )
                } else {
                    $Results.Remove.Add(
                        [PSCustomObject] @{
                            Principal         = $CurrentACL.Principal
                            AccessControlType = $CurrentACL.AccessControlType
                            Action            = 'Remove'
                            Permissions       = $CurrentACL
                        }
                    )
                }
            }
        } else {
            # we don't have this principal defined for set, needs to be removed
            Write-Verbose "Set-ADACL -Preparing for removal of $($CurrentACL.Principal)"
            $Results.Remove.Add(
                [PSCustomObject] @{
                    Principal         = $CurrentACL.Principal
                    AccessControlType = $CurrentACL.AccessControlType
                    Action            = 'Remove'
                    Permissions       = $CurrentACL
                }
            )
            #Remove-ADACL -ActiveDirectorySecurity $MainAccessRights.ACL -ACL $CurrentACL -Principal $CurrentACL.Principal -AccessControlType $CurrentACL.AccessControlType
        }
    }
    foreach ($Principal in $CachedACL.Keys) {
        if ($CachedACL[$Principal]['Action'] -eq 'Set') {
            foreach ($SetPermission in $CachedACL[$Principal]['Permissions']) {
                $DirectMatch = $false

                foreach ($CurrentACL in $MainAccessRights.ACLAccessRules) {

                    $RequestedPrincipal = Convert-Identity -Identity $Principal

                    if ($CurrentACL.Principal -eq $RequestedPrincipal.Name) {

                        if ($CurrentACL.AccessControlType -eq $SetPermission.AccessControlType) {

                            if ($CurrentACL.ObjectTypeName -eq $SetPermission.ObjectTypeName) {

                                if ($CurrentACL.ActiveDirectoryRights -eq $SetPermission.ActiveDirectoryRights) {

                                    if ($CurrentACL.InheritedObjectTypeName -eq $SetPermission.InheritedObjectTypeName) {

                                        if ($CurrentACL.InheritanceType -eq $SetPermission.InheritanceType) {
                                            $DirectMatch = $true
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
                if ($DirectMatch) {
                    Write-Verbose -Message "Set-ADACL - Skipping $($Principal)"
                } else {
                    $Results.Add.Add(
                        [PSCustomObject] @{
                            Principal         = $Principal
                            AccessControlType = $SetPermission.AccessControlType
                            Action            = 'Add'
                            Permissions       = $SetPermission
                        }
                    )
                }
            }
        }
    }
    if (-not $WhatIfPreference) {
        Write-Verbose -Message "Set-ADACL - Applying changes to ACL"
        if ($Results.Remove.Permissions) {
            Write-Verbose -Message "Set-ADACL - Removing ACL"
            Remove-ADACL -ActiveDirectorySecurity $MainAccessRights.ACL -ACL $Results.Remove.Permissions
        }
        Write-Verbose -Message "Set-ADACL - Adding ACL"
        foreach ($Add in $Results.Add) {
            $addADACLSplat = @{
                NTSecurityDescriptor = $MainAccessRights.ACL
                ADObject             = $ADObject
                Principal            = $Add.Principal
                AccessControlType    = $Add.Permissions.AccessControlType
                AccessRule           = $Add.Permissions.ActiveDirectoryRights
                ObjectType           = $Add.Permissions.ObjectTypeName
                InheritanceType      = $Add.Permissions.InheritanceType
                InheritedObjectType  = $Add.Permissions.InheritedObjectTypeName
            }
            Add-ADACL @addADACLSplat
        }
    }
    if (-not $Suppress) {
        $Results
    }
}