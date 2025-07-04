Import-Module .\ADEssentials.psd1 -Force

Show-WinADDHCPSummary -TestMode -Verbose -FilePath "$PSScriptRoot\Reports\DHCPSummaryTest.html" -PassThru