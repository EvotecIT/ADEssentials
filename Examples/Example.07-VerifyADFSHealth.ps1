Import-Module .\ADEssentials.psd1 -Force

# Option with autodetection
$T = Get-WinADDFSHealth -Verbose -Domains 'ad.evotec.xyz'
$T | Format-Table -AutoSize *

# Option without autodetection, with skip of gpo
$Output = Get-WinADDFSHealth -Verbose -Domains 'ad.evotec.xyz' -DomainControllers 'AD1.AD.EVOTEC.XYZ', 'AD2.AD.EVOTEC.XYZ' -SkipGPO:$true -SkipAutodetection
$Output | Format-Table -AutoSize *