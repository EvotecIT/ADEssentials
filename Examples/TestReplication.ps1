$List = Get-ADReplicationUpToDatenessVectorTable -Scope Domain -Target 'abb.com' -Verbose


$Cache = @{}
$List = Get-ADGroup -Filter "*"
foreach ($Group in $List) {
    $cache[$group.Name] = $group
}

function New-LocalAdminAndRDPGroup {
    param(
        $AdminGroupPath, $RDPGroupPath, $computers, $Cache
    )


    #Create local Admin group
    ForEach ($server in $computers) {
        $HostName = $server.Name

        $Name = "xxx-$($HostName)_admins"

        if (-not $Cache[$Name]) {
            Try {
                $Param = @{
                    Name           = $Name
                    samAccountName = "xxx-$($HostName)_admins"
                    Description    = "Local Administrator Access for $HostName"
                    Path           = $AdminGroupPath
                    GroupCategory  = "Security"
                    GroupScope     = "DomainLocal"
                }
                New-ADGroup @Param -ErrorAction Stop
            } Catch {
                Write-Host "$HostName - Local Group Error: $($_.Exception.message)"
            }
        }
        $Name = "xxx-$($HostName)_rdp"
        if (-not $Cache[$Name]) {
            #Create local RDP group
            Try {
                $Param = @{
                    Name           = $Name
                    samAccountName = "xxx-$($HostName)_rdp"
                    Description    = "RDP Access for $HostName"
                    Path           = $RDPGroupPath
                    GroupCategory  = "Security"
                    GroupScope     = "DomainLocal"
                }
                New-ADGroup @Param -ErrorAction Stop
            } Catch {
                Write-Host "$HostName RDP group exists"
            }
        }
    }
}