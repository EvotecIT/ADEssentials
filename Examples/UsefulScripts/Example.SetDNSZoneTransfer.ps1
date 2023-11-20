
$ZoneNames = "ad.evotec.xyz"
$DnsServer = "AD1"

foreach ($ZoneName in $ZoneNames) {
    $setDnsServerPrimaryZoneSplat = @{
        Name              = $zoneName
        ComputerName      = $DnsServer
        SecureSecondaries = 'TransferToSecureServers'
        SecondaryServers  = @(
            "192.168.1.10", "192.168.1.11"
        )
        Notify            = 'NotifyServers'
        NotifyServers     = @(
            "192.168.1.10", "192.168.1.11"
        )
        PassThru          = $true
    }
    # Set the zone transfer settings
    Set-DnsServerPrimaryZone @setDnsServerPrimaryZoneSplat

    <# Set the zone transfer settings reverting to no zone transfer
    $setDnsServerPrimaryZoneSplat = @{
        Name              = $zoneName
        ComputerName      = $DnsServer
        SecureSecondaries = 'NoTransfer'
        Notify            = 'NoNotify'
        PassThru          = $true
    }

    Set-DnsServerPrimaryZone @setDnsServerPrimaryZoneSplat
    #>
}