Import-Module .\ADEssentials.psd1 -Force
Import-Module "C:\Support\GitHub\PSSharedGoods\PSSharedGoods.psd1" -Force


#Get-WinADProtocol -ComputerName 'AD1' -Verbose
Get-WinADProtocol -Verbose | Format-Table *
#Get-WinADProtocol -ComputerName 'EVOWIN', 'EVOPOWER', 'AD1' -Verbose | Format-Table *

return
Get-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"
Get-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
Get-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client"
Set-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client" -Type REG_DWORD -Key 'DisabledByDefault' -Value 0