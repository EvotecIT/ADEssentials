
$Domain = 'ad.evotec.xyz'
$Computers = Get-ADComputer -Filter "*" -Properties ProtectedFromAccidentalDeletion -Server $Domain
foreach ($Computer in $Computers) {
    if ($Computer.ProtectedFromAccidentalDeletion) {
        Set-ADObject -ProtectedFromAccidentalDeletion $false -Identity $Computer.DistinguishedName -Server $Domain -WhatIf
    }
}