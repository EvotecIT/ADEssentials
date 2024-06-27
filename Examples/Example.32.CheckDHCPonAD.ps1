Import-Module .\ADEssentials.psd1 -Force

$Output = Get-WinADDHCP
$Output | Out-HtmlView -Online -SearchBuilder