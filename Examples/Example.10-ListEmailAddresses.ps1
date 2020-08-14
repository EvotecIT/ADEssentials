Import-Module .\ADEssentials.psd1 -Force

$ADUsers = Get-ADUser -Filter * -Properties ProxyAddresses
$Output = foreach ($User in $ADUsers) {
    Get-WinADProxyAddresses -ADUser $User -RemovePrefix
}
$Output | Format-Table