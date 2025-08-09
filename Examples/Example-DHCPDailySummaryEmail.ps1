# Example script for generating DHCP daily summary emails using PSWriteHTML EmailBody
# This script demonstrates how to create rich email reports from DHCP validation data

Import-Module ADEssentials -Force

# Generate comprehensive DHCP summary (Extended mode is now default)
$DHCPData = Get-WinADDHCPSummary -Verbose

# Check if no DHCP servers were found
if ($DHCPData.Statistics.TotalServers -eq 0) {
    Write-Warning "No DHCP servers found in the environment. Cannot generate email report."
    Write-Host "Consider running: Install-WindowsFeature -Name DHCP -IncludeManagementTools" -ForegroundColor Yellow
    exit 0
}

# Determine email priority and subject based on issues found
$Priority = 'Low'
$SubjectEmoji = '💚'
$SubjectText = 'DHCP Infrastructure - All Good'

if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -gt 0) {
    $Priority = 'High'
    $SubjectEmoji = '🚨'
    $SubjectText = 'DHCP Infrastructure - Critical Issues Detected'
} elseif ($DHCPData.ValidationResults.Summary.TotalWarningIssues -gt 0) {
    $Priority = 'Normal'
    $SubjectEmoji = '⚠️'
    $SubjectText = 'DHCP Infrastructure - Warnings Found'
} elseif ($DHCPData.Statistics.ServersOffline -gt 0) {
    $Priority = 'High'
    $SubjectEmoji = '🔴'
    $SubjectText = 'DHCP Infrastructure - Servers Offline'
}

# Create rich HTML email body
$EmailBody = EmailBody {
    EmailImage -Source 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -UrlLink '' -AlternativeText 'Company Logo' -Width 181 -Heigh 57 -Inline

    EmailText -Text "Dear ", "Network Team," -LineBreak
    EmailText -Text "Daily DHCP Infrastructure Summary for $(Get-Date -Format 'MMMM dd, yyyy')" -Color DarkBlue -FontSize 14pt -FontWeight bold -LineBreak

    # Overall Infrastructure Health
    EmailText -Text "Infrastructure Overview" -Color Blue -FontSize 12pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Total DHCP Servers: ", $DHCPData.Statistics.TotalServers -Color None, DodgerBlue -FontWeight normal, bold
        EmailListItem -Text "Servers Online: ", $DHCPData.Statistics.ServersOnline -Color None, $(if ($DHCPData.Statistics.ServersOffline -eq 0) { 'LightGreen' } else { 'Orange' }) -FontWeight normal, bold
        EmailListItem -Text "Servers Offline: ", $DHCPData.Statistics.ServersOffline -Color None, $(if ($DHCPData.Statistics.ServersOffline -eq 0) { 'LightGreen' } else { 'Red' }) -FontWeight normal, bold
        EmailListItem -Text "Total Scopes: ", $DHCPData.Statistics.TotalScopes -Color None, DodgerBlue -FontWeight normal, bold
        EmailListItem -Text "Active Scopes: ", $DHCPData.Statistics.ScopesActive -Color None, LightGreen -FontWeight normal, bold
        EmailListItem -Text "Overall IP Utilization: ", "$($DHCPData.Statistics.OverallPercentageInUse)%" -Color None, $(if ($DHCPData.Statistics.OverallPercentageInUse -gt 80) { 'Red' } elseif ($DHCPData.Statistics.OverallPercentageInUse -gt 60) { 'Orange' } else { 'LightGreen' }) -FontWeight normal, bold
    }

    # Issue Summary
    EmailText -Text "Configuration Issues Summary" -Color Blue -FontSize 12pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Critical Issues: ", $DHCPData.ValidationResults.Summary.TotalCriticalIssues -Color None, $(if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -eq 0) { 'LightGreen' } else { 'Red' }) -FontWeight normal, bold
        EmailListItem -Text "Warning Issues: ", $DHCPData.ValidationResults.Summary.TotalWarningIssues -Color None, $(if ($DHCPData.ValidationResults.Summary.TotalWarningIssues -eq 0) { 'LightGreen' } else { 'Orange' }) -FontWeight normal, bold
        EmailListItem -Text "Info Issues: ", $DHCPData.ValidationResults.Summary.TotalInfoIssues -Color None, $(if ($DHCPData.ValidationResults.Summary.TotalInfoIssues -eq 0) { 'LightGreen' } else { 'Yellow' }) -FontWeight normal, bold
        EmailListItem -Text "Scopes with Critical Issues: ", $DHCPData.ValidationResults.Summary.ScopesWithCritical -Color None, $(if ($DHCPData.ValidationResults.Summary.ScopesWithCritical -eq 0) { 'LightGreen' } else { 'Red' }) -FontWeight normal, bold
        EmailListItem -Text "Scopes with Warnings: ", $DHCPData.ValidationResults.Summary.ScopesWithWarnings -Color None, $(if ($DHCPData.ValidationResults.Summary.ScopesWithWarnings -eq 0) { 'LightGreen' } else { 'Orange' }) -FontWeight normal, bold
    }

    # Critical Issues Section (if any)
    if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -gt 0) {
        EmailText -Text "🚨 Critical Issues Requiring Immediate Attention" -Color Red -FontSize 12pt -FontWeight bold

        # Servers Offline
        if ($DHCPData.ValidationResults.CriticalIssues.ServersOffline.Count -gt 0) {
            EmailText -Text "Offline DHCP Servers:" -Color Red -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.CriticalIssues.ServersOffline {
                EmailTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Unreachable' -BackGroundColor Salmon -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'Status', 'ErrorMessage', 'IsDC'
        }

        # Public DNS with Updates
        if ($DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count -gt 0) {
            EmailText -Text "Scopes with Public DNS and Dynamic Updates:" -Color Red -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates {
                EmailTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackGroundColor Salmon -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'State', 'Issues'
        }

        # High Utilization
        if ($DHCPData.ValidationResults.CriticalIssues.HighUtilization.Count -gt 0) {
            EmailText -Text "Scopes with Critical Utilization (>90%):" -Color Red -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.CriticalIssues.HighUtilization {
                EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackGroundColor Salmon -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'PercentageInUse', 'AddressesInUse', 'AddressesFree'
        }
    }

    # Warning Issues Section (if any)
    if ($DHCPData.ValidationResults.Summary.TotalWarningIssues -gt 0) {
        EmailText -Text "⚠️ Warning Issues" -Color Orange -FontSize 12pt -FontWeight bold

        # Missing Failover
        if ($DHCPData.ValidationResults.WarningIssues.MissingFailover.Count -gt 0) {
            EmailText -Text "Scopes Missing Failover Configuration:" -Color Orange -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.WarningIssues.MissingFailover {
                EmailTableCondition -Name 'FailoverPartner' -ComparisonType string -Operator eq -Value '' -BackGroundColor Orange -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'State', 'FailoverPartner'
        }

        # Extended Lease Duration
        if ($DHCPData.ValidationResults.WarningIssues.ExtendedLeaseDuration.Count -gt 0) {
            EmailText -Text "Scopes with Extended Lease Duration (>48 hours):" -Color Orange -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.WarningIssues.ExtendedLeaseDuration {
                EmailTableCondition -Name 'LeaseDurationHours' -ComparisonType number -Operator gt -Value 48 -BackGroundColor Orange -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'LeaseDurationHours', 'Description'
        }

        # Moderate Utilization
        if ($DHCPData.ValidationResults.WarningIssues.ModerateUtilization.Count -gt 0) {
            EmailText -Text "Scopes with Moderate Utilization (75-90%):" -Color Orange -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.WarningIssues.ModerateUtilization {
                EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackGroundColor Orange -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'PercentageInUse', 'AddressesFree'
        }

        # DNS Record Management Issues
        if ($DHCPData.ValidationResults.WarningIssues.DNSRecordManagement.Count -gt 0) {
            EmailText -Text "Scopes with DNS Record Management Issues:" -Color Orange -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.WarningIssues.DNSRecordManagement {
                EmailTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackGroundColor Orange -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'Issues'
        }
    }

    # Info Issues Section (if any and not too many critical/warning issues)
    if ($DHCPData.ValidationResults.Summary.TotalInfoIssues -gt 0 -and
        $DHCPData.ValidationResults.Summary.TotalCriticalIssues -eq 0 -and
        $DHCPData.ValidationResults.Summary.TotalWarningIssues -lt 5) {

        EmailText -Text "ℹ️ Information Items" -Color Blue -FontSize 12pt -FontWeight bold

        # Missing Domain Name Option
        if ($DHCPData.ValidationResults.InfoIssues.MissingDomainName.Count -gt 0) {
            EmailText -Text "Scopes with Missing Domain Name Option:" -Color Blue -FontWeight bold
            EmailTable -DataTable $DHCPData.ValidationResults.InfoIssues.MissingDomainName {
                EmailTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackGroundColor LightBlue -Inline
            } -HideFooter -IncludeProperty 'ServerName', 'ScopeId', 'Name', 'Issues'
        }
    }

    # Overall Server Status Table
    EmailText -Text "Server Status Overview" -Color Blue -FontSize 12pt -FontWeight bold

    $ServerProperties = 'ServerName', 'Status', 'ScopeCount', 'ScopesWithIssues', 'PercentageInUse', 'IsDC', 'DHCPRole'
    EmailTable -DataTable $DHCPData.Servers {
        EmailTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackGroundColor LightGreen -FailBackgroundColor Salmon -Inline
        EmailTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackGroundColor Orange -Inline
        EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackGroundColor Salmon -Inline
        EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 60 -BackGroundColor Orange -Inline
        EmailTableCondition -Name 'IsDC' -ComparisonType bool -Operator eq -Value $true -BackGroundColor LightBlue -Inline
    } -HideFooter -IncludeProperty $ServerProperties

    # Recommendations Section
    if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -gt 0 -or $DHCPData.ValidationResults.Summary.TotalWarningIssues -gt 0) {
        EmailText -Text "Recommended Actions" -Color DarkBlue -FontSize 12pt -FontWeight bold

        EmailList -FontSize 10pt {
            if ($DHCPData.ValidationResults.CriticalIssues.ServersOffline.Count -gt 0) {
                EmailListItem -Text "🔴 Investigate and restore offline DHCP servers immediately" -Color Red
            }
            if ($DHCPData.ValidationResults.CriticalIssues.PublicDNSWithUpdates.Count -gt 0) {
                EmailListItem -Text "🔴 Review scopes with public DNS servers and disable dynamic updates or use internal DNS" -Color Red
            }
            if ($DHCPData.ValidationResults.CriticalIssues.HighUtilization.Count -gt 0) {
                EmailListItem -Text "🔴 Expand address pools for scopes with >90% utilization" -Color Red
            }
            if ($DHCPData.ValidationResults.WarningIssues.MissingFailover.Count -gt 0) {
                EmailListItem -Text "⚠️ Configure DHCP failover for high-availability scopes" -Color Orange
            }
            if ($DHCPData.ValidationResults.WarningIssues.ModerateUtilization.Count -gt 0) {
                EmailListItem -Text "⚠️ Monitor scopes with >75% utilization for capacity planning" -Color Orange
            }
            if ($DHCPData.ValidationResults.WarningIssues.DNSRecordManagement.Count -gt 0) {
                EmailListItem -Text "⚠️ Review DNS record management settings for proper cleanup" -Color Orange
            }
        }
    } else {
        EmailText -Text "✅ No critical issues detected. DHCP infrastructure is healthy!" -Color Green -FontWeight bold
    }

    # Footer
    EmailText -LineBreak
    EmailText -Text "Report generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') by ADEssentials DHCP monitoring" -Color Gray -FontSize 9pt
    EmailText -Text "For detailed analysis, run: Show-WinADDHCPSummary -FilePath 'C:\Reports\DHCP.html'" -Color Gray -FontSize 9pt
    EmailText -LineBreak
    EmailText -Text "Kind regards," -LineBreak
    EmailText -Text "Your DHCP Infrastructure Monitoring System" -Color DarkBlue -FontWeight bold
}

# Email configuration
$EmailSplat = @{
    From     = 'dhcp-monitoring@company.com'        # Replace with your sender
    To       = 'network-team@company.com'           # Replace with your recipients
    Body     = $EmailBody
    Priority = $Priority
    Subject  = "$SubjectEmoji $SubjectText - $(Get-Date -Format 'yyyy-MM-dd')"
    Verbose  = $true
    WhatIf   = $false  # Set to $true for testing
    MgGraph  = $true   # Use Microsoft Graph for sending (requires Connect-MgGraph)
}

# Optional: Add CC recipients for critical issues
if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -gt 0) {
    $EmailSplat.Cc = 'infrastructure-manager@company.com'  # Replace with your escalation contact
}

# Send the email
Write-Host "Sending DHCP daily summary email..." -ForegroundColor Green
Write-Host "Priority: $Priority" -ForegroundColor $(if ($Priority -eq 'High') { 'Red' } elseif ($Priority -eq 'Normal') { 'Yellow' } else { 'Green' })
Write-Host "Critical Issues: $($DHCPData.ValidationResults.Summary.TotalCriticalIssues)" -ForegroundColor $(if ($DHCPData.ValidationResults.Summary.TotalCriticalIssues -gt 0) { 'Red' } else { 'Green' })
Write-Host "Warning Issues: $($DHCPData.ValidationResults.Summary.TotalWarningIssues)" -ForegroundColor $(if ($DHCPData.ValidationResults.Summary.TotalWarningIssues -gt 0) { 'Yellow' } else { 'Green' })

try {
    # Connect to Microsoft Graph (requires appropriate permissions)
    # Connect-MgGraph -Scopes 'Mail.Send'

    # Send the email
    # Send-EmailMessage @EmailSplat

    # For testing without actually sending, just display the email body
    Write-Host "Email body generated successfully. Enable sending by uncommenting the Send-EmailMessage line." -ForegroundColor Cyan

    # Optionally save the email body to HTML file for preview
    $PreviewPath = "$env:TEMP\DHCP_Email_Preview_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $EmailBody | Out-File -FilePath $PreviewPath -Encoding UTF8
    Write-Host "Email preview saved to: $PreviewPath" -ForegroundColor Cyan

} catch {
    Write-Error "Failed to send email: $($_.Exception.Message)"

    # Fallback: Generate HTML report
    Write-Host "Generating fallback HTML report..." -ForegroundColor Yellow
    $FallbackPath = "$env:TEMP\DHCP_Summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    Show-WinADDHCPSummary -FilePath $FallbackPath -HideHTML
    Write-Host "Fallback report saved to: $FallbackPath" -ForegroundColor Yellow
}

# Display summary to console
Write-Host "`n=== DHCP Infrastructure Summary ===" -ForegroundColor Green
Write-Host "Total Servers: $($DHCPData.Statistics.TotalServers) (Online: $($DHCPData.Statistics.ServersOnline), Offline: $($DHCPData.Statistics.ServersOffline))"
Write-Host "Total Scopes: $($DHCPData.Statistics.TotalScopes) (Active: $($DHCPData.Statistics.ScopesActive), With Issues: $($DHCPData.Statistics.ScopesWithIssues))"
Write-Host "Overall Utilization: $($DHCPData.Statistics.OverallPercentageInUse)%"
Write-Host "Critical Issues: $($DHCPData.ValidationResults.Summary.TotalCriticalIssues)"
Write-Host "Warning Issues: $($DHCPData.ValidationResults.Summary.TotalWarningIssues)"
Write-Host "Info Issues: $($DHCPData.ValidationResults.Summary.TotalInfoIssues)"
