function Remove-WinADDNSRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]] $Name,
        [Parameter(Mandatory)][string] $ZoneName,
        [Parameter(Mandatory)][string] $ServerName,
        [string] $LogPath
    )
    $LogFile = "C:\Temp\Log.txt"


    $ZoneName = "test.zone1"
    $ServerName = "AD0.ad.evotec.xyz"

    [Array] $FoundToDelete = foreach ($FullName in $RecordsToDelete) {
        $Name = $FullName.Split(".")[0]

        $Object = "Checking record $FullName / $Name in $ZoneName zone"
        Write-Host -Object $Object
        $Object | Out-File -FilePath $LogFile -Append

        try {
            $FoundRecord = Get-DnsServerResourceRecord -ComputerName $ServerName -Name $Name -ZoneName $ZoneName -RRType A -ErrorAction Stop
            if ($FoundRecord) {
                $FoundRecord
            }
        } catch {
            $Object = "Record $Name / $FullName not found"
            Write-Host -Object $Object
            $Object | Out-File -FilePath $LogFile -Append
        }
    }
    foreach ($Record in $FoundToDelete) {

    }
    foreach ($Record in $FoundToDelete) {
        $Object = "Removing record $($Record.HostName) / $($Record.RecordType) from $($ZoneName) zone"
        Write-Host -Object $Object
        $Object | Out-File -Path $LogFile -Append
        try {
            Remove-DnsServerResourceRecord -ComputerName $ServerName -ZoneName $ZoneName -Name $Record.HostName -RRType $Record.RecordType -Force -ErrorAction Stop -WhatIf
            $Object = "Record $($Record.HostName) / $($Record.RecordType) removed from $($ZoneName) zone"
            Write-Host -Object $Object
            $Object | Out-File -FilePath $LogFile -Append
        } catch {
            $Object = "Failed to remove record $($Record.HostName) / $($Record.RecordType) from $($ZoneName) zone. Error: $($_.Exception.Message)"
            Write-Host -Object $Object
            $Object | Out-File -FilePath $LogFile -Append
        }
    }
}