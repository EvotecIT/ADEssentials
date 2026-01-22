Import-Module .\ADEssentials.psd1 -Force

# Example: Everything enabled (critical + warning buckets rendered)
$ConsiderDNSConfigCritical = $true
$ConsiderMissingFailoverCritical = $true   # policy: treat scopes without any failover as critical (count-wise)
$IncludeServerAvailabilityIssues = $true   # include offline/unhealthy servers as critical
$SendOnCriticalOnly = $false  # send even when only warnings exist
$TopN = 200     # limit rows per table for email readability

$ReportPath = Join-Path $PSScriptRoot "Reports/Custom_DHCPServersMinimal_$((Get-Date).ToString('yyyy-MM-dd_HH_mm_ss')).html"

$showWinADDHCPSummarySplat = @{
    Online                          = $true
    Verbose                         = $true
    FilePath                        = $ReportPath
    Minimal                         = $true
    HideHTML                        = $true
    PassThru                        = $true
    IncludeServerAvailabilityIssues = $IncludeServerAvailabilityIssues
    ConsiderDNSConfigCritical       = $ConsiderDNSConfigCritical
    ConsiderMissingFailoverCritical = $ConsiderMissingFailoverCritical
}

$Output = Show-WinADDHCPSummary @showWinADDHCPSummarySplat

return
# Counters
$CriticalCount = $Output.ValidationResults.Summary.TotalCriticalIssues
$WarningCount = $Output.ValidationResults.Summary.TotalWarningIssues
$InfoCount = $Output.ValidationResults.Summary.TotalInfoIssues
$TotalIssues = @($Output.ScopesWithIssues).Count
if ($SendOnCriticalOnly -and $CriticalCount -eq 0) {
    Write-Host 'No critical issues detected. Skipping email send.'
    return
}

# Buckets
$critOnlyOnPrimary = $Output.ValidationResults.CriticalIssues.FailoverOnlyOnPrimary
$critMissingOnBoth = $Output.ValidationResults.CriticalIssues.FailoverMissingOnBoth
$critDNSPublic = $Output.ValidationResults.CriticalIssues.PublicDNSWithUpdates
$critDNSProblems = $Output.ValidationResults.CriticalIssues.DNSConfigurationProblems
$critServersOffline = $Output.ValidationResults.CriticalIssues.ServersOffline
$polMissingFailover = $Output.ValidationResults.WarningIssues.MissingFailover   # list stays under WarningIssues; policy elevates counts

$warnOnlyOnSecondary = $Output.ValidationResults.WarningIssues.FailoverOnlyOnSecondary
$warnLease = $Output.ValidationResults.WarningIssues.ExtendedLeaseDuration
$warnDNSMgmt = $Output.ValidationResults.WarningIssues.DNSRecordManagement
$infoMissingDomain = $Output.ValidationResults.InfoIssues.MissingDomainName

# Build email
$EmailBody = EmailBody {
    EmailText -Text "Dear ", "Network Team," -LineBreak
    EmailText -Text "DHCP Validation Summary" -Color Blue -FontSize 10pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Total DHCP Servers: ", $($Output.Servers.Count) -Color None, DodgerBlue -FontWeight normal, bold
        EmailListItem -Text "Total Scopes: ", $($Output.Scopes.Count) -Color None, DodgerBlue -FontWeight normal, bold
        if ($CriticalCount -gt 0) {
            EmailListItem -Text "Critical Issues: ", $CriticalCount -Color None, Red -FontWeight normal, bold
        }
        if ($WarningCount -gt 0) {
            EmailListItem -Text "Warning Issues: ", $WarningCount -Color None, DarkOrange -FontWeight normal, bold
        }
        if ($InfoCount -gt 0) {
            EmailListItem -Text "Info Issues: ", $InfoCount -Color None, Gray -FontWeight normal, bold
        }
        EmailListItem -Text "Scopes With Issues (unique): ", $TotalIssues -Color None, Red -FontWeight normal, bold
    }

    EmailText -Text "Issue counts are per-scope and may overlap across categories." -Color DarkGray -FontSize 9pt -LineBreak
    EmailText -Text "Issue Breakdown (where the counts come from):" -Color Blue -FontSize 9pt -FontWeight bold -LineBreak
    EmailList -FontSize 9pt {
        if ($critOnlyOnPrimary.Count -gt 0) { EmailListItem -Text "Critical: Missing on secondary (failover mismatch): ", $critOnlyOnPrimary.Count -Color None, Red -FontWeight normal, bold }
        if ($critMissingOnBoth.Count -gt 0) { EmailListItem -Text "Critical: Missing on both partners: ", $critMissingOnBoth.Count -Color None, Red -FontWeight normal, bold }
        if ($critDNSPublic.Count -gt 0) { EmailListItem -Text "Critical: Public DNS + updates enabled: ", $critDNSPublic.Count -Color None, Red -FontWeight normal, bold }
        if ($critDNSProblems.Count -gt 0) { EmailListItem -Text "Critical: DNS configuration problems (policy): ", $critDNSProblems.Count -Color None, Red -FontWeight normal, bold }
        if ($critServersOffline.Count -gt 0) { EmailListItem -Text "Critical: Offline/unhealthy DHCP servers: ", $critServersOffline.Count -Color None, Red -FontWeight normal, bold }
        if ($polMissingFailover.Count -gt 0) { EmailListItem -Text "Warning/Policy: No failover configured: ", $polMissingFailover.Count -Color None, DarkOrange -FontWeight normal, bold }
        if ($warnOnlyOnSecondary.Count -gt 0) { EmailListItem -Text "Warning: Missing on primary (failover mismatch): ", $warnOnlyOnSecondary.Count -Color None, DarkOrange -FontWeight normal, bold }
        if ($warnLease.Count -gt 0) { EmailListItem -Text "Warning: Lease duration > 48h: ", $warnLease.Count -Color None, DarkOrange -FontWeight normal, bold }
        if ($warnDNSMgmt.Count -gt 0) { EmailListItem -Text "Warning: DNS record management settings: ", $warnDNSMgmt.Count -Color None, DarkOrange -FontWeight normal, bold }
        if ($infoMissingDomain.Count -gt 0) { EmailListItem -Text "Info: Missing domain name option (015): ", $infoMissingDomain.Count -Color None, Gray -FontWeight normal, bold }
    }

    if ($critOnlyOnPrimary.Count -gt 0) {
        EmailText -Text "🔴 Critical: Scopes present only on primary (missing on secondary)" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable ($critOnlyOnPrimary | Select-Object -First $TopN) -HideFooter -IncludeProperty 'Relationship', 'PrimaryServer', 'SecondaryServer', 'ScopeId'
        EmailText -LineBreak
    }
    if ($critMissingOnBoth.Count -gt 0) {
        EmailText -Text "🔴 Critical: Scopes missing from failover on both partners" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable ($critMissingOnBoth | Select-Object -First $TopN) -HideFooter -IncludeProperty 'Relationship', 'PrimaryServer', 'SecondaryServer', 'ScopeId'
        EmailText -LineBreak
    }
    if ($ConsiderDNSConfigCritical -and $critDNSProblems.Count -gt 0) {
        EmailText -Text "🔴 Critical: DNS Configuration Problems" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable ($critDNSProblems | Select-Object -First $TopN) -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'DNSServers', 'DomainNameOption', 'DynamicUpdates'
        EmailText -LineBreak
    }
    if ($IncludeServerAvailabilityIssues -and $critServersOffline.Count -gt 0) {
        EmailText -Text "🔴 Critical: Offline/Unhealthy DHCP Servers" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable ($critServersOffline | Select-Object -First $TopN) -HideFooter -IncludeProperty 'ServerName', 'Status', 'ErrorMessage'
        EmailText -LineBreak
    }
    if ($ConsiderMissingFailoverCritical -and $polMissingFailover.Count -gt 0) {
        EmailText -Text "🔴 Critical (policy): Scopes Without Failover Protection" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable ($polMissingFailover | Select-Object -First $TopN) -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'State'
        EmailText -LineBreak
    }

    if ($warnOnlyOnSecondary.Count -gt 0) {
        EmailText -Text "🟠 Warning: Scopes present only on secondary (missing on primary)" -Color DarkOrange -FontWeight bold -LineBreak
        EmailTable -DataTable ($warnOnlyOnSecondary | Select-Object -First $TopN) -HideFooter -IncludeProperty 'Relationship', 'PrimaryServer', 'SecondaryServer', 'ScopeId'
        EmailText -LineBreak
    }
    if ($warnLease.Count -gt 0) {
        EmailText -Text "🟠 Warning: Extended Lease Duration (>48h)" -Color DarkOrange -FontWeight bold -LineBreak
        EmailTable -DataTable ($warnLease | Select-Object -First $TopN) -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'LeaseDurationHours'
        EmailText -LineBreak
    }
    if ($warnDNSMgmt.Count -gt 0) {
        EmailText -Text "🟠 Warning: DNS Record Management Settings" -Color DarkOrange -FontWeight bold -LineBreak
        EmailTable -DataTable ($warnDNSMgmt | Select-Object -First $TopN) -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'UpdateDnsRRForOlderClients', 'DeleteDnsRROnLeaseExpiry'
        EmailText -LineBreak
    }
}

# Example sending via Graph in WhatIf
try {
    Connect-MgGraph -Scopes 'Mail.Send' -NoWelcome -ErrorAction Stop
} catch {

}

$EmailSplat = @{
    From     = 'przemyslaw.klys@company.pl'
    To       = 'network-team@company.pl'
    Body     = $EmailBody
    Priority = if ($CriticalCount -gt 0) { 'High' } else { 'Normal' }
    Subject  = if ($TotalIssues -gt 0) { "DHCP Validation Issues - $TotalIssues scope(s) (C:$CriticalCount W:$WarningCount I:$InfoCount)" } else { "DHCP Validation: OK" }
    Verbose  = $true
    WhatIf   = $true
    MgGraph  = $true
}

Send-EmailMessage @EmailSplat

