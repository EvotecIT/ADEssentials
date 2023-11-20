function Show-WinADObjectDifference {
    [CmdletBinding()]
    param(
        [Array] $Identity,
        [switch] $GlobalCatalog,
        [string[]] $Properties
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
    } -ShowHTML
    Write-Verbose -Message "Show-WinADObjectDifference - Generating HTML - Done"
}