Import-Module .\ADEssentials.psd1 -Force

# Example: Failover-only mapping
# Critical = missing on one partner or missing on both partners
$ConsiderDNSConfigCritical = $false  # do not escalate DNS into critical
$ConsiderMissingFailoverCritical = $false  # do not escalate scopes-without-any-failover into critical
$IncludeServerAvailabilityIssues = $false  # keep server availability out of critical
$SendOnCriticalOnly = $true
$TopN = 200

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

# Counters
$CriticalCount = $Output.ValidationResults.Summary.TotalCriticalIssues
$WarningCount = $Output.ValidationResults.Summary.TotalWarningIssues
$InfoCount = $Output.ValidationResults.Summary.TotalInfoIssues
$TotalIssues = $Output.ValidationResults.Summary.UniqueScopesWithIssues
if ($SendOnCriticalOnly -and $CriticalCount -eq 0) {
    Write-Host 'No critical issues detected. Skipping email send.'
    return
}

return
# Buckets (failover focused)
$critMissingOnOnePartner = $Output.ValidationResults.CriticalIssues.FailoverMissingOnOnePartner
$critMissingOnBoth = $Output.ValidationResults.CriticalIssues.FailoverMissingOnBoth
$warnFailoverUnverified = $Output.ValidationResults.WarningIssues.FailoverUnverified

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
    EmailText -Text "Issue Breakdown (failover-focused):" -Color Blue -FontSize 9pt -FontWeight bold -LineBreak
    EmailList -FontSize 9pt {
        if ($critMissingOnOnePartner.Count -gt 0) { EmailListItem -Text "Critical: Missing on one partner (failover mismatch): ", $critMissingOnOnePartner.Count -Color None, Red -FontWeight normal, bold }
        if ($critMissingOnBoth.Count -gt 0) { EmailListItem -Text "Critical: Missing on both partners: ", $critMissingOnBoth.Count -Color None, Red -FontWeight normal, bold }
        if ($warnFailoverUnverified.Count -gt 0) { EmailListItem -Text "Warning: Failover evidence unverified: ", $warnFailoverUnverified.Count -Color None, DarkOrange -FontWeight normal, bold }
    }

    if ($critMissingOnOnePartner.Count -gt 0) {
        EmailText -Text "🔴 Critical: Scopes missing from one failover partner" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable ($critMissingOnOnePartner | Select-Object -First $TopN) -HideFooter -IncludeProperty 'Relationship', 'PartnerA', 'PartnerB', 'PresentPartner', 'MissingPartner', 'ScopeId'
        EmailText -LineBreak
    }
    if ($critMissingOnBoth.Count -gt 0) {
        EmailText -Text "🔴 Critical: Scopes missing from failover on both partners" -Color Red -FontWeight bold -LineBreak
        EmailTable -DataTable ($critMissingOnBoth | Select-Object -First $TopN) -HideFooter -IncludeProperty 'Relationship', 'PartnerA', 'PartnerB', 'ScopeId'
        EmailText -LineBreak
    }
    if ($warnFailoverUnverified.Count -gt 0) {
        EmailText -Text "🟠 Warning: Failover Evidence Could Not Be Verified" -Color DarkOrange -FontWeight bold -LineBreak
        EmailTable -DataTable ($warnFailoverUnverified | Select-Object -First $TopN) -HideFooter -IncludeProperty 'ScopeId', 'PartnerA', 'PartnerB', 'Relationship', 'Issue', 'Verified'
        EmailText -LineBreak
    }
}

# Example sending via Graph in WhatIf
try { Connect-MgGraph -Scopes 'Mail.Send' -NoWelcome -ErrorAction Stop } catch {}

$EmailSplat = @{
    From     = 'przemyslaw.klys@company.pl'
    To       = 'network-team@company.pl'
    Body     = $EmailBody
    Priority = if ($CriticalCount -gt 0) { 'High' } else { 'Low' }
    Subject  = if ($CriticalCount -gt 0) {
        "DHCP Validation Issues - $TotalIssues scope(s) (C:$CriticalCount W:$WarningCount I:$InfoCount)"
    } elseif ($TotalIssues -gt 0 -or $WarningCount -gt 0 -or $InfoCount -gt 0) {
        "DHCP Validation Issues - $TotalIssues scope(s) (W:$WarningCount I:$InfoCount)"
    } else {
        'DHCP Validation: OK'
    }
    Verbose  = $true
    WhatIf   = $true
    MgGraph  = $true
}

Send-EmailMessage @EmailSplat
