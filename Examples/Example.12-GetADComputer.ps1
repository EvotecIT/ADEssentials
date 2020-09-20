Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

$Computers = @(
    'ADPreview2019.ad.evotec.pl'
    'ADRODC.ad.evotec.pl'
    'EVOWIN' # this will resolve as it's computer in same domain
    'ADTEST' # this will not resolve as it's DC in another forest
    'ADTEST.test.evotec.pl'
    'adtest@test.evotec.pl'
)

$Output = Get-WinADObject -Identity $Computers -Verbose
$Output | Format-Table *

#$Ident = 'ADPreview2019.ad.evotec.pl'
#$Ident -split '\.',2