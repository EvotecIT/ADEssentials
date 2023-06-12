Import-Module .\ADEssentials.psd1 -Force

Get-WinADPasswordPolicy | Format-Table

Get-WinADPasswordPolicy | Out-HtmlView -Filtering -DataStore JavaScript -Title 'Password Policies' -ScrollX

Invoke-ADEssentials -Type Users,PasswordPolicies -Verbose -FilePath $PSScriptRoot\Reports\UsersAndPasswordPolicies.html -Online