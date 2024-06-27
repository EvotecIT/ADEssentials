function Get-WinDnsServerDiagnostics {
    [CmdLetBinding()]
    param(
        [string] $ComputerName
    )

    $DnsServerDiagnostics = Get-DnsServerDiagnostics -ComputerName $ComputerName
    foreach ($_ in $DnsServerDiagnostics) {
        [PSCustomObject] @{
            FilterIPAddressList                  = $_.FilterIPAddressList
            Answers                              = $_.Answers
            EnableLogFileRollover                = $_.EnableLogFileRollover
            EnableLoggingForLocalLookupEvent     = $_.EnableLoggingForLocalLookupEvent
            EnableLoggingForPluginDllEvent       = $_.EnableLoggingForPluginDllEvent
            EnableLoggingForRecursiveLookupEvent = $_.EnableLoggingForRecursiveLookupEvent
            EnableLoggingForRemoteServerEvent    = $_.EnableLoggingForRemoteServerEvent
            EnableLoggingForServerStartStopEvent = $_.EnableLoggingForServerStartStopEvent
            EnableLoggingForTombstoneEvent       = $_.EnableLoggingForTombstoneEvent
            EnableLoggingForZoneDataWriteEvent   = $_.EnableLoggingForZoneDataWriteEvent
            EnableLoggingForZoneLoadingEvent     = $_.EnableLoggingForZoneLoadingEvent
            EnableLoggingToFile                  = $_.EnableLoggingToFile
            EventLogLevel                        = $_.EventLogLevel
            FullPackets                          = $_.FullPackets
            LogFilePath                          = $_.LogFilePath
            MaxMBFileSize                        = $_.MaxMBFileSize
            Notifications                        = $_.Notifications
            Queries                              = $_.Queries
            QuestionTransactions                 = $_.QuestionTransactions
            ReceivePackets                       = $_.ReceivePackets
            SaveLogsToPersistentStorage          = $_.SaveLogsToPersistentStorage
            SendPackets                          = $_.SendPackets
            TcpPackets                           = $_.TcpPackets
            UdpPackets                           = $_.UdpPackets
            UnmatchedResponse                    = $_.UnmatchedResponse
            Update                               = $_.Update
            UseSystemEventLog                    = $_.UseSystemEventLog
            WriteThrough                         = $_.WriteThrough
            GatheredFrom                         = $ComputerName
        }
    }
}