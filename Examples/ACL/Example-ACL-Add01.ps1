Clear-Host
Import-Module .\ADEssentials.psd1 -Force

$FindOU = 'OU=Users,OU=Accounts,OU=Production,DC=ad,DC=evotec,DC=xyz'

Add-ADACL -Verbose -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -AccessRule GenericAll -AccessControlType Allow
Add-ADACL -Verbose -ADObject $FindOU -Principal 'przemyslaw.klys' -AccessRule GenericAll -AccessControlType Allow

Remove-ADACL -Verbose -ADObject $FindOU -Principal 'mmmm@ad.evotec.pl' -AccessRule GenericAll -AccessControlType Allow