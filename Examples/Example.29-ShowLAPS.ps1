Import-Module .\ADEssentials.psd1 -Force
Import-Module C:\Support\GitHub\PSWriteHTML\PSWriteHTML.psd1 -force

#$LAPS = Get-WinADBitlockerLapsSummary -LapsOnly
#$LAPS | Format-Table *

Invoke-ADEssentials -Type Laps -Online #, LapsACL, LapsAndBitLocker -Online

#$LAPSComputers = Get-WinADComputerACLLAPS
#$LAPSComputers | Format-Table *

#Get-WinADForestOptionalFeatures | Format-Table