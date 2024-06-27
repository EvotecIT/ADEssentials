Clear-Host
Import-Module .\ADEssentials.psd1 -Force

#Get-WinADForestControllerInformation | Out-HtmlView -ScrollX -Filtering -DataStore JavaScript

#Get-WinADDomainControllerOption -DomainController 'AD1', 'AD2','AD3' -Verbose | Format-Table *
#Get-WinADDomainControllerOption -DomainController 'ADRODC' -Verbose | Format-List *
#Set-WinADDomainControllerOption -DomainController 'ADRODC' -Option 'IS_GC' -Action Disable
#Set-WinADDomainControllerOption -DomainController 'ADRODC' -Option 'IS_GC' -Action Enable
Get-WinADDomainControllerOption -DomainController 'ADRODC' -Verbose | Format-List *