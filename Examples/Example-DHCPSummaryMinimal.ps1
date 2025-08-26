Import-Module .\ADEssentials.psd1 -Force

# Get DHCP validation data using minimal mode (focused on V2 validator requirements)
# This is much faster than full report as it only collects validation-critical data
$Output = Show-WinADDHCPSummary -Minimal -Verbose -FilePath "$PSScriptRoot\Reports\DHCPValidation.html" -PassThru -TestMode -

# To test with real servers (requires appropriate permissions)
# $Output = Show-WinADDHCPSummary -Minimal -Verbose -FilePath "$PSScriptRoot\Reports\DHCPValidation.html" -PassThru

# The $Output variable contains all validation data already categorized:
# - $Output.ScopesWithIssues - All scopes that have validation issues
# - $Output.ValidationResults.CriticalIssues - Public DNS with updates, Servers offline
# - $Output.ValidationResults.WarningIssues - Missing failover, Extended lease duration, DNS record management
# - $Output.ValidationResults.InfoIssues - Missing domain name, Inactive scopes

# Email report using PSWriteHTML patterns
$EmailBody = EmailBody {
    EmailImage -Source 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -UrlLink '' -AlternativeText 'Logo' -Width 181 -Heigh 57 -Inline

    EmailText -Text "Dear ", "Network Team," -LineBreak

    EmailText -Text "DHCP Validation Summary" -Color Blue -FontSize 10pt -FontWeight bold

    # Use data from $Output directly
    $TotalIssues = $Output.ScopesWithIssues.Count
    $CriticalCount = $Output.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count + $Output.ValidationResults.CriticalIssues.ServersOffline.Count
    $WarningCount = $Output.ValidationResults.WarningIssues.MissingFailover.Count + $Output.ValidationResults.WarningIssues.ExtendedLeaseDuration.Count + $Output.ValidationResults.WarningIssues.DNSRecordManagement.Count

    EmailList -FontSize 10pt {
        EmailListItem -Text "Total DHCP Servers: ", $($Output.Servers.Count) -Color None, DodgerBlue -FontWeight normal, bold
        EmailListItem -Text "Total Scopes: ", $($Output.Scopes.Count) -Color None, DodgerBlue -FontWeight normal, bold
        EmailListItem -Text "Scopes with Issues: ", $TotalIssues -Color None, $(if ($TotalIssues -eq 0) { 'LightGreen' } else { 'Salmon' }) -FontWeight normal, bold
        if ($CriticalCount -gt 0) {
            EmailListItem -Text "Critical Issues: ", $CriticalCount -Color None, Red -FontWeight normal, bold
        }
        if ($WarningCount -gt 0) {
            EmailListItem -Text "Warning Issues: ", $WarningCount -Color None, Orange -FontWeight normal, bold
        }
    }

    if ($TotalIssues -gt 0) {
        # Show critical issues first
        if ($Output.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count -gt 0) {
            EmailText -Text "🔴 Critical: Public DNS Servers with Dynamic Updates Enabled" -Color Red -FontWeight bold -LineBreak
            EmailTable -DataTable $Output.ValidationResults.CriticalIssues.PublicDNSWithUpdates {
                EmailTableCondition -Name 'DNSServers' -ComparisonType string -Operator like -Value '*8.8*' -BackGroundColor Salmon -Inline
                EmailTableCondition -Name 'DNSServers' -ComparisonType string -Operator like -Value '*1.1*' -BackGroundColor Salmon -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'DNSServers', 'DynamicUpdates'
            EmailText -LineBreak
        }

        # Show warning issues
        if ($Output.ValidationResults.WarningIssues.ExtendedLeaseDuration.Count -gt 0) {
            EmailText -Text "⚠️ Warning: Extended Lease Duration (>48 hours)" -Color Orange -FontWeight bold -LineBreak
            EmailTable -DataTable $Output.ValidationResults.WarningIssues.ExtendedLeaseDuration {
                EmailTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 168 -BackGroundColor Salmon -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'LeaseDurationHours'
            EmailText -LineBreak
        }

        if ($Output.ValidationResults.WarningIssues.MissingFailover.Count -gt 0) {
            EmailText -Text "⚠️ Warning: Scopes Without Failover Protection" -Color Orange -FontWeight bold -LineBreak
            EmailTable -DataTable $Output.ValidationResults.WarningIssues.MissingFailover -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'State'
        }
    } else {
        EmailText -Text "✅ All DHCP configurations passed validation!" -Color LightGreen -FontWeight bold
    }

    EmailText -LineBreak
    EmailText -Text "Kind regards,"
    EmailText -Text "Your automation friend"
}

Connect-MgGraph -Scopes 'Mail.Send' -NoWelcome

$EmailSplat = @{
    From     = 'przemyslaw.klys@company.pl'
    To       = 'przemyslaw.klys@company.pl'
    Body     = $EmailBody
    Priority = if ($TotalIssues -gt 0) { 'High' } else { 'Low' }
    Subject  = if ($TotalIssues -gt 0) { "DHCP Validation Issues 👎 - $TotalIssues problems found" } else { 'DHCP Validation Results 💖' }
    Verbose  = $true
    WhatIf   = $true
    MgGraph  = $true
}

# Connect-MgGraph -Scopes 'Mail.Send'
Send-EmailMessage @EmailSplat