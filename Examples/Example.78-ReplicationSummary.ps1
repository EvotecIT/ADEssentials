Import-Module .\ADEssentials.psd1 -Force

# Object oriented way only
# $ReplicationSummary = Get-WinADForestReplicationSummary -IncludeStatisticsVariable Statistics

# HTML way
$Output = Show-WinADForestReplicationSummary -Verbose -FilePath "$PSScriptRoot\Reports\ReplicationSummary.html" -PassThru
$ReplicationSummary = $Output.ReplicationSummary
$Statistics = $Output.Statistics

# Email way
$EmailBody = EmailBody {
    EmailImage -Source 'https://evotec.xyz/wp-content/uploads/2021/04/Logo-evotec-bb.png' -UrlLink '' -AlternativeText 'Eurofins Logo' -Width 181 -Heigh 57 -Inline

    EmailText -Text "Dear ", "AD Team," -LineBreak
    EmailText -Text "Upon reviewing the resuls of replication I've found: "
    EmailList {
        EmailListItem -Text "Servers with good replication: ", $($Statistics.Good) -Color Black, SpringGreen -FontWeight normal, bold
        EmailListItem -Text "Servers with replication failures: ", $($Statistics.Failures) -Color Black, Red -FontWeight normal, bold
        EmailListItem -Text "Servers with replication delta over 24 hours: ", $($Statistics.DeltaOver24Hours) -Color Black, Red -FontWeight normal, bold
        EmailListItem -Text "Servers with replication delta over 12 hours: ", $($Statistics.DeltaOver12Hours) -Color Black, Red -FontWeight normal, bold
        EmailListItem -Text "Servers with replication delta over 6 hours: ", $($Statistics.DeltaOver6Hours) -Color Black, Red -FontWeight normal, bold
        EmailListItem -Text "Servers with replication delta over 3 hours: ", $($Statistics.DeltaOver3Hours) -Color Black, Red -FontWeight normal, bold
        EmailListItem -Text "Servers with replication delta over 1 hour: ", $($Statistics.DeltaOver1Hours) -Color Black, Red -FontWeight normal, bold
        EmailListItem -Text "Unique replication errors: ", $($Statistics.UniqueErrors.Count) -Color Black, Red -FontWeight normal, bold
        EmailListItem -Text "Unique replication warnings: ", $($Statistics.UniqueWarnings.Count) -Color Black, Yellow -FontWeight normal, bold
    }

    if ($Statistics.UniqueErrors.Count -gt 0) {
        EmailText -Text "Unique replication errors:"
        EmailList {
            foreach ($ErrorText in $Statistics.UniqueErrors) {
                EmailListItem -Text $ErrorText
            }
        }
    } else {
        EmailText -Text "It seems you're doing a great job! Keep it up! 😊" -LineBreak
    }

    EmailText -Text "For more details please check the table below:"

    EmailTable -DataTable $ReplicationSummary {
        EmailTableCondition -Inline -Name "Fail" -HighlightHeaders 'Fails', 'Total', 'PercentageError' -ComparisonType number -Operator gt 0 -BackGroundColor Salmon -FailBackgroundColor SpringGreen
    } -HideFooter

    EmailText -LineBreak
    EmailText -Text "Kind regards,"
    EmailText -Text "Your automation friend"
}

$EmailSplat = @{
    From     = 'przemyslaw.klys@evotec.pl'
    To       = 'przemyslaw.klys@evotec.pl'
    Body     = $EmailBody
    Priority = if ($Statistics.Failures -gt 0) { 'High' } else { 'Low' }
    Subject  = if ($Statistics.Failures -gt 0) { 'Replication Results 👎' } else { 'Replication Results 💖' }
    Verbose  = $true
    WhatIf   = $false
    MgGraph  = $true
}

Connect-MgGraph -Scopes 'Mail.Send'
Send-EmailMessage @EmailSplat