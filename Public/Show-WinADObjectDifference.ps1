function Show-WinADObjectDifference {
    <#
    .SYNOPSIS
    This function shows the differences between Active Directory objects.
    .DESCRIPTION
    The function takes an array of Identity, a switch for Global Catalog, an array of Properties, a string for FilePath, and a switch to hide HTML.
    It then generates an HTML report using the Find-WinADObjectDifference function and displays it.
    .PARAMETER Identity
    An array of Identity to compare.
    .PARAMETER GlobalCatalog
    A switch to specify if the comparison should be done in the Global Catalog.
    .PARAMETER Properties
    An array of Properties to compare.
    .PARAMETER FilePath
    A string specifying the file path to save the HTML report.
    .PARAMETER HideHTML
    A switch to hide the HTML report.
    .EXAMPLE
    Show-WinADObjectDifference -Identity "user1", "user2" -GlobalCatalog -Properties "Name", "Email" -FilePath "C:\ADReport.html" -HideHTML
    #>
    [CmdletBinding()]
    param(
        [Array] $Identity,
        [switch] $GlobalCatalog,
        [string[]] $Properties,
        [string] $FilePath,
        [switch] $HideHTML
    )

    $OutputValue = Find-WinADObjectDifference -Identity $Identity -GlobalCatalog:$GlobalCatalog.IsPresent -Properties $Properties

    Write-Verbose -Message "Show-WinADObjectDifference - Generating HTML"
    New-HTML {
        New-HTMLTableOption -DataStore JavaScript -BoolAsString -ArrayJoinString ", " -ArrayJoin

        New-HTMLTab -Name 'Summary' {
            New-HTMLTable -DataTable $OutputValue.ListSummary -Filtering -DataStore JavaScript -ScrollX {
                New-HTMLTableCondition -Name 'DifferentServersCount' -Operator eq -ComparisonType number -Value 0 -BackgroundColor LimeGreen -FailBackgroundColor Salmon -HighlightHeaders 'DifferentServersCount', 'DifferentServers', 'DifferentProperties'
                New-HTMLTableCondition -Name 'SameServersCount' -Operator eq -ComparisonType number -Value 0 -BackgroundColor Salmon -FailBackgroundColor LimeGreen -HighlightHeaders 'SameServersCount', 'SameServers', 'SameProperties'
            }
        }
        New-HTMLTab -Name 'Details per property' {
            New-HTMLTable -DataTable $OutputValue.ListDetails -Filtering -DataStore JavaScript -ScrollX -AllProperties
        }
        New-HTMLTab -Name 'Details per server' {
            New-HTMLTable -DataTable $OutputValue.ListDetailsReversed -Filtering -DataStore JavaScript -ScrollX
        }
        New-HTMLTab -Name 'Detailed Differences' {
            New-HTMLTable -DataTable $OutputValue.List -Filtering -DataStore JavaScript -ScrollX
        }
    } -ShowHTML:(-not $HideHTML.IsPresent) -FilePath $FilePath
    Write-Verbose -Message "Show-WinADObjectDifference - Generating HTML - Done"
}