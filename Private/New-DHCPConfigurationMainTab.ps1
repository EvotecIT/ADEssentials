function New-DHCPConfigurationMainTab {
    <#
    .SYNOPSIS
    Creates the main Configuration tab with nested subtabs for better organization.
    
    .DESCRIPTION
    This private function generates a main Configuration tab that contains nested tabs
    for Options & Classes, Policies, and other configuration-related items.
    
    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.
    
    .PARAMETER IncludeTabs
    Array of tab names to include in the report.
    
    .OUTPUTS
    New-HTMLTab object containing the Configuration tab with nested content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData,
        
        [Parameter(Mandatory = $false)]
        [string[]] $IncludeTabs
    )

    New-HTMLTab -TabName '⚙️ Configuration' {
        New-HTMLTabPanel {
            # Options tab
            if (-not $IncludeTabs -or 'Options&Classes' -in $IncludeTabs) {
                New-DHCPOptionsTab -DHCPData $DHCPData
            }
            
            # Classes tab
            if (-not $IncludeTabs -or 'Options&Classes' -in $IncludeTabs) {
                New-DHCPClassesTab -DHCPData $DHCPData
            }
            
            # Policies tab (if we have policies data)
            if ((-not $IncludeTabs -or 'Policies' -in $IncludeTabs) -and $DHCPData.Policies.Count -gt 0) {
                New-HTMLTab -TabName '📜 Policies' {
                    New-HTMLSection -HeaderText "DHCP Policies Configuration" {
                        New-HTMLTable -DataTable $DHCPData.Policies -Filtering {
                            New-HTMLTableCondition -Name 'Enabled' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'ProcessingOrder' -ComparisonType number -Operator eq -Value 1 -BackgroundColor LightBlue
                        } -DataStore JavaScript -ScrollX -Title "All DHCP Policies"
                    }
                }
            }
            
            # Server Settings tab
            if ((-not $IncludeTabs -or 'ServerSettings' -in $IncludeTabs) -and $DHCPData.ServerSettings.Count -gt 0) {
                New-HTMLTab -TabName '🖥️ Server Settings' {
                    New-HTMLSection -HeaderText "DHCP Server Configuration" {
                        New-HTMLTable -DataTable $DHCPData.ServerSettings -Filtering {
                            New-HTMLTableCondition -Name 'IsAuthorized' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Red -Color White
                            New-HTMLTableCondition -Name 'IsDomainJoined' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Orange
                            New-HTMLTableCondition -Name 'ActivatePolicies' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightGreen -FailBackgroundColor Yellow
                        } -DataStore JavaScript -Title "Server Configuration Settings"
                    }
                }
            }
        }
    }
}