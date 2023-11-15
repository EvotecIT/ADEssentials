function Show-WinADObjectDifference {
    [CmdletBinding()]
    param(
        [string[]] $Identity,
        [switch] $GlobalCatalog
    )

    $OutputValue = Find-WinADObjectDifference -Identity $Identity -GlobalCatalog:$GlobalCatalog.IsPresent

    Write-Verbose -Message "Show-WinADObjectDifference - Generating HTML"
    New-HTML {
        New-HTMLTableOption -DataStore JavaScript -BoolAsString -ArrayJoinString ", " -ArrayJoin

        New-HTMLTable -DataTable $OutputValue.ListSummary -Filtering -DataStore JavaScript -ScrollX {
            New-HTMLTableCondition -Name 'ServersDifferentCount' -Operator eq -ComparisonType number -Value 0 -BackgroundColor LimeGreen -FailBackgroundColor Salmon
            New-HTMLTableCondition -Name 'ServersSameCount' -Operator eq -ComparisonType number -Value 0 -BackgroundColor Salmon -FailBackgroundColor LimeGreen
        }

        New-HTMLTable -DataTable $OutputValue.List -Filtering -DataStore JavaScript -ScrollX

    } -ShowHTML
    Write-Verbose -Message "Show-WinADObjectDifference - Generating HTML - Done"
}