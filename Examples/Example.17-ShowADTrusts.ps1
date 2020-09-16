Import-Module .\ADEssentials.psd1 -Force

Show-WinADTrust -Online -FilePath $PSScriptRoot\Reports\Trusts.html -Verbose

$Trusts.AdditionalInformation | Format-Table
$Trusts.AdditionalInformation.msDSTrustForestTrustInfo | Format-Table
$Trusts.AdditionalInformation.SuffixesInclude | Format-Table
$Trusts.AdditionalInformation.SuffixesExclude | Format-Table
$Trusts.AdditionalInformation.TrustObject | Format-Table
$Trusts.AdditionalInformation.GroupExists | Format-Table

Show-WinADTrust -Online -FilePath $PSScriptRoot\Reports\Trusts.html