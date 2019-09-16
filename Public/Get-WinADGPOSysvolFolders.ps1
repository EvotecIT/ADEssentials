function Get-WinADGPOSysvolFolders {
    [alias('Get-WinADGPOSysvol')]
    [cmdletBinding()]
    param(
        [Array] $GPOs,
        [string] $Domain = $EnV:USERDNSDOMAIN,
        [Array] $ComputerName
    )

    if (-not $ComputerName) {
        $ComputerName = Get-ADDomainController -Filter * -Server $Domain -ErrorAction SilentlyContinue
    } else {
        $ComputerName = foreach ($_ in $ComputerName) {
            Get-ADDomainController -Identity $_ -ErrorAction SilentlyContinue -Server $Domain
        }
    }

    if (-not $GPOs) {
        [Array]$GPOs = @(Get-GPO -All -Domain $Domain)
    }

    foreach ($Server in $ComputerName) {
        $Differences = @{ }
        $SysvolHash = @{ }

        $GPOGUIDS = $GPOs.ID.GUID

        # if (-not $Sysvol) {
        try {
            $SYSVOL = Get-ChildItem -Path "\\$Server\SYSVOL\$Domain\Policies" -ErrorAction Stop
        } catch {
            $Sysvol = $Null
        }
        #}
        foreach ($_ in $SYSVOL) {
            $GUID = $_.Name -replace '{' -replace '}'
            $SysvolHash[$GUID] = $_
        }
        $Files = $SYSVOL.Name -replace '{' -replace '}'
        if ($Files -ne '') {
            $Comparing = Compare-Object -ReferenceObject $GPOGUIDS -DifferenceObject $Files -IncludeEqual
            foreach ($_ in $Comparing) {
                if ($_.SideIndicator -eq '==') {
                    $Found = 'Exists'
                } elseif ($_.SideIndicator -eq '<=') {
                    $Found = 'Not available on SYSVOL'
                } else {
                    $Found = 'Orphaned GPO'
                }
                $Differences[$_.InputObject] = $Found
            }
        } else {

        }
        $GPOSummary = @(
            foreach ($GPO in $GPOS) {

                if ($null -ne $SysvolHash[$GPO.Id.GUID].FullName) {
                    $ACL = Get-Acl -Path $SysvolHash[$GPO.Id.GUID].FullName
                } else {
                    $ACL = $null
                }
                [PSCustomObject] @{
                    DisplayName      = $GPO.DisplayName
                    DomainName       = $GPO.DomainName
                    SysvolServer     = $Server.HostName
                    SysvolStatus     = if ($null -eq $Differences[$GPO.Id.Guid]) { 'Not available on SYSVOL' } else { $Differences[$GPO.Id.Guid] }
                    Owner            = $GPO.Owner
                    FileOwner        = $ACL.Owner
                    Id               = $GPO.Id.Guid
                    GpoStatus        = $GPO.GpoStatus
                    Description      = $GPO.Description
                    CreationTime     = $GPO.CreationTime
                    ModificationTime = $GPO.ModificationTime
                    UserVersion      = $GPO.UserVersion
                    ComputerVersion  = $GPO.ComputerVersion
                    WmiFilter        = $GPO.WmiFilter
                }
            }
            foreach ($_ in $Differences.Keys) {
                if ($Differences[$_] -eq 'Orphaned GPO') {
                    if ($SysvolHash[$_].BaseName -notcontains 'PolicyDefinitions') {

                        if ($null -ne $SysvolHash[$_].FullName) {
                            $ACL = Get-Acl -Path $SysvolHash[$_].FullName
                        } else {
                            $ACL = $null
                        }

                        [PSCustomObject] @{
                            DisplayName      = $SysvolHash[$_].BaseName
                            DomainName       = $Domain
                            SysvolServer     = $Server.HostName
                            SysvolStatus     = $Differences[$GPO.Id.Guid]
                            Owner            = $ACL.Owner
                            FileOwner        = $ACL.Owner
                            Id               = $_
                            GpoStatus        = 'Orphaned'
                            Description      = $null
                            CreationTime     = $SysvolHash[$_].CreationTime
                            ModificationTime = $SysvolHash[$_].LastWriteTime
                            UserVersion      = $null
                            ComputerVersion  = $null
                            WmiFilter        = $null
                        }
                    }
                }
            }
        )
        $GPOSummary
    }
}