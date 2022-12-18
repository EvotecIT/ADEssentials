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

    $ExpectedProperties = @('ActiveDirectoryRights', 'AccessControlType', 'ObjectTypeName', 'InheritedObjectTypeName', 'InheritanceType')

    $FoundDisprepancy = $false
    $Count = 1
    foreach ($ACL in $ACLSettings) {
        if ($ACL.Principal -and $ACL.Permissions) {
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject @($ACL.Permissions.Keys) | Where-Object { $_.SideIndicator -in '<=' } | ForEach-Object {
                Write-Warning -Message "Set-ADACL - Entry $Count - $($ACL.Principal) is missing property $($_.InputObject)"
                $FoundDisprepancy = $true
            }
        } elseif ($ACL.Principal) {
            Compare-Object -ReferenceObject $ExpectedProperties -DifferenceObject @($ACL.Keys) | Where-Object { $_.SideIndicator -in '<=' } | ForEach-Object {
                Write-Warning -Message "Set-ADACL - Entry $Count - $($ACL.Principal) is missing property $($_.InputObject)"
                $FoundDisprepancy = $true
            }
        }
        $Count++
    }
    if ($FoundDisprepancy) {
        Write-Warning -Message "Set-ADACL - Please check your ACL configuration is correct. Each entry must have the following properties: $($ExpectedProperties -join ', ')"
        return
    }
    foreach ($ExpectedACL in $ACLSettings) {
        if ($ExpectedACL.Principal -and $ExpectedACL.Permissions) {
            foreach ($Principal in $ExpectedACL.Principal) {
                $ConvertedIdentity = Convert-Identity -Identity $Principal -Verbose:$false
                if ($ConvertedIdentity.Error) {
                    Write-Warning -Message "Set-ADACL - Converting identity $($Principal) failed with $($ConvertedIdentity.Error). Be warned."
                }
                $ConvertedPrincipal = ($ConvertedIdentity).Name
                if (-not $CachedACL[$ConvertedPrincipal]) {
                    $CachedACL[$ConvertedPrincipal] = [ordered] @{}
                }
                # user may not provided any action, so we assume 'Set' as default
                $Action = if ($ExpectedACL.Action) { $ExpectedACL.Action } else { 'Add' }
                $ExpectedACL.Action = $Action

                $CachedACL[$ConvertedPrincipal]['Action'] = $Action

                if (-not $CachedACL[$ConvertedPrincipal]['Permissions']) {
                    $CachedACL[$ConvertedPrincipal]['Permissions'] = [System.Collections.Generic.List[object]]::new()
                }

                if ($ExpectedACL.Permissions) {
                    foreach ($Permission in $ExpectedACL.Permissions) {
                        $CachedACL[$ConvertedPrincipal]['Permissions'].Add([PSCustomObject] $Permission)
                    }
                }

            }
        } elseif ($ExpectedACL.Principal) {
            foreach ($Principal in $ExpectedACL.Principal) {
                $ConvertedIdentity = Convert-Identity -Identity $Principal -Verbose:$false
                if ($ConvertedIdentity.Error) {
                    Write-Warning -Message "Set-ADACL - Converting identity $($Principal) failed with $($ConvertedIdentity.Error). Be warned."
                }
                $ConvertedPrincipal = ($ConvertedIdentity).Name
                if (-not $CachedACL[$ConvertedPrincipal]) {
                    $CachedACL[$ConvertedPrincipal] = [ordered] @{}
                }

                # user may not provided any action, so we assume 'Set' as default
                $Action = if ($ExpectedACL.Action) { $ExpectedACL.Action } else { 'Add' }
                $ExpectedACL.Action = $Action

                $CachedACL[$ConvertedPrincipal]['Action'] = $Action

                if (-not $CachedACL[$ConvertedPrincipal]['Permissions']) {
                    $CachedACL[$ConvertedPrincipal]['Permissions'] = [System.Collections.Generic.List[object]]::new()
                }

                $NewPermission = [ordered] @{}
                foreach ($Key in $ExpectedACL.Keys) {
                    if ($Key -notin @('Principal')) {
                        $NewPermission.$Key = $ExpectedACL.$Key
                    }
                }
                $CachedACL[$ConvertedPrincipal]['Permissions'].Add([PSCustomObject] $NewPermission)
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
                        # since it's possible people will differently name their object type name, we are going to convert it to GUID
                        $TypeObjectLeft = Convert-ADSchemaToGuid -SchemaName $CurrentACL.ObjectTypeName -AsString
                        $TypeObjectRight = Convert-ADSchemaToGuid -SchemaName $SetPermission.ObjectTypeName -AsString
                        if ($TypeObjectLeft -eq $TypeObjectRight) {

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
            Write-Verbose "Set-ADACL - Preparing for removal of $($CurrentACL.Principal)"
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
    $AlreadyCovered = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($Principal in $CachedACL.Keys) {
        if ($CachedACL[$Principal]['Action'] -in 'Add', 'Set') {
            foreach ($SetPermission in $CachedACL[$Principal]['Permissions']) {
                $DirectMatch = $false

                foreach ($CurrentACL in $MainAccessRights.ACLAccessRules) {
                    if ($CurrentACL -in $AlreadyCovered) {
                        continue
                    }
                    $RequestedPrincipal = Convert-Identity -Identity $Principal -Verbose:$false

                    if ($CurrentACL.Principal -ne $RequestedPrincipal.Name) {
                        continue
                    }
                    if ($CurrentACL.AccessControlType -eq $SetPermission.AccessControlType) {

                        # since it's possible people will differently name their object type name, we are going to convert it to GUID
                        $TypeObjectLeft = Convert-ADSchemaToGuid -SchemaName $CurrentACL.ObjectTypeName -AsString
                        $TypeObjectRight = Convert-ADSchemaToGuid -SchemaName $SetPermission.ObjectTypeName -AsString
                        if ($TypeObjectLeft -eq $TypeObjectRight) {

                            if ($CurrentACL.ActiveDirectoryRights -eq $SetPermission.ActiveDirectoryRights) {

                                if ($CurrentACL.InheritedObjectTypeName -eq $SetPermission.InheritedObjectTypeName) {

                                    if ($CurrentACL.InheritanceType -eq $SetPermission.InheritanceType) {
                                        $DirectMatch = $true
                                        $AlreadyCovered.Add($CurrentACL)
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