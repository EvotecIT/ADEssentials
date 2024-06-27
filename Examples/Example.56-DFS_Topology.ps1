Import-Module .\ADEssentials.psd1 -Force

Get-WinADDFSTopology -Type All | Format-Table

Remove-WinADDFSTopology -Type MissingAll -Verbose -WhatIf