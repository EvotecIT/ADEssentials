Function Get-DomainControllerUpTime($domainNameInput) {
    Write-Verbose "..running function Get-DomainControllerUpTime"

    If ((Test-Connection $domainNameInput -Count 1 -Quiet) -eq $True) {
        try {
            $W32OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $domainNameInput -ErrorAction SilentlyContinue
            $timespan = $W32OS.ConvertToDateTime($W32OS.LocalDateTime) – $W32OS.ConvertToDateTime($W32OS.LastBootUpTime)
            [int]$uptime = "{0:00}" -f $timespan.TotalHours
        } catch [exception] {
            $uptime = 'WMI Failure'
        }

    }

    Else {
        $uptime = '0'
    }

    return $uptime
}

#Get-DomainControllerUpTime -domainNameInput 'ad1'
