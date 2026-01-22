Import-Module .\ADEssentials.psd1 -Force

# Policy toggles (applied in Get/Validation; email logic stays minimal)
$ConsiderMissingFailoverCritical = $true
$ConsiderDNSConfigCritical = $true
$IncludeServerAvailabilityIssues = $false
$SendOnCriticalOnly = $true

# Get DHCP validation data (minimal mode)
$Output = Show-WinADDHCPSummary -Minimal -Verbose -FilePath "$PSScriptRoot\Reports\DHCPValidation.html" -PassThru -TestMode -ConsiderMissingFailoverCritical:$ConsiderMissingFailoverCritical -ConsiderDNSConfigCritical:$ConsiderDNSConfigCritical -IncludeServerAvailabilityIssues:$IncludeServerAvailabilityIssues
#return
# Counters
$CriticalCount = $Output.ValidationResults.Summary.TotalCriticalIssues
$WarningCount = $Output.ValidationResults.Summary.TotalWarningIssues
$InfoCount = $Output.ValidationResults.Summary.TotalInfoIssues
$TotalIssues = @($Output.ScopesWithIssues).Count

# Breakdown (counts by category; can overlap per-scope)
$critOnlyOnPrimary   = $Output.ValidationResults.CriticalIssues.FailoverOnlyOnPrimary.Count
$critMissingOnBoth   = $Output.ValidationResults.CriticalIssues.FailoverMissingOnBoth.Count
$critDNSPublic       = $Output.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count
$critDNSConfig       = $Output.ValidationResults.CriticalIssues.DNSConfigurationProblems.Count
$critServersOffline  = $Output.ValidationResults.CriticalIssues.ServersOffline.Count
$warnOnlyOnSecondary = $Output.ValidationResults.WarningIssues.FailoverOnlyOnSecondary.Count
$warnMissingFailover = $Output.ValidationResults.WarningIssues.MissingFailover.Count
$warnLease           = $Output.ValidationResults.WarningIssues.ExtendedLeaseDuration.Count
$warnDNSMgmt         = $Output.ValidationResults.WarningIssues.DNSRecordManagement.Count
$infoMissingDomain   = $Output.ValidationResults.InfoIssues.MissingDomainName.Count

if ($SendOnCriticalOnly -and $CriticalCount -eq 0) {
    Write-Host 'No critical issues detected. Skipping email send.'
    return
}

# Build email
$EmailBody = EmailBody {
    EmailText -Text "Dear ", "Network Team," -LineBreak
    EmailText -Text "DHCP Validation Summary" -Color Blue -FontSize 10pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Total DHCP Servers: ", $($Output.Servers.Count) -Color None, DodgerBlue -FontWeight normal, bold
        EmailListItem -Text "Total Scopes: ", $($Output.Scopes.Count) -Color None, DodgerBlue -FontWeight normal, bold
        if ($CriticalCount -gt 0) { EmailListItem -Text "Critical Issues: ", $CriticalCount -Color None, Red -FontWeight normal, bold }
        if ($WarningCount -gt 0) { EmailListItem -Text "Warning Issues: ", $WarningCount -Color None, DarkOrange -FontWeight normal, bold }
        if ($InfoCount -gt 0) { EmailListItem -Text "Info Issues: ", $InfoCount -Color None, Gray -FontWeight normal, bold }
        EmailListItem -Text "Scopes With Issues (unique): ", $TotalIssues -Color None, Red -FontWeight normal, bold
    }

    EmailText -Text "Issue counts are per-scope and may overlap across categories." -Color DarkGray -FontSize 9pt -LineBreak
    EmailText -Text "Issue Breakdown (where the counts come from):" -Color Blue -FontSize 9pt -FontWeight bold -LineBreak
    EmailList -FontSize 9pt {
        if ($critOnlyOnPrimary -gt 0) { EmailListItem -Text "Critical: Missing on secondary (failover mismatch): ", $critOnlyOnPrimary -Color None, Red -FontWeight normal, bold }
        if ($critMissingOnBoth -gt 0) { EmailListItem -Text "Critical: Missing on both partners: ", $critMissingOnBoth -Color None, Red -FontWeight normal, bold }
        if ($critDNSPublic -gt 0) { EmailListItem -Text "Critical: Public DNS + updates enabled: ", $critDNSPublic -Color None, Red -FontWeight normal, bold }
        if ($critDNSConfig -gt 0) { EmailListItem -Text "Critical: DNS configuration problems (policy): ", $critDNSConfig -Color None, Red -FontWeight normal, bold }
        if ($critServersOffline -gt 0) { EmailListItem -Text "Critical: Offline/unhealthy DHCP servers: ", $critServersOffline -Color None, Red -FontWeight normal, bold }
        if ($warnMissingFailover -gt 0) { EmailListItem -Text "Warning: No failover configured: ", $warnMissingFailover -Color None, DarkOrange -FontWeight normal, bold }
        if ($warnOnlyOnSecondary -gt 0) { EmailListItem -Text "Warning: Missing on primary (failover mismatch): ", $warnOnlyOnSecondary -Color None, DarkOrange -FontWeight normal, bold }
        if ($warnLease -gt 0) { EmailListItem -Text "Warning: Lease duration > 48h: ", $warnLease -Color None, DarkOrange -FontWeight normal, bold }
        if ($warnDNSMgmt -gt 0) { EmailListItem -Text "Warning: DNS record management settings: ", $warnDNSMgmt -Color None, DarkOrange -FontWeight normal, bold }
        if ($infoMissingDomain -gt 0) { EmailListItem -Text "Info: Missing domain name option (015): ", $infoMissingDomain -Color None, Gray -FontWeight normal, bold }
    }

    # Critical: Scopes without failover (treated as critical by policy)
    if ($ConsiderMissingFailoverCritical -and $Output.ValidationResults.WarningIssues.MissingFailover.Count -gt 0) {
        EmailText -Text "🔴 Critical: Scopes Without Failover Protection" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable $Output.ValidationResults.WarningIssues.MissingFailover -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'State'
        EmailText -LineBreak
    }

    # Critical: DNS configuration problems (aggregated)
    if ($ConsiderDNSConfigCritical -and $Output.ValidationResults.CriticalIssues.DNSConfigurationProblems.Count -gt 0) {
        EmailText -Text "🔴 Critical: Scopes with DNS Configuration Problems" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable $Output.ValidationResults.CriticalIssues.DNSConfigurationProblems -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'DNSServers', 'DomainNameOption', 'DynamicUpdates'
        EmailText -LineBreak
    }
}
return
Connect-MgGraph -Scopes 'Mail.Send' -NoWelcome

$EmailSplat = @{
    From     = 'przemyslaw.klys@company.pl'
    To       = 'przemyslaw.klys@company.pl'
    Body     = $EmailBody
    Priority = if ($CriticalCount -gt 0) { 'High' } else { 'Low' }
    Subject  = if ($TotalIssues -gt 0) { "DHCP Validation Issues - $TotalIssues scope(s) (C:$CriticalCount W:$WarningCount I:$InfoCount)" } else { 'DHCP Validation: OK' }
    Verbose  = $true
    WhatIf   = $true
    MgGraph  = $true
}

# Connect-MgGraph -Scopes 'Mail.Send'
Send-EmailMessage @EmailSplat
