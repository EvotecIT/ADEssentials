function Show-WinADLdapSummary {
    <#
    .SYNOPSIS
    Generates an HTML report for LDAP summary.

    .DESCRIPTION
    This function generates an HTML report for LDAP summary using the Get-WinADLDAPSummary function.
    The report includes statistics and detailed LDAP server information.

    .PARAMETER Forest
    The name of the Active Directory forest.

    .PARAMETER ExcludeDomains
    Domains to exclude from the summary.

    .PARAMETER ExcludeDomainControllers
    Domain controllers to exclude from the summary.

    .PARAMETER IncludeDomains
    Domains to include in the summary.

    .PARAMETER IncludeDomainControllers
    Domain controllers to include in the summary.

    .PARAMETER SkipRODC
    Switch to skip read-only domain controllers.

    .PARAMETER Identity
    The identity to use for the summary.

    .PARAMETER RetryCount
    The number of retries for testing.

    .PARAMETER FilePath
    The path where the HTML report will be saved.

    .PARAMETER Online
    Switch to indicate if the report should be generated with online resources.

    .PARAMETER HideHTML
    Switch to indicate if the HTML report should be hidden after generation.

    .PARAMETER FailIfDomainNameNotInCertificate
    A switch to fail if the domain name is not in the certificate.

    .PARAMETER PassThru
    Switch to return the LDAP summary as output.

    .EXAMPLE
    Show-WinADLdapSummary -Forest "ad.evotec.xyz" -FilePath "C:\Reports\LDAPSummary.html"

    .EXAMPLE
    Show-WinADLdapSummary -IncludeDomains "domain1", "domain2" -HideHTML

    .EXAMPLE
    Show-WinADLdapSummary -PassThru

    .NOTES
    #>
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        $Identity,
        [int] $RetryCount = 3,
        [string] $FilePath,
        [switch] $Online,
        [switch] $HideHTML,
        [switch] $FailIfDomainNameNotInCertificate,
        [switch] $PassThru
    )

    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }

    $getWinADLDAPSummarySplat = @{
        IncludeDomains                   = $IncludeDomains
        ExcludeDomains                   = $ExcludeDomains
        IncludeDomainControllers         = $IncludeDomainControllers
        ExcludeDomainControllers         = $ExcludeDomainControllers
        SkipRODC                         = $SkipRODC
        Identity                         = $Identity
        RetryCount                       = $RetryCount
        Forest                           = $Forest
        Extended                         = $true
        FailIfDomainNameNotInCertificate = $FailIfDomainNameNotInCertificate
    }

    $Output = Get-WinADLDAPSummary @getWinADLDAPSummarySplat

    New-HTML {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore JavaScript -ArrayJoin -ArrayJoinString "," -BoolAsString
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

        New-HTMLHeader {
            New-HTMLSection -Invisible {
                New-HTMLSection {
                    New-HTMLText -Text "Report generated on $(Get-Date)" -Color Blue
                } -JustifyContent flex-start -Invisible
                New-HTMLSection {
                    New-HTMLText -Text "ADEssentials - $($Script:Reporting['Version'])" -Color Blue
                } -JustifyContent flex-end -Invisible
            }
        }

        New-HTMLSection -HeaderText "LDAP Summary" {
            New-HTMLPanel -Invisible {
                New-HTMLText -Text "Summary for $($Output.Count) servers" -Color Blue -FontSize 10pt -FontWeight bold

                New-HTMLList -FontSize 10pt {
                    New-HTMLListItem -Text "Servers with no issues: ", $($Output.GoodServers.Count) -Color None, LightGreen -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers with issues: ", $($Output.FailedServersCount) -Color None, Salmon -FontWeight normal, bold
                }

                New-HTMLText -Text "Servers certificate summary" -Color Blue -FontSize 10pt -FontWeight bold

                New-HTMLList -FontSize 10pt {
                    New-HTMLListItem -Text "Servers with certificate expiring More Than 30 Days: ", $($Output.ServersExpiringMoreThan30Days.Count) -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers with certificate expiring In 30 Days: ", $($Output.ServersExpiringIn30Days.Count) -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers with certificate expiring In 15 Days: ", $($Output.ServersExpiringIn15Days.Count) -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers with certificate expiring In 7 Days: ", $($Output.ServersExpiringIn7Days.Count) -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers with certificate expiring In 3 Days Or Less: ", $($Output.ServersExpiringIn3DaysOrLess.Count) -FontWeight normal, bold
                    New-HTMLListItem -Text "Servers with certificate expired: ", $($Output.ServersExpired.Count) -FontWeight normal, bold
                }
            }
            New-HTMLPanel {
                New-HTMLChart {
                    New-ChartPie -Name 'Servers with no issues' -Value $($Output.GoodServers.Count) -Color LightGreen
                    New-ChartPie -Name 'Servers with issues' -Value $($Output.FailedServersCount) -Color Salmon
                } -Title 'Servers status' -TitleColor Dandelion
            }
        }

        New-HTMLSection -HeaderText "LDAP Servers" {
            New-HTMLTable -DataTable $Output.List -Filtering {
                New-HTMLTableCondition -Name 'StatusDate' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                New-HTMLTableCondition -Name 'X509DnsNameStatus' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon -HighlightHeaders 'X509DnsNameStatus', 'X509DnsNameList'
                New-HTMLTableCondition -Name 'StatusPorts' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon
                New-HTMLTableCondition -Name 'StatusIdentity' -ComparisonType string -Operator eq -Value 'OK' -BackgroundColor LightGreen -FailBackgroundColor Salmon

            } -DataTableID 'DT-LDAPSummary' -ScrollX -WarningAction SilentlyContinue
        }
    } -FilePath $FilePath -ShowHTML:(-not $HideHTML)

    if ($PassThru) {
        $Output
    }
}