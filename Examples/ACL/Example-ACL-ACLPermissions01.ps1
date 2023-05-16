Import-Module .\ADEssentials.psd1 -Force

# Saves all permissions directly into XLSX file
# It saves each domain to separate file (if there are multiple domains)
Get-WinADACLForest -Verbose -OutputFile "$PSSCriptRoot\PermissionsOutputPerSheet.xlsx"