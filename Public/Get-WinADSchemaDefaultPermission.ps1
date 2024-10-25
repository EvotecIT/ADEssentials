function Get-WinADSchemaDefaultPermission {
    [CmdletBinding()]
    param(

    )

    $Output = [ordered] @{
        SchemaList        = $null
        SchemaPermissions = [ordered] @{}
        SchemaSummary     = [ordered] @{}
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
    )
    $ForestInformation = Get-WinADForestDetails -Extended
    $ForestDN = $ForestInformation['DomainsExtended'][$ForestInformation['Forest'].RootDomain].DistinguishedName
    $FindDN = "CN=Schema,CN=Configuration,$ForestDN"
    $SchemaObject = Get-ADObject -Filter * -SearchBase $FindDN -Properties $Properties -ErrorAction SilentlyContinue | Select-Object -Property $Properties -Skip 1
    $Output['SchemaList'] = $SchemaObject
    $Count = 0
    foreach ($Object in $SchemaObject) {
        $Count++
        Write-Verbose "Get-WinADSchemaDefaultPermission - Processing [$Count/$($SchemaObject.Count)] $($Object.DistinguishedName)"
        if ($Object.defaultSecurityDescriptor -and $Object.defaultSecurityDescriptor -ne "D:S:") {
            $SecurityDescriptor = Convert-ADSecurityDescriptor -SDDL $Object.defaultSecurityDescriptor -Resolve -DistinguishedName $Object.DistinguishedName
            $Output['SchemaPermissions'][$Object.Name] = $SecurityDescriptor

            $Output.SchemaSummary[$Object.Name] = [PSCustomObject] @{
                Name                  = $Object.Name
                CanonicalName         = $Object.CanonicalName
                AdminDisplayName      = $Object.adminDisplayName
                LdapDisplayName       = $Object.lDAPDisplayName

                'Account Operators'   = @()
                'Administrators'      = @()
                'System'              = @()
                'Authenticated Users' = @()
                'Domain Admins'       = @()
                'Creator Owner'       = @()
                'Cert Publishers'     = @()
                'Other'               = @()
                DistinguishedName     = $Object.DistinguishedName
            }
            foreach ($Permission in $SecurityDescriptor) {
                if ($Permission.Principal -eq 'Account Operators') {
                    if ($Output.SchemaSummary[$Object.Name].'Account Operators' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'Account Operators' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Administrators') {
                    if ($Output.SchemaSummary[$Object.Name].'Administrators' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'Administrators' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'System') {
                    if ($Output.SchemaSummary[$Object.Name].'System' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'System' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Authenticated Users') {
                    if ($Output.SchemaSummary[$Object.Name].'Authenticated Users' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'Authenticated Users' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Domain Admins') {
                    if ($Output.SchemaSummary[$Object.Name].'Domain Admins' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'Domain Admins' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'CREATOR OWNER') {
                    if ($Output.SchemaSummary[$Object.Name].'CREATOR OWNER' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'CREATOR OWNER' += $Permission.ActiveDirectoryRights
                    }
                } elseif ($Permission.Principal -eq 'Cert Publishers') {
                    if ($Output.SchemaSummary[$Object.Name].'Cert Publishers' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'Cert Publishers' += $Permission.ActiveDirectoryRights
                    }
                } else {
                    if ($Output.SchemaSummary[$Object.Name].'Other' -notcontains $Permission.ActiveDirectoryRights) {
                        $Output.SchemaSummary[$Object.Name].'Other' += $Permission.ActiveDirectoryRights
                    }
                }
            }

        } else {
            Write-Verbose "Get-WinADSchemaDefaultPermission - No defaultSecurityDescriptor found for $($Object.DistinguishedName)"
            $Output['SchemaPermissions'][$Object.Name] = $null
        }
    }
    $Output
}