Import-Module .\ADEssentials.psd1 -Force

$Objects = Get-WinADPrivilegedObjects -Verbose
$Objects | Format-Table *

$Objects | Out-HtmlView {
    New-HTMLTableCondition -Name "IsOrphaned" -Value $False -BackgroundColor TeaGreen
    New-HTMLTableCondition -Name "IsOrphaned" -Value $True -BackgroundColor Red
    New-HTMLTableCondition -Name "IsCriticalSystemObject" -Value $True -BackgroundColor TeaGreen
    New-HTMLTableCondition -Name "IsCriticalSystemObject" -Value $False -BackgroundColor Red
}