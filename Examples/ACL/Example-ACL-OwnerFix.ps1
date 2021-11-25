Import-Module .\ADEssentials.psd1 -Force

Set-WinADForestACLOwner -WhatIf -Verbose -LimitProcessing 2 -IncludeOwnerType 'NotAdministrative', 'Unknown'