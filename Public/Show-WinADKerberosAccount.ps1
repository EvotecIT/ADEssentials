function Show-WinADKerberosAccount {
    [CmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $Online,
        [switch] $HideHTML,
        [string] $FilePath
    )
    $Today = Get-Date
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'

    $AccountData = Get-WinADKerberosAccount -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains

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

        foreach ($Domain in $AccountData.Keys) {
            New-HTMLTab -Name $Domain {
                New-HTMLPanel {
                    New-HTMLTable -DataTable $AccountData[$Domain].Values.FullInformation -Filtering -DataStore JavaScript -ScrollX {
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
                    foreach ($Account in $AccountData[$Domain].Values) {
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

                        $TimeSinceLastChange = ($Today) - $NewestPassword

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

                        $TimeSinceLastChangeGC = ($Today) - $NewestPasswordGC

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

                            New-HTMLSection -HeaderText 'Domain Controllers by Domain' {
                                New-HTMLTable -DataTable $DomainControllers.Values {

                                } -Filtering -DataStore JavaScript
                            }
                            New-HTMLSection -HeaderText 'Global Catalogs in Forest' {
                                New-HTMLTable -DataTable $GlobalCatalogs.Values {

                                } -Filtering -DataStore JavaScript
                            }
                        }
                    }
                }
            }

        }
    } -Online:$Online.IsPresent -ShowHTML:(-not $HideHTML) -FilePath $FilePath
}