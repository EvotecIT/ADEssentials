function Show-WinADKerberosAccount {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $Online,
        [switch] $HideHTML,
        [string] $FilePath,
        [switch] $PassThru
    )
    $Today = Get-Date
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    $AccountData = Get-WinADKerberosAccount -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -IncludeCriticalAccounts

    Write-Verbose -Message "Show-WinADKerberosAccount - Building HTML report based on delivered data"
    New-HTML -Author 'Przemysław Kłys' -TitleText 'Kerberos Reporting' {
        New-HTMLTabStyle -BorderRadius 0px -TextTransform lowercase -BackgroundColorActive SlateGrey
        New-HTMLSectionStyle -BorderRadius 0px -HeaderBackGroundColor Grey -RemoveShadow
        New-HTMLPanelStyle -BorderRadius 0px
        New-HTMLTableOption -DataStore JavaScript -BoolAsString -ArrayJoinString ', ' -ArrayJoin

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

        foreach ($Domain in $AccountData.Data.Keys) {
            New-HTMLTab -Name $Domain {
                New-HTMLPanel {
                    New-HTMLTable -DataTable $AccountData['Data'][$Domain].Values.FullInformation -Filtering -DataStore JavaScript -ScrollX {
                        $newHTMLTableConditionSplat = @{
                            Name                = 'PasswordLastSetDays'
                            ComparisonType      = 'number'
                            Operator            = 'le'
                            Value               = 180
                            BackgroundColor     = 'LimeGreen'
                            FailBackgroundColor = 'Salmon'
                            HighlightHeaders    = 'PasswordLastSetDays', 'PasswordLastSet'
                        }

                        New-HTMLTableCondition @newHTMLTableConditionSplat
                    }
                }

                New-HTMLTabPanel {
                    foreach ($Account in $AccountData['Data'][$Domain].Values) {
                        $DomainControllers = $Account.DomainControllers
                        $GlobalCatalogs = $Account.GlobalCatalogs

                        $CountMatched = 0
                        $CountNotMatched = 0
                        $CountTotal = 0
                        $NewestPassword = $DomainControllers.Values.PasswordLastSet | Sort-Object -Descending | Select-Object -First 1
                        foreach ($Password in $DomainControllers.Values.PasswordLastSet) {
                            if ($Password -eq $NewestPassword) {
                                $CountMatched++
                            } else {
                                $CountNotMatched++
                            }
                            $CountTotal++
                        }

                        if ($NewestPassword) {
                            $TimeSinceLastChange = ($Today) - $NewestPassword
                        } else {
                            $TimeSinceLastChange = $null
                        }

                        $CountMatchedGC = 0
                        $CountNotMatchedGC = 0
                        $CountTotalGC = 0
                        $NewestPasswordGC = $GlobalCatalogs.Values.PasswordLastSet | Sort-Object -Descending | Select-Object -First 1
                        foreach ($Password in $GlobalCatalogs.Values.PasswordLastSet) {
                            if ($Password -eq $NewestPasswordGC) {
                                $CountMatchedGC++
                            } else {
                                $CountNotMatchedGC++
                            }
                            $CountTotalGC++
                        }

                        if ($NewestPasswordGC) {
                            $TimeSinceLastChangeGC = ($Today) - $NewestPasswordGC
                        } else {
                            $TimeSinceLastChangeGC = $null
                        }

                        New-HTMLTab -Name $Account.FullInformation.SamAccountName {
                            New-HTMLSection -Invisible {

                                # DC Status
                                New-HTMLSection -Invisible {
                                    New-HTMLPanel -Invisible {
                                        New-HTMLStatus {
                                            $Percentage = "$([math]::Round(($CountMatched / $CountTotal) * 100))%"
                                            if ($Percentage -eq '100%') {
                                                $BackgroundColor = '#0ef49b'
                                                $Icon = 'Good'
                                            } elseif ($Percentage -ge '70%') {
                                                $BackgroundColor = '#d2dc69'
                                                $Icon = 'Bad'
                                            } elseif ($Percentage -ge '30%') {
                                                $BackgroundColor = '#faa04b'
                                                $Icon = 'Bad'
                                            } elseif ($Percentage -ge '10%') {
                                                $BackgroundColor = '#ff9035'
                                                $Icon = 'Bad'
                                            } elseif ($Percentage -ge '0%') {
                                                $BackgroundColor = '#ff5a64'
                                                $Icon = 'Dead'
                                            }

                                            if ($Icon -eq 'Dead') {
                                                $IconType = '&#x2620'
                                            } elseif ($Icon -eq 'Bad') {
                                                $IconType = '&#x2639'
                                            } elseif ($Icon -eq 'Good') {
                                                $IconType = '&#x2714'
                                            }

                                            New-HTMLStatusItem -Name 'Domain Controller' -Status "Synchronized $CountMatched/$CountTotal ($Percentage)" -BackgroundColor $BackgroundColor -IconHex $IconType
                                            $newHTMLToastSplat = @{
                                                TextHeader   = 'Kerberos password date'
                                                Text         = "Password set on: $NewestPassword (Days: $($TimeSinceLastChange.Days), Hours: $($TimeSinceLastChange.Hours), Minutes: $($TimeSinceLastChange.Minutes))"
                                                BarColorLeft = 'AirForceBlue'
                                                IconSolid    = 'info-circle'
                                                IconColor    = 'AirForceBlue'
                                            }
                                            if ($TimeSinceLastChange.Days -ge 180) {
                                                $newHTMLToastSplat['BarColorLeft'] = 'Salmon'
                                                $newHTMLToastSplat['IconSolid'] = 'exclamation-triangle'
                                                $newHTMLToastSplat['IconColor'] = 'Salmon'
                                                $newHTMLToastSplat['TextHeader'] = 'Kerberos password date (outdated)'
                                            }
                                            New-HTMLToast @newHTMLToastSplat
                                        }
                                    }
                                }
                                # GC Status
                                New-HTMLSection -Invisible {
                                    New-HTMLStatus {
                                        $Percentage = "$([math]::Round(($CountMatchedGC / $CountTotalGC) * 100))%"
                                        if ($Percentage -eq '100%') {
                                            $BackgroundColor = '#0ef49b'
                                            $Icon = 'Good'
                                        } elseif ($Percentage -ge '70%') {
                                            $BackgroundColor = '#d2dc69'
                                            $Icon = 'Bad'
                                        } elseif ($Percentage -ge '30%') {
                                            $BackgroundColor = '#faa04b'
                                            $Icon = 'Bad'
                                        } elseif ($Percentage -ge '10%') {
                                            $BackgroundColor = '#ff9035'
                                            $Icon = 'Bad'
                                        } elseif ($Percentage -ge '0%') {
                                            $BackgroundColor = '#ff5a64'
                                            $Icon = 'Dead'
                                        }

                                        if ($Icon -eq 'Dead') {
                                            $IconType = '&#x2620'
                                        } elseif ($Icon -eq 'Bad') {
                                            $IconType = '&#x2639'
                                        } elseif ($Icon -eq 'Good') {
                                            $IconType = '&#x2714'
                                        }

                                        New-HTMLStatusItem -Name 'Global Catalogs' -Status "Synchronized $CountMatchedGC/$CountTotalGC ($Percentage)" -BackgroundColor $BackgroundColor -IconHex $IconType
                                        $newHTMLToastSplat = @{
                                            TextHeader   = 'Kerberos password date'
                                            Text         = "Password set on: $NewestPasswordGC (Days: $($TimeSinceLastChangeGC.Days), Hours: $($TimeSinceLastChangeGC.Hours), Minutes: $($TimeSinceLastChangeGC.Minutes))"
                                            BarColorLeft = 'AirForceBlue'
                                            IconSolid    = 'info-circle'
                                            IconColor    = 'AirForceBlue'
                                        }
                                        if ($TimeSinceLastChange.Days -ge 180) {
                                            $newHTMLToastSplat['BarColorLeft'] = 'Salmon'
                                            $newHTMLToastSplat['IconSolid'] = 'exclamation-triangle'
                                            $newHTMLToastSplat['IconColor'] = 'Salmon'
                                            $newHTMLToastSplat['TextHeader'] = 'Kerberos password date (outdated)'
                                        }
                                        New-HTMLToast @newHTMLToastSplat
                                    }
                                }

                            }


                            #$DataAccount = $Account.FullInformation

                            New-HTMLSection -HeaderText "Domain Controllers for '$($Account.FullInformation.SamAccountName)'" {
                                New-HTMLTable -DataTable $DomainControllers.Values {
                                    New-HTMLTableCondition -Name 'Status' -Operator eq -Value 'OK' -BackgroundColor '#0ef49b' -FailBackgroundColor '#ff5a64'
                                } -Filtering -DataStore JavaScript
                            }
                            New-HTMLSection -HeaderText "Global Catalogs for account '$($Account.FullInformation.SamAccountName)'" {
                                New-HTMLTable -DataTable $GlobalCatalogs.Values {
                                    New-HTMLTableCondition -Name 'Status' -Operator eq -Value 'OK' -BackgroundColor '#0ef49b' -FailBackgroundColor '#ff5a64'
                                } -Filtering -DataStore JavaScript
                            }
                        }
                    }
                }

                $KerberosAccount = $AccountData['Data'][$Domain]['krbtgt'].FullInformation
                $NewestPassword = $KerberosAccount.PasswordLastSetDays

                New-HTMLSection -HeaderText "Critical Accounts for domain '$Domain'" {
                    New-HTMLContainer {
                        New-HTMLPanel {
                            New-HTMLText -Text "Critical accounts that should have their password changed after every kerberos password change."
                            New-HTMLList {
                                New-HTMLListItem -Text 'Domain Admins'
                                New-HTMLListItem -Text 'Enterprise Admins'
                            }
                        }
                        New-HTMLPanel {
                            New-HTMLTable -DataTable $AccountData['CriticalAccounts'][$Domain] {
                                if ($null -ne $NewestPassword) {
                                    New-HTMLTableCondition -Name 'PasswordLastSetDays' -Operator le -Value $NewestPassword -ComparisonType number -BackgroundColor MintGreen -FailBackgroundColor Salmon -HighlightHeaders PasswordLastSetDays, PasswordLastSet
                                }
                            } -Filtering -DataStore JavaScript -ScrollX
                        }
                    }
                }
            }

        }
    } -Online:$Online.IsPresent -ShowHTML:(-not $HideHTML) -FilePath $FilePath

    if ($PassThru) {
        $AccountData
    }
    Write-Verbose -Message "Show-WinADKerberosAccount - HTML Report generated"
}