Import-Module .\ADEssentials.psd1 -Force

$Users = Get-ADUser -Filter * | Select-Object -First 10
Show-WinADObjectDifference -Identity $Users.DistinguishedName -Verbose