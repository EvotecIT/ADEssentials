Import-Module .\ADEssentials.psd1 -Force

$Object = Show-WinADSIDHistory -Online -PassThru
$Object