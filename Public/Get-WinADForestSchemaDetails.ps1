function Get-WinADForestSchemaDetails {
    <#
    .SYNOPSIS
    Gets detailed information about Active Directory forest schema including security permissions.

    .DESCRIPTION
    This function retrieves comprehensive information about the Active Directory forest schema, including:
    - Schema master information
    - Schema object details
    - Schema attributes and their properties
    - Security permissions (both current and default) for schema objects
    - Permission differences from default settings
    - Schema object owners

    .PARAMETER None
    This function does not accept any parameters.

    .OUTPUTS
    Returns a hashtable containing:
    - SchemaMaster: The domain controller that holds the Schema Master FSMO role
    - SchemaObject: Details of the Schema container object
    - SchemaList: List of all schema objects and their attributes
    - ForestInformation: General forest details
    - SchemaDefaultPermissions: Default security permissions for schema objects
    - SchemaPermissions: Current security permissions for schema objects
    - SchemaSummaryDefaultPermissions: Summarized default permissions by principal
    - SchemaSummaryPermissions: Summarized current permissions by principal
    - SchemaOwners: Owners of schema objects

    .EXAMPLE
    $SchemaDetails = Get-WinADForestSchemaDetails
    Gets all schema details and permissions for the current forest

    .EXAMPLE
    $SchemaDetails = Get-WinADForestSchemaDetails | Select-Object -ExpandProperty SchemaList
    Gets just the list of schema objects and their attributes

    .NOTES
    Requires Active Directory PowerShell module
    Requires Schema Admin permissions to view some details
    Can be resource intensive in large environments
    #>
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
        SchemaOwners                    = [ordered] @{}
    }
    $Today = Get-Date
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
        "attributeID"
        "attributeSyntax"
        "isSingleValued"
        "adminDescription"
        "omSyntax"
        "searchFlags"
        "systemOnly"
        "showInAdvancedViewOnly"
        "schemaIDGUID"
        "attributeSecurityGUID"
        "CN"
    )
    $ForestInformation = Get-WinADForestDetails -Extended
    $ForestDN = $ForestInformation['DomainsExtended'][$ForestInformation['Forest'].RootDomain].DistinguishedName
    $FindDN = "CN=Schema,CN=Configuration,$ForestDN"
    $SchemaObject = Get-ADObject -Filter * -SearchBase $FindDN -Properties $Properties -ErrorAction SilentlyContinue
    $Count = 0
    $SchemaFilteredObject = $SchemaObject | ForEach-Object {
        # Skip the first object as it is the schema object itself
        if ($Count -eq 0) { $Count++; return }

        # Convert GUIDs from byte arrays
        $SchemaIdGuid = if ($_."schemaIDGUID") { [System.Guid]::new($_."schemaIDGUID").ToString() } else { $null } # ConvertFrom-ADSchemaGUID
        $AttributeSecurityGuid = if ($_."attributeSecurityGUID") { [System.Guid]::new($_."attributeSecurityGUID").ToString() } else { $null } # ConvertFrom-ADSchemaGUID
        $AttributeSecurityGuidBase64 = if ($_."attributeSecurityGUID") { [Convert]::ToBase64String($_."attributeSecurityGUID") } else { $null } # ConvertTo-Base64

        [PSCustomObject] @{
            "Name"                            = $_."Name"
            "DistinguishedName"               = $_."DistinguishedName"
            "CanonicalName"                   = $_."CanonicalName"
            "Created"                         = $_."Created"
            "CreatedDaysAgo"                  = if ($_.Created) { (New-TimeSpan -Start $_."Created" -End $Today).Days } else { $null }
            "Modified"                        = $_."Modified"
            "ModifiedDaysAgo"                 = if ($_.Modified) { (New-TimeSpan -Start $_."Modified" -End $Today).Days } else { $null }
            "objectClass"                     = $_."objectClass"
            "ObjectGUID"                      = $_."ObjectGUID"
            "ProtectedFromAccidentalDeletion" = $_."ProtectedFromAccidentalDeletion"
            "defaultSecurityDescriptor"       = $_."defaultSecurityDescriptor"
            "NTSecurityDescriptor"            = $_."NTSecurityDescriptor"
            "CN"                              = $_."CN"
            "attributeID"                     = $_."attributeID"
            "attributeSyntax"                 = $_."attributeSyntax"
            "isSingleValued"                  = $_."isSingleValued"
            "adminDisplayName"                = $_."adminDisplayName"
            "lDAPDisplayName"                 = $_."lDAPDisplayName"
            "adminDescription"                = $_."adminDescription"
            "omSyntax"                        = $_."omSyntax"
            "searchFlags"                     = $_."searchFlags"
            "systemOnly"                      = $_."systemOnly"
            "showInAdvancedViewOnly"          = $_."showInAdvancedViewOnly"
            "attributeSecurityGUID"           = $AttributeSecurityGuid
            "attributeSecurityGUIDBase64"     = $AttributeSecurityGuidBase64
            "schemaIDGUID"                    = $SchemaIdGuid
        }
    }
    $Output['SchemaObject'] = $SchemaObject[0]
    $Output['SchemaList'] = $SchemaFilteredObject
    $Output['SchemaMaster'] = $ForestInformation.Forest.SchemaMaster
    $Output['ForestInformation'] = $ForestInformation.Forest
    $Count = 0
    foreach ($Object in $SchemaFilteredObject) {
        $Count++
        Write-Verbose "Get-WinADForestSchemaDetails - Processing [$Count/$($SchemaFilteredObject.Count)] $($Object.DistinguishedName)"
        $Output.SchemaSummaryDefaultPermissions[$Object.Name] = [PSCustomObject] @{
            Name                            = $Object.Name
            CanonicalName                   = $Object.CanonicalName
            AdminDisplayName                = $Object.adminDisplayName
            LdapDisplayName                 = $Object.lDAPDisplayName
            'PermissionsAvailable'          = $false
            'Account Operators'             = @()
            'Administrators'                = @()
            'System'                        = @()
            'Authenticated Users'           = @()
            'Domain Admins'                 = @()
            'Enterprise Admins'             = @()
            'Enterprise Domain Controllers' = @()
            'Schema Admins'                 = @()
            'Creator Owner'                 = @()
            'Cert Publishers'               = @()
            'Other'                         = @()
            DistinguishedName               = $Object.DistinguishedName
        }

        $Output.SchemaSummaryPermissions[$Object.Name] = [PSCustomObject] @{
            Name                            = $Object.Name
            CanonicalName                   = $Object.CanonicalName
            AdminDisplayName                = $Object.adminDisplayName
            LdapDisplayName                 = $Object.lDAPDisplayName
            'PermissionsChanged'            = $null
            'DefaultPermissionsAvailable'   = $false
            'Account Operators'             = @()
            'Administrators'                = @()
            'System'                        = @()
            'Authenticated Users'           = @()
            'Domain Admins'                 = @()
            'Enterprise Admins'             = @()
            'Enterprise Domain Controllers' = @()
            'Schema Admins'                 = @()
            'Creator Owner'                 = @()
            'Cert Publishers'               = @()
            'Other'                         = @()
            DistinguishedName               = $Object.DistinguishedName
        }

        if ($Object.NTSecurityDescriptor) {
            $SecurityDescriptor = Get-ADACL -ADObject $Object -Resolve
            $Owner = Get-ADACLOwner -ADObject $Object.DistinguishedName -Resolve
            $Output['SchemaOwners'][$Object.Name] = [PSCustomObject] @{
                Name              = $Object.Name
                CanonicalName     = $Object.CanonicalName
                AdminDisplayName  = $Object.adminDisplayName
                LdapDisplayName   = $Object.lDAPDisplayName
                Owner             = $Owner.Owner
                OwnerType         = $Owner.OwnerType
                OwnerSID          = $Owner.OwnerSID
                Error             = $Owner.Error
                DistinguishedName = $Object.DistinguishedName
            }
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
                } elseif ($Permission.Principal -eq 'Enterprise Domain Controllers') {
                    if ($Output.SchemaSummaryPermissions[$Object.Name].'Enterprise Domain Controllers' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryPermissions[$Object.Name].'Enterprise Domain Controllers' += $Permission.ActiveDirectoryRights
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
            $SchemaAdminsList = $Output.SchemaSummaryPermissions[$Object.Name].'Schema Admins' -split ", "
            $SchemaAdminsExpected = 'CreateChild', 'Self', 'WriteProperty', 'ExtendedRight', 'GenericRead', 'WriteDacl', 'WriteOwner'

            $Compare = Compare-Object -ReferenceObject $SchemaAdminsList -DifferenceObject $SchemaAdminsExpected
            $CompareResult = $Compare.SideIndicator -contains '=>' -or $Compare.SideIndicator -contains '<='
            $CompareCount = $SchemaAdminsExpected.Count -eq $SchemaAdminsList.Count
            if ($Output.SchemaSummaryPermissions[$Object.Name].'Account Operators'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Administrators'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'System'.Count -gt 0 -and $Output.SchemaSummaryPermissions[$Object.Name].'System'[0] -eq 'GenericAll' -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Authenticated Users'.Count -gt 0 -and $Output.SchemaSummaryPermissions[$Object.Name].'Authenticated Users'[0] -eq 'GenericRead' -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Domain Admins'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Enterprise Admins'.Count -eq 0 -and
                $CompareResult -eq $false -and $CompareCount -eq $true -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Creator Owner'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Cert Publishers'.Count -eq 0 -and
                $Output.SchemaSummaryPermissions[$Object.Name].'Other'.Count -eq 0) {
                $Output.SchemaSummaryPermissions[$Object.Name].'PermissionsChanged' = $false
            } else {
                $Output.SchemaSummaryPermissions[$Object.Name].'PermissionsChanged' = $true
            }
        }
        if ($Object.defaultSecurityDescriptor -and $Object.defaultSecurityDescriptor -ne "D:S:") {
            $Output.SchemaSummaryPermissions[$Object.Name].'DefaultPermissionsAvailable' = $true

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
                } elseif ($Permission.Principal -eq 'Enterprise Domain Controllers') {
                    if ($Output.SchemaSummaryDefaultPermissions[$Object.Name].'Enterprise Domain Controllers' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummaryDefaultPermissions[$Object.Name].'Enterprise Domain Controllers' += $Permission.ActiveDirectoryRights
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