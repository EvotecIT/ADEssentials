function Get-WinADForestSchemaDetails {
    [CmdletBinding()]
    param(

    )

    $Output = [ordered] @{
        SchemaMaster                    = $null
        SchemaObject                    = $null
        SchemaList                      = $null
        ForestInformation               = $null
        SchemaDefaultPermissions        = [ordered] @{}
        SchemaPermissions               = [ordered] @{}
        SchemaSummaryDefaultPermissions = [ordered] @{}
        SchemaSummaryPermissions        = [ordered] @{}
    }

    $Properties = @(
        "Name"
        "DistinguishedName"
        "CanonicalName"
        "adminDisplayName"
        "lDAPDisplayName"
        "Created"
        "Modified"
        "objectClass"
        "ObjectGUID"
        "ProtectedFromAccidentalDeletion"
        "defaultSecurityDescriptor"
        "NTSecurityDescriptor"
    )
    $ForestInformation = Get-WinADForestDetails -Extended
    $ForestDN = $ForestInformation['DomainsExtended'][$ForestInformation['Forest'].RootDomain].DistinguishedName
    $FindDN = "CN=Schema,CN=Configuration,$ForestDN"
    $SchemaObject = Get-ADObject -Filter * -SearchBase $FindDN -Properties $Properties -ErrorAction SilentlyContinue
    $SchemaFilteredObject = $SchemaObject | Select-Object -Property $Properties -Skip 1
    $Output['SchemaObject'] = $SchemaObject[0]
    $Output['SchemaList'] = $SchemaFilteredObject
    $Output['SchemaMaster'] = $ForestInformation.Forest.SchemaMaster
    $Output['ForestInformation'] = $ForestInformation.Forest
    $Count = 0
    foreach ($Object in $SchemaFilteredObject) {
        $Count++
        Write-Verbose "Get-WinADForestSchemaDetails - Processing [$Count/$($SchemaFilteredObject.Count)] $($Object.DistinguishedName)"
        $Output.SchemaSummaryDefaultPermissions[$Object.Name] = [PSCustomObject] @{
            Name                   = $Object.Name
            CanonicalName          = $Object.CanonicalName
            AdminDisplayName       = $Object.adminDisplayName
            LdapDisplayName        = $Object.lDAPDisplayName
            'PermissionsAvailable' = $false
            'Account Operators'    = @()
            'Administrators'       = @()
            'System'               = @()
            'Authenticated Users'  = @()
            'Domain Admins'        = @()
            'Enterprise Admins'    = @()
            'Schema Admins'        = @()
            'Creator Owner'        = @()
            'Cert Publishers'      = @()
            'Other'                = @()
            DistinguishedName      = $Object.DistinguishedName
        }

        $Output.SchemaSummaryPermissions[$Object.Name] = [PSCustomObject] @{
            Name                          = $Object.Name
            CanonicalName                 = $Object.CanonicalName
            AdminDisplayName              = $Object.adminDisplayName
            LdapDisplayName               = $Object.lDAPDisplayName
            'PermissionsChanged'          = $null
            'DefaultPermissionsAvailable' = $false
            'Account Operators'           = @()
            'Administrators'              = @()
            'System'                      = @()
            'Authenticated Users'         = @()
            'Domain Admins'               = @()
            'Enterprise Admins'           = @()
            'Schema Admins'               = @()
            'Creator Owner'               = @()
            'Cert Publishers'             = @()
            'Other'                       = @()
            DistinguishedName             = $Object.DistinguishedName
        }

        if ($Object.NTSecurityDescriptor) {
            $SecurityDescriptor = Get-ADACL -ADObject $Object -Resolve
            $Output['SchemaPermissions'][$Object.Name] = $SecurityDescriptor
            foreach ($Permission in $SecurityDescriptor) {
                if ($Permission.Principal -eq 'Account Operators') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Account Operators' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Account Operators' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Administrators') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Administrators' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Administrators' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.PrincipalObjectSID -eq 'S-1-5-18') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'System' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'System' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Authenticated Users') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Authenticated Users' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Authenticated Users' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Domain Admins') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Domain Admins' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Domain Admins' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'CREATOR OWNER') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'CREATOR OWNER' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'CREATOR OWNER' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Cert Publishers') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Cert Publishers' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Cert Publishers' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Enterprise Admins') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Enterprise Admins' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Enterprise Admins' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Schema Admins') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Schema Admins' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Schema Admins' += $Permission.ActiveDirectoryRights
                    }
                } else {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Other' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Other' += $Permission.ActiveDirectoryRights
                    }
                }
            }
            if ($Output.SchemaSummaryPermissions[$Object.Name].'Account Operators'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Administrators'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'System'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Authenticated Users'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Domain Admins'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Enterprise Admins'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Schema Admins'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Creator Owner'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Cert Publishers'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Other'.Count -eq 0) {
                $Output.SchemaSummaryPermissions[$Object.Name].'PermissionsChanged' = $false
            } else {
                $Output.SchemaSummaryPermissions[$Object.Name].'PermissionsChanged' = $true
            }
        }
        if ($Object.defaultSecurityDescriptor -and $Object.defaultSecurityDescriptor -ne "D:S:") {
            $SecurityDescriptor = Convert-ADSecurityDescriptor -SDDL $Object.defaultSecurityDescriptor -Resolve -DistinguishedName $Object.DistinguishedName
            $Output['SchemaDefaultPermissions'][$Object.Name] = $SecurityDescriptor
            foreach ($Permission in $SecurityDescriptor) {
                if ($Permission.Principal -eq 'Account Operators') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Account Operators' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Account Operators' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Administrators') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Administrators' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Administrators' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.PrincipalObjectSID -eq 'S-1-5-18') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'System' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'System' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Authenticated Users') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Authenticated Users' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Authenticated Users' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Domain Admins') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Domain Admins' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Domain Admins' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'CREATOR OWNER') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'CREATOR OWNER' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'CREATOR OWNER' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Cert Publishers') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Cert Publishers' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Cert Publishers' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Enterprise Admins') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Enterprise Admins' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Enterprise Admins' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Schema Admins') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Schema Admins' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Schema Admins' += $Permission.ActiveDirectoryRights
                    }
                } else {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Other' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Other' += $Permission.ActiveDirectoryRights
                    }
                }
                $Output.SchemaSummaryDefaultPermissions[$Object.Name].'PermissionsAvailable' = $true
            }
        } else {
            Write-Verbose "Get-WinADForestSchemaDetails - No defaultSecurityDescriptor found for $($Object.DistinguishedName)"
            $Output['SchemaDefaultPermissions'][$Object.Name] = $null
        }
    }
    $Output
}