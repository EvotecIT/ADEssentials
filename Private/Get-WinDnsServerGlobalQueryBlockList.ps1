function Get-WinDnsServerGlobalQueryBlockList {
    [CmdLetBinding()]
    param(
        [string[]] $ComputerName,
        [string] $Domain = $ENV:USERDNSDOMAIN,
        [switch] $Formatted,
        [string] $Splitter = ', '
    )
    if ($Domain -and -not $ComputerName) {
        $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).HostName
    }
    foreach ($Computer in $ComputerName) {
        $ServerGlobalQueryBlockList = Get-DnsServerGlobalQueryBlockList -ComputerName $Computer
        foreach ($_ in $ServerGlobalQueryBlockList) {
            if ($Formatted) {
                [PSCustomObject] @{
                    Enable       = $_.Enable
                    List         = $_.List -join $Splitter
                    GatheredFrom = $Computer
                }
            } else {
                [PSCustomObject] @{
                    Enable       = $_.Enable
                    List         = $_.List
                    GatheredFrom = $Computer
                }
            }
        }
    }
}