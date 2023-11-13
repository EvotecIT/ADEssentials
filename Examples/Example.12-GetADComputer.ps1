Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

# $Computers = @(
#     'EVOWIN'
#     'ADPreview2019.ad.evotec.pl'
#     'ADRODC.ad.evotec.pl'
#     'EVOWIN' # this will resolve as it's computer in same domain
#     'ADTEST' # this will not resolve as it's DC in another forest
#     'ADTEST.test.evotec.pl'
#     'adtest@test.evotec.pl'
#     'test.test'
#     'test7.ad.evotec.pl'
#     'test8.test.evotec.pl'
# )

# $Output = Get-WinADObject -Identity $Computers -Verbose #-IncludeAllTypes
# $Output | Format-Table *

$Computers = Get-WinADComputers
$Computers.Count
$Computers | Format-Table