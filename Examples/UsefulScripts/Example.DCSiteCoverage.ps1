
# https://www.windows-security.org/84d22a57dce965145438b717db2daaf5/specify-sites-covered-by-the-dc-locator-dns-srv-records

$DCs = Get-ADDomainController -Filter "*" -Server ad.evotec.xyz
$RegistryOutput = Get-PSRegistry -RegistryPath 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' -ComputerName $DCs.HostName
#$RegistryOutput | Out-HtmlView -AllProperties -Filtering -DataStore JavaScript -FilePath "$PSScriptRoot\NetlogonRegistry.html"
$RegistryOutput | Format-Table PSComputerName, PSError, SiteCoverage, GCSiteCoverage, *