function Convert-TrustForestTrustInfo {
    [CmdletBinding()]
    param(
        [byte[]] $msDSTrustForestTrustInfo
    )
    # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/66387402-cb2b-490c-bf2a-f4ad687397e4
    $Flags = [ordered] @{
        '0'                      = 'Enabled'
        'LsaTlnDisabledNew'      = 'Not yet enabled'
        'LsaTlnDisabledAdmin'    = 'Disabled by administrator'
        'LsaTlnDisabledConflict' = 'Disabled due to a conflict with another trusted domain'
        'LsaSidDisabledAdmin'    = 'Disabled for SID, NetBIOS, and DNS name–based matches by the administrator'
        'LsaSidDisabledConflict' = 'Disabled for SID, NetBIOS, and DNS name–based matches due to a SID or DNS name–based conflict with another trusted domain'
        'LsaNBDisabledAdmin'     = 'Disabled for NetBIOS name–based matches by the administrator'
        'LsaNBDisabledConflict'  = 'Disabled for NetBIOS name–based matches due to a NetBIOS domain name conflict with another trusted domain'
    }

    if ($msDSTrustForestTrustInfo) {
        $Read = Get-ForestTrustInfo -Byte $msDSTrustForestTrustInfo
        $ForestTrustDomainInfo = [ordered]@{}
        [Array] $Records = foreach ($Record in $Read.Records) {
            if ($Record.RecordType -ne 'ForestTrustDomainInfo') {
                # ForestTrustTopLevelName, ForestTrustTopLevelNameEx
                if ($Record.RecordType -eq 'ForestTrustTopLevelName') {
                    $Type = 'Included'
                } else {
                    $Type = 'Excluded'
                }
                [PSCustomObject] @{
                    DnsName     = $null
                    NetbiosName = $null
                    Sid         = $null
                    Type        = $Type
                    Suffix      = $Record.ForestTrustData
                    Status      = $Flags["$($Record.Flags)"]
                    StatusFlag  = $Record.Flags
                    WhenCreated = $Record.Timestamp
                }
            } else {
                $ForestTrustDomainInfo['DnsName'] = $Record.ForestTrustData.DnsName
                $ForestTrustDomainInfo['NetbiosName'] = $Record.ForestTrustData.NetbiosName
                $ForestTrustDomainInfo['Sid'] = $Record.ForestTrustData.Sid
            }
        }
        foreach ($Record in $Records) {
            $Record.DnsName = $ForestTrustDomainInfo['DnsName']
            $Record.NetbiosName = $ForestTrustDomainInfo['NetbiosName']
            $Record.Sid = $ForestTrustDomainInfo['Sid']
        }
        $Records
    }
}