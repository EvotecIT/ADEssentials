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
$TotalIssues = (@($Output.ScopesWithIssues).Count) + $CriticalCount + $WarningCount

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
    Subject  = if ($CriticalCount -gt 0) { "DHCP Validation: Critical issues found ($CriticalCount)" } else { 'DHCP Validation: OK' }
    Verbose  = $true
    WhatIf   = $true
    MgGraph  = $true
}

# Connect-MgGraph -Scopes 'Mail.Send'
Send-EmailMessage @EmailSplat
