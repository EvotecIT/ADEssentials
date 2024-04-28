Import-Module .\ADEssentials.psd1 -Force

$Find = Compare-WinADGlobalCatalogObjects -Verbose
$Find

Invoke-ADEssentials -Type GlobalCatalogComparison -Verbose