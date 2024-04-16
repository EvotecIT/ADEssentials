

$NTDS = Get-PSRegistry -RegistryPath "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NTDS\Parameters" -ComputerName AD3
[bool] $NTDS.'Strict Replication Consistency'