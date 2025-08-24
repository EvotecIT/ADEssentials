Import-Module .\ADEssentials.psd1 -Force

Show-WinADDHCPSummary -Verbose -FilePath "$PSScriptRoot\Reports\DHCPSummaryTest.html" -PassThru -TestMode