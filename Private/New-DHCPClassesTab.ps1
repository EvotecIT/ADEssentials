function New-DHCPClassesTab {
    <#
    .SYNOPSIS
    Creates the Classes tab content for DHCP HTML report.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][hashtable] $DHCPData)

    New-HTMLTab -TabName '📋 Classes' {
        # Classes Overview
        if ($DHCPData.DHCPClasses.Count -gt 0) {
            New-HTMLSection -HeaderText "📋 DHCP Classes Configuration" {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "DHCP Classes Overview" -FontSize 18pt -FontWeight bold -Color DarkBlue
                    New-HTMLText -Text "DHCP classes allow different configuration based on client type." -FontSize 12pt -Color DarkGray

                    # Summary statistics
                    $VendorClasses = ($DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'Vendor' }).Count
                    $UserClasses = ($DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'User' }).Count
                    $TotalServers = ($DHCPData.DHCPClasses | Group-Object ServerName).Count

                    New-HTMLSection -HeaderText "Classes Summary" -Invisible -Density Compact {
                        New-HTMLInfoCard -Title "Total Classes" -Number $DHCPData.DHCPClasses.Count -Subtitle "Configured" -Icon "📋" -TitleColor Purple -NumberColor DarkMagenta
                        New-HTMLInfoCard -Title "Vendor Classes" -Number $VendorClasses -Subtitle "Device Manufacturers" -Icon "🏭" -TitleColor Blue -NumberColor DarkBlue
                        New-HTMLInfoCard -Title "User Classes" -Number $UserClasses -Subtitle "Custom Categories" -Icon "👥" -TitleColor Green -NumberColor DarkGreen
                        New-HTMLInfoCard -Title "Servers" -Number $TotalServers -Subtitle "With Classes" -Icon "🖥️" -TitleColor Orange -NumberColor DarkOrange
                    }
                }
            }
        }

        # Vendor Classes
        $VendorClassData = $DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'Vendor' }
        if ($VendorClassData.Count -gt 0) {
            New-HTMLSection -HeaderText "🏭 Vendor Classes" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "Vendor classes identify device manufacturers and types" -FontSize 12pt
                    New-HTMLTable -DataTable $VendorClassData -Filtering {
                        New-HTMLTableCondition -Name 'Name' -ComparisonType string -Operator contains -Value 'Microsoft' -BackgroundColor LightYellow -HighlightHeaders 'Name'
                        New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Vendor' -BackgroundColor LightBlue -HighlightHeaders 'Type'
                    } -DataStore JavaScript
                }
            }
        }

        # User Classes
        $UserClassData = $DHCPData.DHCPClasses | Where-Object { $_.Type -eq 'User' }
        if ($UserClassData.Count -gt 0) {
            New-HTMLSection -HeaderText "👥 User Classes" -CanCollapse {
                New-HTMLPanel -Invisible {
                    New-HTMLText -Text "User classes provide custom device categorization" -FontSize 12pt
                    New-HTMLTable -DataTable $UserClassData -Filtering {
                        New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'User' -BackgroundColor LightGreen -HighlightHeaders 'Type'
                    } -DataStore JavaScript
                }
            }
        }

        # All Classes Table
        if ($DHCPData.DHCPClasses.Count -gt 0) {
            New-HTMLSection -HeaderText "📊 All DHCP Classes" -CanCollapse {
                New-HTMLTable -DataTable $DHCPData.DHCPClasses -Filtering {
                    New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'Vendor' -BackgroundColor LightBlue -HighlightHeaders 'Type'
                    New-HTMLTableCondition -Name 'Type' -ComparisonType string -Operator eq -Value 'User' -BackgroundColor LightGreen -HighlightHeaders 'Type'
                    New-HTMLTableCondition -Name 'Name' -ComparisonType string -Operator contains -Value 'Microsoft' -BackgroundColor LightYellow -HighlightHeaders 'Name'
                } -DataStore JavaScript -ScrollX -Title "Complete Classes Configuration"
            }
        } else {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "No DHCP classes configured" -FontSize 14pt -Color Gray
                New-HTMLText -Text "DHCP classes can be used for:" -FontSize 12pt -FontWeight bold
                New-HTMLList {
                    New-HTMLListItem -Text "Different configurations for different device types"
                    New-HTMLListItem -Text "Vendor-specific options (e.g., VoIP phones)"
                    New-HTMLListItem -Text "Custom grouping of devices"
                    New-HTMLListItem -Text "Policy-based option assignment"
                }
            }
        }
    }
}