# Install module should be only done once, unless you want to update to newest version
Install-Module PSWriteHTML -Force -Verbose -Scope CurrentUser
# import module should be done every time you want to use it, although PowerShell autoloads most PowerShell modules
Import-Module PSWriteHTML -Force

# Gather data
$DNSByName = Get-WinDNSRecords -Prettify -IncludeDetails
$DNSByIP = Get-WinDNSIPAddresses -Prettify -IncludeDetails

# Create HTML :-)
New-HTML {
    New-HTMLTab -Name "DNS by Name" {
        New-HTMLTable -DataTable $DNSByName -Filtering {
            New-HTMLTableCondition -Name 'Count' -ComparisonType number -Value 1 -BackgroundColor LightGreen
            New-HTMLTableCondition -Name 'Count' -ComparisonType number -Value 1 -Operator gt -BackgroundColor Orange
            New-HTMLTableConditionGroup -Logic AND {
                New-HTMLTableCondition -Name 'Count' -ComparisonType number -Value 1 -Operator gt
                New-HTMLTableCondition -Name 'Types' -Operator like -ComparisonType string -Value 'static'
                New-HTMLTableCondition -Name 'Types' -Operator like -ComparisonType string -Value 'dynamic'
            } -BackgroundColor Rouge -Row -Color White
        } -DataStore JavaScript
    }
    New-HTMLTab -Name 'DNS by IP' {
        New-HTMLTable -DataTable $DNSByIP -Filtering {
            New-HTMLTableCondition -Name 'Count' -ComparisonType number -Value 1 -BackgroundColor LightGreen
            New-HTMLTableCondition -Name 'Count' -ComparisonType number -Value 1 -Operator gt -BackgroundColor Orange
            New-HTMLTableConditionGroup -Logic AND {
                New-HTMLTableCondition -Name 'Count' -ComparisonType number -Value 1 -Operator gt
                New-HTMLTableCondition -Name 'Types' -Operator like -ComparisonType string -Value 'static'
                New-HTMLTableCondition -Name 'Types' -Operator like -ComparisonType string -Value 'dynamic'
            } -BackgroundColor Rouge -Row -Color White
        } -DataStore JavaScript
    }
} -ShowHTML -Online -TitleText "DNS Records" -FilePath $PSScriptRoot\DNSRecords.html