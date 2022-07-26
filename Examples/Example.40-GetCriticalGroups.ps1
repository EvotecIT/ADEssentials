Import-Module .\ADEssentials.psd1 -Force

Show-WinADGroupCritical -ReportPath "$PSScriptRoot\GroupMembership-CriticalGroups_$(Get-Date -f yyyy-MM-dd_HHmmss).html"