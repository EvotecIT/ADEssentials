# DHCP Daily Summary Email - Simple Version
# Following the pattern from Example.79-LDAPSummary.ps1

Import-Module .\ADEssentials.psd1 -Force

# Generate DHCP summary data
$Output = Show-WinADDHCPSummary -Verbose -FilePath "$PSScriptRoot\Reports\DHCPSummary.html" -PassThru

# Email way
$EmailBody = EmailBody {
    EmailImage -Source 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -UrlLink '' -AlternativeText 'Company Logo' -Width 181 -Heigh 57 -Inline

    EmailText -Text "Dear ", "Network Team," -LineBreak

    EmailText -Text "Summary for DHCP Infrastructure" -Color Blue -FontSize 10pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Servers Online: ", $($Output.Statistics.ServersOnline) -Color None, LightGreen -FontWeight normal, bold
        EmailListItem -Text "Servers Offline: ", $($Output.Statistics.ServersOffline) -Color None, $(if ($Output.Statistics.ServersOffline -eq 0) { 'LightGreen' } else { 'Salmon' }) -FontWeight normal, bold
        EmailListItem -Text "Servers with Issues: ", $($Output.Statistics.ServersWithIssues) -Color None, $(if ($Output.Statistics.ServersWithIssues -eq 0) { 'LightGreen' } else { 'Orange' }) -FontWeight normal, bold
        EmailListItem -Text "Total Scopes: ", $($Output.Statistics.TotalScopes) -Color None, DodgerBlue -FontWeight normal, bold
        EmailListItem -Text "Scopes with Issues: ", $($Output.Statistics.ScopesWithIssues) -Color None, $(if ($Output.Statistics.ScopesWithIssues -eq 0) { 'LightGreen' } else { 'Salmon' }) -FontWeight normal, bold
    }

    EmailText -Text "Configuration Issues Summary" -Color Blue -FontSize 10pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Critical Issues: ", $($Output.ValidationResults.Summary.TotalCriticalIssues) -Color None, $(if ($Output.ValidationResults.Summary.TotalCriticalIssues -eq 0) { 'LightGreen' } else { 'Red' }) -FontWeight normal, bold
        EmailListItem -Text "Warning Issues: ", $($Output.ValidationResults.Summary.TotalWarningIssues) -Color None, $(if ($Output.ValidationResults.Summary.TotalWarningIssues -eq 0) { 'LightGreen' } else { 'Orange' }) -FontWeight normal, bold
        EmailListItem -Text "Info Issues: ", $($Output.ValidationResults.Summary.TotalInfoIssues) -Color None, $(if ($Output.ValidationResults.Summary.TotalInfoIssues -eq 0) { 'LightGreen' } else { 'Yellow' }) -FontWeight normal, bold
        EmailListItem -Text "Overall IP Utilization: ", "$($Output.Statistics.OverallPercentageInUse)%" -Color None, $(if ($Output.Statistics.OverallPercentageInUse -gt 80) { 'Red' } elseif ($Output.Statistics.OverallPercentageInUse -gt 60) { 'Orange' } else { 'LightGreen' }) -FontWeight normal, bold
    }

    $Properties = 'ServerName', 'Status', 'ScopeCount', 'ScopesWithIssues', 'PercentageInUse', 'IsDC'
    if ($Output.Statistics.ServersWithIssues -gt 0 -or $Output.Statistics.ServersOffline -gt 0) {
        EmailText -Text "Servers with issues:" -LineBreak
        $ServersWithProblems = $Output.Servers | Where-Object { $_.ScopesWithIssues -gt 0 -or $_.Status -ne 'Online' }
        EmailTable -DataTable $ServersWithProblems {
            EmailTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackgroundColor LightGreen -FailBackgroundColor Salmon -Inline
            EmailTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackgroundColor Orange -Inline
            EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackgroundColor Salmon -Inline
            EmailTableCondition -Name 'IsDC' -ComparisonType bool -Operator eq -Value $true -BackgroundColor LightBlue -Inline
        } -HideFooter -IncludeProperty $Properties -PrettifyObject
    }

    if ($Output.Statistics.ScopesWithIssues -gt 0) {
        EmailText -Text "Scopes with configuration issues:" -LineBreak
        $ScopeProperties = 'ServerName', 'ScopeId', 'Name', 'State', 'PercentageInUse', 'HasIssues', 'Issues'
        EmailTable -DataTable $Output.ScopesWithIssues {
            EmailTableCondition -Name 'HasIssues' -ComparisonType bool -Operator eq -Value $true -BackgroundColor Salmon -Inline
            EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 90 -BackgroundColor Red -Inline
            EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 75 -BackgroundColor Orange -Inline
            EmailTableCondition -Name 'State' -ComparisonType string -Operator eq -Value 'Active' -BackgroundColor LightGreen -FailBackgroundColor Orange -Inline
        } -HideFooter -IncludeProperty $ScopeProperties -PrettifyObject
    }

    EmailText -LineBreak
    EmailText -Text "For all server details please check the table below:" -LineBreak

    EmailTable -DataTable $Output.Servers {
        EmailTableCondition -Name 'Status' -ComparisonType string -Operator eq -Value 'Online' -BackGroundColor LightGreen -FailBackgroundColor Salmon -Inline
        EmailTableCondition -Name 'ScopesWithIssues' -ComparisonType number -Operator gt -Value 0 -BackGroundColor Orange -Inline
        EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 80 -BackGroundColor Salmon -Inline
        EmailTableCondition -Name 'PercentageInUse' -ComparisonType number -Operator gt -Value 60 -BackGroundColor Orange -Inline
        EmailTableCondition -Name 'IsDC' -ComparisonType bool -Operator eq -Value $true -BackGroundColor LightBlue -Inline
    } -HideFooter -IncludeProperty $Properties -PrettifyObject

    EmailText -LineBreak
    EmailText -Text "Kind regards,"
    EmailText -Text "Your DHCP Infrastructure Monitor"
}

$EmailSplat = @{
    From     = 'dhcp-monitor@company.com'
    To       = 'network-team@company.com'
    Body     = $EmailBody
    Priority = if ($Output.ValidationResults.Summary.TotalCriticalIssues -gt 0) { 'High' } elseif ($Output.ValidationResults.Summary.TotalWarningIssues -gt 0) { 'Normal' } else { 'Low' }
    Subject  = if ($Output.ValidationResults.Summary.TotalCriticalIssues -gt 0) { 'DHCP Infrastructure 🚨' } elseif ($Output.ValidationResults.Summary.TotalWarningIssues -gt 0) { 'DHCP Infrastructure ⚠️' } else { 'DHCP Infrastructure ✅' }
    Verbose  = $true
    WhatIf   = $false
    MgGraph  = $true
}

Connect-MgGraph -Scopes 'Mail.Send'
Send-EmailMessage @EmailSplat
