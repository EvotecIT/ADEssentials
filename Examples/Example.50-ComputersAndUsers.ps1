Import-Module ADEssentials -Force
Import-Module PSWriteOffice -Force

$Computers = Get-WinADComputers
$Users = Get-WinADUsers
$Computers | Export-OfficeExcel -FilePath $PSScriptRoot\ADReport.xlsx -WorksheetName "Computers" -ShowRowStripes
$Users | Export-OfficeExcel -FilePath $PSScriptRoot\ADReport.xlsx -WorksheetName "Users" -ShowRowStripes -Show