$Script:ConfigurationLAPSACL = [ordered] @{
    Name       = 'LAPS ACL'
    Enabled    = $true
    Execute    = {
        Get-WinADComputerACLLAPS -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains
    }
    Processing = {

    }
    Summary    = {
        New-HTMLText -Text @(
            "This report focuses on detecting whether computer has ability to read/write to LAPS properties in Active Directory. "
            "Often for many reasons such as broken ACL inheritance or not fully implemented SELF write access to LAPS - LAPS is implemented only partially. "
            "This means while IT may be thinking that LAPS should be functioning properly - the computer itself may not have rights to write password back to AD, making LAPS not functional. "

        ) -FontSize 10pt -LineBreak
        New-HTMLText -Text "Following computer resources are exempt from LAPS: " -FontSize 10pt
        New-HTMLList {
            New-HTMLListItem -Text "Domain Controllers and Read Only Domain Controllers"
            New-HTMLListItem -Text 'Computer Service accounts such as AZUREADSSOACC$'
        } -FontSize 10pt
        New-HTMLText -Text 'Everything else should have proper LAPS ACL for the computer to provide data.' -FontSize 10pt
    }
    Variables  = @{

    }
    Solution   = {
        New-HTMLSection -Invisible {
            New-HTMLPanel {
                $Script:Reporting['LAPSACL']['Summary']
            }
            New-HTMLPanel {
                <#
                New-HTMLChart {
                    New-ChartBarOptions -Type barStacked
                    New-ChartLegend -Name 'Yes', 'No' -Color SpringGreen, Salmon
                    New-ChartBar -Name 'Authenticated Users Available' -Value $Script:Reporting['GPOPermissionsRead']['Variables']['WillNotTouch'], $Script:Reporting['GPOPermissionsRead']['Variables']['WillFix']
                    New-ChartBar -Name 'Accessible Group Policies' -Value $Script:Reporting['GPOPermissionsRead']['Variables']['Read'], $Script:Reporting['GPOPermissionsRead']['Variables']['CouldNotRead']
                } -Title 'Group Policy Permissions' -TitleAlignment center
                #>
            }
        }
        if ($Script:Reporting['LAPSACL']['Data']) {
            New-HTMLSection -Name 'LAPS ACL Summary' {
                New-HTMLTable -DataTable $Script:Reporting['LAPSACL']['Data'] -Filtering {
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'LapsACL' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'LapsExpirationACL' -ComparisonType string -Operator eq -Value $true
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false
                    } -BackgroundColor LimeGreen -HighlightHeaders LapsACL, LapsExpirationACL
                    New-HTMLTableConditionGroup -Logic AND {
                        New-HTMLTableCondition -Name 'LapsACL' -ComparisonType string -Operator eq -Value $false
                        New-HTMLTableCondition -Name 'LapsExpirationACL' -ComparisonType string -Operator eq -Value $false
                        New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false
                    } -BackgroundColor Alizarin -HighlightHeaders LapsACL, LapsExpirationACL
                    New-HTMLTableCondition -Name 'Enabled' -ComparisonType string -Operator eq -Value $true -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $false -BackgroundColor LimeGreen -FailBackgroundColor BlizzardBlue
                    New-HTMLTableCondition -Name 'IsDC' -ComparisonType string -Operator eq -Value $true -BackgroundColor BlizzardBlue -HighlightHeaders LapsACL, LapsExpirationACL

                }
            }
            if ($Script:Reporting['LAPSACL']['WarningsAndErrors']) {
                New-HTMLSection -Name 'Warnings & Errors to Review' {
                    New-HTMLTable -DataTable $Script:Reporting['LAPSACL']['WarningsAndErrors'] -Filtering {
                        New-HTMLTableCondition -Name 'Type' -Value 'Warning' -BackgroundColor SandyBrown -ComparisonType string -Row
                        New-HTMLTableCondition -Name 'Type' -Value 'Error' -BackgroundColor Salmon -ComparisonType string -Row
                    } -PagingOptions 10, 20, 30, 40, 50
                }
            }
        }
    }
}