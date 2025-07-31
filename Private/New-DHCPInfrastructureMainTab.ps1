function New-DHCPInfrastructureMainTab {
    <#
    .SYNOPSIS
    Creates the main Infrastructure tab with nested subtabs for better organization.
    
    .DESCRIPTION
    This private function generates a main Infrastructure tab that contains nested tabs
    for IPv4/IPv6, Failover, and Network Segmentation.
    
    .PARAMETER DHCPData
    The DHCP data object containing all server and scope information.
    
    .PARAMETER IncludeTabs
    Array of tab names to include in the report.
    
    .OUTPUTS
    New-HTMLTab object containing the Infrastructure tab with nested content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $DHCPData,
        
        [Parameter(Mandatory = $false)]
        [string[]] $IncludeTabs
    )

    New-HTMLTab -TabName '🏗️ Infrastructure' {
        New-HTMLTabPanel {
            # Always show IPv4/IPv6 as it's core infrastructure
            New-DHCPIPv4IPv6Tab -DHCPData $DHCPData
            
            # Failover tab
            if (-not $IncludeTabs -or 'Failover' -in $IncludeTabs) {
                New-DHCPFailoverTab -DHCPData $DHCPData
            }
            
            # Network Segmentation tab
            if (-not $IncludeTabs -or 'NetworkSegmentation' -in $IncludeTabs) {
                New-DHCPNetworkSegmentationTab -DHCPData $DHCPData
            }
            
            # Server Infrastructure tab (simplified from original Infrastructure tab)
            if (-not $IncludeTabs -or 'Infrastructure' -in $IncludeTabs) {
                New-DHCPInfrastructureTab -DHCPData $DHCPData
            }
        }
    }
}