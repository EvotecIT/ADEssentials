Import-Module .\ADEssentials.psd1 -Force

$T = Get-WinADDFSHealth -Verbose -Domains 'ad.evotec.xyz' #-DomainControllers 'adrodc'
$T | Format-Table -a