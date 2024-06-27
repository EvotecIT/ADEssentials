Import-Module .\ADEssentials.psd1 -Force

$Find = Compare-WinADGlobalCatalogObjects -Verbose -IncludeDomains 'ad.evotec.pl' -Advanced
$Find

Invoke-ADEssentials -Type GlobalCatalogComparison -Verbose -IncludeDomains 'ad.evotec.xyz'