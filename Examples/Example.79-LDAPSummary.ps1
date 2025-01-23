Import-Module .\ADEssentials.psd1 -Force

#$Output = Get-WinADLDAPSummary
#$Output | Format-Table

<#
$Output1 = Get-WinADLDAPSummary -Extended
$Output1 | Format-Table
#>

$Output = Show-WinADLdapSummary -Verbose -FilePath "$PSScriptRoot\Reports\LDAPSummary.html" -PassThru -Identity 'krbtgt' -Fail

# Email way
$EmailBody = EmailBody {
    EmailImage -Source 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -UrlLink '' -AlternativeText 'Eurofins Logo' -Width 181 -Heigh 57 -Inline

    EmailText -Text "Dear ", "AD Team," -LineBreak

    EmailText -Text "Summary for LDAP servers" -Color Blue -FontSize 10pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Servers with no issues: ", $($Output.GoodServers.Count) -Color None, LightGreen -FontWeight normal, bold
        EmailListItem -Text "Servers with issues: ", $($Output.FailedServers.Count) -Color None, Salmon -FontWeight normal, bold
    }

    EmailText -Text "Servers certificate summary" -Color Blue -FontSize 10pt -FontWeight bold

    EmailList -FontSize 10pt {
        EmailListItem -Text "Servers with certificate expiring More Than 30 Days: ", $($Output.ServersExpiringMoreThan30Days.Count) -FontWeight normal, bold
        EmailListItem -Text "Servers with certificate expiring In 30 Days: ", $($Output.ServersExpiringIn30Days.Count) -FontWeight normal, bold
        EmailListItem -Text "Servers with certificate expiring In 15 Days: ", $($Output.ServersExpiringIn15Days.Count) -FontWeight normal, bold
        EmailListItem -Text "Servers with certificate expiring In 7 Days: ", $($Output.ServersExpiringIn7Days.Count) -FontWeight normal, bold
        EmailListItem -Text "Servers with certificate expiring In 3 Days Or Less: ", $($Output.ServersExpiringIn3DaysOrLess.Count) -FontWeight normal, bold
        EmailListItem -Text "Servers with certificate expired: ", $($Output.ServersExpired.Count) -FontWeight normal, bold
    }

    $Properties = 'Computer', 'Site', 'IsGC', 'StatusDate', 'StatusPorts', 'StatusIdentity', 'AvailablePorts', 'X509NotBeforeDays', 'X509NotAfterDays', 'X509DnsNameStatus', 'X509DnsNameList', 'X509NotAfter', 'X509Issuer', 'ErrorMessage', 'RetryCount'
    if ($Output.FailedServers.Count -gt 0) {
        EmailText -Text "Servers with issues:" -LineBreak
        EmailTable -DataTable $Output.FailedServers {
            EmailTableCondition -Name 'StatusDate' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon -Inline
            EmailTableCondition -Name 'X509DnsNameStatus' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon -HighlightHeaders 'X509DnsNameStatus', 'X509DnsNameList' -Inline
            EmailTableCondition -Name 'StatusPorts' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon -Inline
            EmailTableCondition -Name 'StatusIdentity' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon -Inline
        } -HideFooter -IncludeProperty $Properties -PrettifyObject
    }

    EmailText -LineBreak
    EmailText -Text "For all server details please check the table below:" -LineBreak

    EmailTable -DataTable $Output.List {
        EmailTableCondition -Name 'StatusDate' -ComparisonType string -Operator eq -Value 'OK' -BackGroundColor LightGreen -FailBackgroundColor Salmon -Inline
        EmailTableCondition -Name 'X509DnsNameStatus' -ComparisonType string -Operator eq -Value 'OK' -BackGroundColor LightGreen -FailBackgroundColor Salmon -HighlightHeaders 'X509DnsNameStatus', 'X509DnsNameList' -Inline
        EmailTableCondition -Name 'StatusPorts' -ComparisonType string -Operator eq -Value 'OK' -BackGroundColor LightGreen -FailBackgroundColor Salmon -Inline
        EmailTableCondition -Name 'StatusIdentity' -ComparisonType string -Operator eq -Value 'OK' -BackGroundColor LightGreen -FailBackgroundColor Salmon -Inline
    } -HideFooter -IncludeProperty $Properties -PrettifyObject

    EmailText -LineBreak
    EmailText -Text "Kind regards,"
    EmailText -Text "Your automation friend"
}

$EmailSplat = @{
    From     = 'przemyslaw.klys@evotec.pl'
    To       = 'przemyslaw.klys@evotec.pl'
    Body     = $EmailBody
    Priority = if ($Output.FailedServers.Count -gt 0) { 'High' } else { 'Low' }
    Subject  = if ($Output.FailedServers.Count -gt 0) { 'LDAP Results 👎' } else { 'LDAP Results 💖' }
    Verbose  = $true
    WhatIf   = $false
    MgGraph  = $true
}

Connect-MgGraph -Scopes 'Mail.Send'
Send-EmailMessage @EmailSplat