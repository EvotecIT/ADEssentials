


#Set-FileOwner -Path '\\ad1\c$\Windows\SYSVOL\sysvol\ad.evotec.xyz\scripts\' -Recursive -Owner 'BUILTIN\Administrators' #-WhatIf  #-Exlude 'BUILTIN\Administrators'
#Get-FileOwner -Path '\\ad1\c$\Windows\SYSVOL\sysvol\ad.evotec.xyz\scripts\' -Recursive | Format-Table

Get-ChildItem -Path '\\ad1\c$\Windows\SYSVOL\sysvol\ad.evotec.xyz\scripts\' -Recurs | ForEach-Object {

    Get-FilePermissions -Path $_.FullName
} | Format-Table

return
$T = Set-FileOwner -Path '\\ad1\c$\Windows\SYSVOL\sysvol\ad.evotec.xyz\scripts\'
$T | Format-List
$T.DiscretionaryAcl