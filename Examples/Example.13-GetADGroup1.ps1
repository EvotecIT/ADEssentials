﻿Import-Module .\ADEssentials.psd1 -Force

# Lets check only two groups
#Get-WinADGroupMember -Group 'GDS-TestGroup9' | Format-Table *
#Get-WinADGroupMember -Group 'GDS-TestGroup9' -All -AddSelf | Format-Table *
Get-WinADGroupMember -Group 'GDS-TestGroup9' -All -SelfOnly | Format-List *

<#
# Another groups
Get-WinADGroupMember -Group 'Test Local Group' | Format-Table *
Get-WinADGroupMember -Group 'Test Local Group' -All | Format-Table *

# Another One
Get-WinADGroupMember -Group 'GDS-TestGroup3' | Format-Table *
Get-WinADGroupMember -Group 'GDS-TestGroup3' -All | Format-Table *

# Another one
Get-WinADGroupMember -Group 'Domain Admins' | Format-Table
Get-WinADGroupMember -Group 'Domain Admins' -All -AddSelf | Format-Table *

#>