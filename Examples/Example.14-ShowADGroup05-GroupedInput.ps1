Import-Module .\ADEssentials.psd1 -Force

$Groups = 'Group1', 'Domain Admins'
$GroupMemberInput = [ordered]@{}
foreach ($Group in $Groups) {
    $GroupOutput = Get-WinADGroupMember -Identity $Group -Verbose -AddSelf -All
    $GroupMemberInput[$Group] = $GroupOutput
}

Show-WinADGroupMember -Identity $GroupMemberInput -Online