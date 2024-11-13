$Script:ConfigurationSchema = [ordered] @{
    Name       = 'Schema Information'
    Enabled    = $true
    Execute    = {
        Get-WinADForestSchemaDetails
    }
    Processing = {
        # foreach ($PasswordPolicy in $Script:Reporting['PasswordPolicies']['Data']) {
        #     if ($PasswordPolicy.Name -eq 'Default Password Policy') {
        #         $Script:Reporting['PasswordPolicies']['Variables'].DefaultPasswordPolicy += 1
        #     } else {
        #         $Script:Reporting['PasswordPolicies']['Variables'].FineGrainedPasswordPolicies += 1
        #     }
        # }
    }
    Summary    = {
        New-HTMLPanel {
            New-HTMLText -Text @(
                "This report focuses on showing all Default Schema Permissions in Active Directory forest. "
                # "It shows default password policies and fine grained password policies. "
                # "Keep in mind that there can only be one valid Default Password Policy per domain. "
                # "If you have multiple password policies defined (that are not FGPP), only one will work, the one with the lowest precedence on the Domain Controller OU."
                # "Any other Password Policy that you defined will not be shown here."
                # "If you are not seeing FGPP password policies and you have them defined, make sure that you have extended rights to read them."
            ) -FontSize 10pt
            New-HTMLList {
                New-HTMLListItem -Text "Schema List: ", "shows all Schema objects in the forest" -Color None, BlueDiamond -FontWeight normal, bold
                New-HTMLListItem -Text "Schema Permissions: ", "shows all Schema Permissions in the forest" -Color None, BlueDiamond -FontWeight normal, bold
                New-HTMLListItem -Text "Schema Default Permissions: ", "shows all Schema Default Permissions in the forest for specific objects" -Color None, BlueDiamond -FontWeight normal, bold
            } -FontSize 10pt
            New-HTMLText -Text @(
                "This is supposed to tell you who can modify the Schema in your forest, but also who can create/modify/delete specific objects once they are created."
            ) -FontSize 10pt
        }
        New-HTMLPanel {
            New-HTMLText -Text "Forest Information" -FontSize 10pt
            New-HTMLList {
                New-HTMLListItem -Text "Forest Name: ", $Script:Reporting['Schema']['Data'].ForestInformation.Name -Color None, BlueDiamond -FontWeight normal, bold
                New-HTMLListItem -Text "Forest Domain (s): ", ($Script:Reporting['Schema']['Data'].ForestInformation.Domains -join ", ") -Color None, BlueDiamond -FontWeight normal, bold
                New-HTMLListItem -Text "Forest Level: ", $Script:Reporting['Schema']['Data'].ForestInformation.ForestMode -Color None, BlueDiamond -FontWeight normal, bold
                New-HTMLListItem -Text "Schema Master: ", $Script:Reporting['Schema']['Data'].ForestInformation.SchemaMaster -Color None, BlueDiamond -FontWeight normal, bold
                New-HTMLListItem -Text "Schema DistinguishedName: ", $Script:Reporting['Schema']['Data'].SchemaObject.DistinguishedName -Color None, BlueDiamond -FontWeight normal, bold
            } -FontSize 10pt
        }
    }
    Variables  = @{

    }
    Solution   = {
        if ($Script:Reporting['Schema']['Data']) {
            New-HTMLSection -Invisible {
                $Script:Reporting['Schema']['Summary']
            }
            New-HTMLTabPanel {
                New-HTMLTab -Name "Schema List" {
                    New-HTMLTable -DataTable $Script:Reporting['Schema']['Data'].SchemaList -Filtering {

                    } -ScrollX -PagingLength 15 -DataTableID 'SchemaList' -ExcludeProperty NTSecurityDescriptor -PagingOptions 5, 7, 10, 15, 20, 25, 50, 100

                }
                New-HTMLTab -Name "Schema Owners" {
                    New-HTMLTable -DataTable $Script:Reporting['Schema']['Data'].SchemaOwners.Values -Filtering {

                    } -ScrollX -PagingLength 15 -DataTableID 'SchemaOwners' -PagingOptions 5, 7, 10, 15, 20, 25, 50, 100
                }
                New-HTMLTab -Name "Schema Permissions" {
                    New-HTMLSection -HeaderText 'Summary' {
                        New-HTMLTable -DataTable $Script:Reporting['Schema']['Data'].SchemaSummaryPermissions.Values -Filtering {
                            New-TableEvent -ID 'SchemaPermissions' -SourceColumnID 17 -TargetColumnID 0
                            New-HTMLTableCondition -Name 'PermissionsChanged' -ComparisonType string -Operator eq -Value $true -BackgroundColor Salmon -FailBackgroundColor LightGreen
                            New-HTMLTableCondition -Name 'DefaultPermissionsAvailable' -ComparisonType string -Operator eq -Value $true -BackgroundColor MoonYellow
                        } -ScrollX -PagingLength 7 -DataTableID 'SchemaSummaryPermission' -PagingOptions 5, 7, 10, 15, 20, 25, 50, 100
                    }
                    New-HTMLSection -HeaderText 'Details' {
                        # Remove empty values
                        $FilteredData = $Script:Reporting['Schema']['Data'].SchemaPermissions.Values | ForEach-Object { if ($_) { $_ } }
                        New-HTMLTable -DataTable $FilteredData -Filtering {
                            New-HTMLTableCondition -Name 'AccessControlType' -ComparisonType string -Operator eq -Value 'Allow' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        } -ScrollX -PagingLength 7 -DataTableID 'SchemaPermissions' -PagingOptions 5, 7, 10, 15, 20, 25, 50, 100
                    }
                }
                New-HTMLTab -Name "Schema Default Permissions" {
                    New-HTMLSection -HeaderText 'Summary' {
                        New-HTMLTable -DataTable $Script:Reporting['Schema']['Data'].SchemaSummaryDefaultPermissions.Values -Filtering {
                            New-TableEvent -ID 'SchemaDefaultPermissions' -SourceColumnID 16 -TargetColumnID 0
                            New-HTMLTableCondition -Name 'PermissionsAvailable' -ComparisonType string -Operator eq -Value $true -BackgroundColor MoonYellow
                        } -ScrollX -PagingLength 7 -DataTableID 'SchemaSummary' -PagingOptions 5, 7, 10, 15, 20, 25, 50, 100
                    }
                    New-HTMLSection -HeaderText 'Details' {
                        # Remove empty values
                        $FilteredData = $Script:Reporting['Schema']['Data'].SchemaDefaultPermissions.Values | ForEach-Object { if ($_) { $_ } }
                        New-HTMLTable -DataTable $FilteredData -Filtering {
                            New-HTMLTableCondition -Name 'AccessControlType' -ComparisonType string -Operator eq -Value 'Allow' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                        } -ScrollX -PagingLength 7 -DataTableID 'SchemaDefaultPermissions' -PagingOptions 5, 7, 10, 15, 20, 25, 50, 100
                    }
                }
            }
        }
    }
}