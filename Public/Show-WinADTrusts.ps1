function Show-WinADTrusts {
    [alias('Show-ADTrusts')]
    [cmdletBinding()]
    param(
        [string] $FilePath,
        [switch] $Online
    )
    if ($FilePath -eq '') {
        $FilePath = Get-FileName -Extension 'html' -Temporary
    }
    New-HTML -TitleText "Visual Trusts" {
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLTableOption -DataStore HTML
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey

        $ADTrusts = Get-WinADTrusts -Unique -Display

        <#
        $AllNodes = @(
            $ADTrusts.TrustSource
            $ADTrusts.TrustTarget
        ) | Sort-Object -Unique
        #>

        New-HTMLTab -TabName 'Trusts' {
            New-HTMLSection -Title "Information about Trusts" {
                New-HTMLTable -DataTable $ADTrusts -Filtering {
                    #New-TableHeader -Names Name, SamAccountName, DomainName, DisplayName -Title 'Member'
                    #New-TableHeader -Names DirectMembers, DirectGroups, IndirectMembers, TotalMembers -Title 'Statistics'
                    #New-TableHeader -Names GroupType, GroupScope -Title 'Group Details'
                    #New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $false -Name Enabled -Operator eq
                    #New-TableCondition -BackgroundColor LightBlue -ComparisonType string -Value '' -Name ParentGroup -Operator eq -Row
                    #New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name CrossForest -Operator eq
                    #New-TableCondition -BackgroundColor CoralRed -ComparisonType bool -Value $true -Name Circular -Operator eq
                }
            }
            New-HTMLSection  {
                New-HTMLDiagram {
                    foreach ($Node in $AllNodes) {
                        New-DiagramNode -Label $Node.'Trust'
                    }

                    foreach ($Trust in $ADTrusts) {
                        New-DiagramNode -Label $Trust.'Trust Source'
                        New-DiagramNode -Label $Trust.'Trust Target'
                        # [enum]::GetValues([Microsoft.ActiveDirectory.Management.ADTrustDirection])
                        if ($Trust.'Trust Direction' -eq 'Disabled') {

                        } elseif ($Trust.'Trust Direction' -eq 'Inbound') {
                            New-DiagramLink -From $Trust.'Trust Source' -To $Trust.'Trust Target' -ArrowsFromEnabled
                        } elseif ($Trust.'Trust Direction' -eq 'Outbount') {
                            New-DiagramLink -From $Trust.'Trust Source' -To $Trust.'Trust Target' -ArrowsToEnabled
                        } elseif ($Trust.'Trust Direction' -eq 'Bidirectional') {
                            New-DiagramLink -From $Trust.'Trust Source' -To $Trust.'Trust Target' -ArrowsToEnabled -ArrowsFromEnabled
                        }

                    }
                }
            }
        }

    } -Online:$Online -FilePath $FilePath -ShowHTML
}