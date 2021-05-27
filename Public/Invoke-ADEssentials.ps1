function Invoke-ADEssentials {
    [cmdletBinding()]
    param(
        [string] $FilePath,
        [Parameter(Position = 0)][string[]] $Type,
        [switch] $PassThru,
        [switch] $HideHTML,
        [switch] $HideSteps,
        [switch] $ShowError,
        [switch] $ShowWarning,
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $Online
    )
    Reset-ADEssentialsStatus

    $Script:AllUsers = [ordered] @{}
    $Script:Cache = [ordered] @{}
    $Script:Reporting = [ordered] @{}
    $Script:Reporting['Version'] = Get-GitHubVersion -Cmdlet 'Invoke-ADEssentials' -RepositoryOwner 'evotecit' -RepositoryName 'ADEssentials'
    $Script:Reporting['Settings'] = @{
        ShowError   = $ShowError.IsPresent
        ShowWarning = $ShowWarning.IsPresent
        HideSteps   = $HideSteps.IsPresent
    }

    Write-Color '[i]', "[ADEssentials] ", 'Version', ' [Informative] ', $Script:Reporting['Version'] -Color Yellow, DarkGray, Yellow, DarkGray, Magenta

    # Verify requested types are supported
    $Supported = [System.Collections.Generic.List[string]]::new()
    [Array] $NotSupported = foreach ($T in $Type) {
        if ($T -notin $Script:ADEssentialsConfiguration.Keys ) {
            $T
        } else {
            $Supported.Add($T)
        }
    }
    if ($Supported) {
        Write-Color '[i]', "[ADEssentials] ", 'Supported types', ' [Informative] ', "Chosen by user: ", ($Supported -join ', ') -Color Yellow, DarkGray, Yellow, DarkGray, Yellow, Magenta
    }
    if ($NotSupported) {
        Write-Color '[i]', "[ADEssentials] ", 'Not supported types', ' [Informative] ', "Following types are not supported: ", ($NotSupported -join ', ') -Color Yellow, DarkGray, Yellow, DarkGray, Yellow, Magenta
        Write-Color '[i]', "[ADEssentials] ", 'Not supported types', ' [Informative] ', "Please use one/multiple from the list: ", ($Script:ADEssentialsConfiguration.Keys -join ', ') -Color Yellow, DarkGray, Yellow, DarkGray, Yellow, Magenta
        return
    }
    $DisplayForest = if ($Forest) { $Forest } else { 'Not defined. Using current one' }
    $DisplayIncludedDomains = if ($IncludeDomains) { $IncludeDomains -join "," } else { 'Not defined. Using all domains of forest' }
    $DisplayExcludedDomains = if ($ExcludeDomains) { $ExcludeDomains -join ',' } else { 'No exclusions provided' }
    Write-Color '[i]', "[ADEssentials] ", 'Domain Information', ' [Informative] ', "Forest: ", $DisplayForest -Color Yellow, DarkGray, Yellow, DarkGray, Yellow, Magenta
    Write-Color '[i]', "[ADEssentials] ", 'Domain Information', ' [Informative] ', "Included Domains: ", $DisplayIncludedDomains -Color Yellow, DarkGray, Yellow, DarkGray, Yellow, Magenta
    Write-Color '[i]', "[ADEssentials] ", 'Domain Information', ' [Informative] ', "Excluded Domains: ", $DisplayExcludedDomains -Color Yellow, DarkGray, Yellow, DarkGray, Yellow, Magenta

    # Lets make sure we only enable those types which are requestd by user
    if ($Type) {
        foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
            $Script:ADEssentialsConfiguration[$T].Enabled = $false
        }
        # Lets enable all requested ones
        foreach ($T in $Type) {
            $Script:ADEssentialsConfiguration[$T].Enabled = $true
        }
    }


    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation
    foreach ($Domain in $ForestInformation.Domains) {
        $QueryServer = $ForestInformation['QueryServers']["$Domain"].HostName[0]

        $Properties = @(
            'DistinguishedName', 'mail', 'LastLogonDate', 'PasswordLastSet', 'DisplayName', 'Manager', 'Description',
            'PasswordNeverExpires', 'PasswordNotRequired', 'PasswordExpired', 'UserPrincipalName', 'SamAccountName', 'CannotChangePassword',
            'TrustedForDelegation', 'TrustedToAuthForDelegation', 'msExchMailboxGuid', 'msExchRemoteRecipientType', 'msExchRecipientTypeDetails',
            'msExchRecipientDisplayType', 'pwdLastSet', "msDS-UserPasswordExpiryTimeComputed",
            'WhenCreated', 'WhenChanged'
        )
        $AllUsers[$Domain] = Get-ADUser -Filter * -Server $QueryServer -Properties $Properties
    }
    if (-not $Script:Cache) {
        $Script:Cache = @{}
        foreach ($Domain in $AllUsers.Keys) {
            foreach ($U in $AllUsers[$Domain]) {
                $Script:Cache[$U.DistinguishedName] = $U
            }
        }
        #foreach ($Domain in $AllComputers.Keys) {
        #    foreach ($C in $AllComputers[$Domain]) {
        #        $Script:Cache[$C.DistinguishedName] = $C
        #    }
        #}
    }


    # Build data
    foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
        if ($Script:ADEssentialsConfiguration[$T].Enabled -eq $true) {
            $Script:Reporting[$T] = [ordered] @{
                Name              = $Script:ADEssentialsConfiguration[$T].Name
                ActionRequired    = $null
                Data              = $null
                Exclusions        = $null
                WarningsAndErrors = $null
                Time              = $null
                Summary           = $null
                Variables         = Copy-Dictionary -Dictionary $Script:ADEssentialsConfiguration[$T]['Variables']
            }
            if ($Exclusions) {
                if ($Exclusions -is [scriptblock]) {
                    $Script:Reporting[$T]['ExclusionsCode'] = $Exclusions
                }
                if ($Exclusions -is [Array]) {
                    $Script:Reporting[$T]['Exclusions'] = $Exclusions
                }
            }

            $TimeLogADEssentials = Start-TimeLog
            Write-Color -Text '[i]', '[Start] ', $($Script:ADEssentialsConfiguration[$T]['Name']) -Color Yellow, DarkGray, Yellow
            $OutputCommand = Invoke-Command -ScriptBlock $Script:ADEssentialsConfiguration[$T]['Execute'] -WarningVariable CommandWarnings -ErrorVariable CommandErrors -ArgumentList $Forest, $ExcludeDomains, $IncludeDomains
            if ($OutputCommand -is [System.Collections.IDictionary]) {
                # in some cases the return will be wrapped in Hashtable/orderedDictionary and we need to handle this without an array
                $Script:Reporting[$T]['Data'] = $OutputCommand
            } else {
                # since sometimes it can be 0 or 1 objects being returned we force it being an array
                $Script:Reporting[$T]['Data'] = [Array] $OutputCommand
            }
            Invoke-Command -ScriptBlock $Script:ADEssentialsConfiguration[$T]['Processing']
            $Script:Reporting[$T]['WarningsAndErrors'] = @(
                if ($ShowWarning) {
                    foreach ($War in $CommandWarnings) {
                        [PSCustomObject] @{
                            Type       = 'Warning'
                            Comment    = $War
                            Reason     = ''
                            TargetName = ''
                        }
                    }
                }
                if ($ShowError) {
                    foreach ($Err in $CommandErrors) {
                        [PSCustomObject] @{
                            Type       = 'Error'
                            Comment    = $Err
                            Reason     = $Err.CategoryInfo.Reason
                            TargetName = $Err.CategoryInfo.TargetName
                        }
                    }
                }
            )
            $TimeEndADEssentials = Stop-TimeLog -Time $TimeLogADEssentials -Option OneLiner
            $Script:Reporting[$T]['Time'] = $TimeEndADEssentials
            Write-Color -Text '[i]', '[End  ] ', $($Script:ADEssentialsConfiguration[$T]['Name']), " [Time to execute: $TimeEndADEssentials]" -Color Yellow, DarkGray, Yellow, DarkGray
        }
    }


    New-HTML -Author 'Przemysław Kłys' -TitleText 'ADEssentials Report' {
        New-HTMLTabStyle -BorderRadius 0px -TextTransform capitalize -BackgroundColorActive SlateGrey
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

        if ($Type.Count -eq 1) {
            foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
                if ($Script:ADEssentialsConfiguration[$T].Enabled -eq $true) {
                    if ($Script:ADEssentialsConfiguration[$T]['Summary']) {
                        $Script:Reporting[$T]['Summary'] = Invoke-Command -ScriptBlock $Script:ADEssentialsConfiguration[$T]['Summary']
                    }
                    & $Script:ADEssentialsConfiguration[$T]['Solution']
                }
            }
        } else {
            foreach ($T in $Script:ADEssentialsConfiguration.Keys) {
                if ($Script:ADEssentialsConfiguration[$T].Enabled -eq $true) {
                    if ($Script:ADEssentialsConfiguration[$T]['Summary']) {
                        $Script:Reporting[$T]['Summary'] = Invoke-Command -ScriptBlock $Script:ADEssentialsConfiguration[$T]['Summary']
                    }
                    New-HTMLTab -Name $Script:ADEssentialsConfiguration[$T]['Name'] {
                        & $Script:ADEssentialsConfiguration[$T]['Solution']
                    }
                }
            }
        }
    } -Online:$Online.IsPresent -ShowHTML:(-not $HideHTML) -FilePath $FilePath


    Reset-ADEssentialsStatus
}

[scriptblock] $SourcesAutoCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $Script:ADEssentialsConfiguration.Keys | Sort-Object | Where-Object { $_ -like "*$wordToComplete*" }
}

Register-ArgumentCompleter -CommandName Invoke-ADEssentials -ParameterName Type -ScriptBlock $SourcesAutoCompleter