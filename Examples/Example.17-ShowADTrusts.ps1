Import-Module .\ADEssentials.psd1 -Force

$Trusts = Show-WinADTrust -Online -FilePath $PSScriptRoot\Reports\Trusts.html -Verbose -PassThru

$Trusts.AdditionalInformation | Format-Table
$Trusts.AdditionalInformation.msDSTrustForestTrustInfo | Format-Table
$Trusts.AdditionalInformation.SuffixesInclude | Format-Table
$Trusts.AdditionalInformation.SuffixesExclude | Format-Table
$Trusts.AdditionalInformation.TrustObject | Format-Table
$Trusts.AdditionalInformation.GroupExists | Format-Table