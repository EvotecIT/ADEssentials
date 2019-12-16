Import-Module .\ADEssentials.psd1 -Force


$SysVolOutput = Get-WinADGPOSysvolFolders
$SysVolOutput | Format-Table -a *