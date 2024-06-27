Import-Module .\ADEssentials.psd1 -Force

$Groups = 'Group1', 'EVOTECPL\Domain Admins'
$Inputs = foreach ($Group in $Groups) {
    $GroupOutput = Get-WinADGroupMember -Identity $Group -Verbose -AddSelf -All
    $GroupOutput
}

Show-WinADGroupMember -Identity $Inputs -Online -Verbose