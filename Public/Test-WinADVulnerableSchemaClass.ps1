function Test-WinADVulnerableSchemaClass {
    <#
    .SYNOPSIS
    Checks for CVE-2021-34470 and returns and object with output

    .DESCRIPTION
    Checks for CVE-2021-34470 and returns and object with output

    .EXAMPLE
    Test-WinADVulnerableSchemaClass

    .NOTES
    Based on https://microsoft.github.io/CSS-Exchange/Security/Test-CVE-2021-34470/
    To repair either upgrade Microsoft Exchange Schema or run the fix from URL above
    #>
    [cmdletBinding()]
    param()
    $schemaMaster = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().SchemaRoleOwner
    $schemaDN = ([ADSI]"LDAP://$($schemaMaster)/RootDSE").schemaNamingContext
    $storageGroupSchemaEntryDN = "LDAP://$($schemaMaster)/CN=ms-Exch-Storage-Group,$schemaDN"
    if (-not ([System.DirectoryServices.DirectoryEntry]::Exists($storageGroupSchemaEntryDN))) {
        return [PSCustomObject] @{
            "Vulnerable"         = $false
            "Status"             = "Exchange was not installed in this forest. Therefore, CVE-2021-34470 vulnerability is not present."
            "HasUnexpectedValue" = $false
            'Superior'           = $null
        }
    }

    $storageGroupSchemaEntry = [ADSI]($storageGroupSchemaEntryDN)
    if ($storageGroupSchemaEntry.Properties["possSuperiors"].Count -eq 0) {
        return [PSCustomObject] @{
            "Vulnerable"         = $false
            "Status"             = "CVE-2021-34470 vulnerability is not present."
            "HasUnexpectedValue" = $false
            'Superior'           = $null
        }

    }
    foreach ($val in $storageGroupSchemaEntry.Properties["possSuperiors"]) {
        if ($val -eq "computer") {
            return [PSCustomObject] @{
                "Vulnerable"         = $true
                "Status"             = "CVE-2021-34470 vulnerability is present."
                "HasUnexpectedValue" = $false
                'Superior'           = $null
            }
        } else {
            return [PSCustomObject] @{
                "Vulnerable"         = $true
                "Status"             = "CVE-2021-34470 vulnerability may be present due to an unexpected superior: $val"
                "HasUnexpectedValue" = $true
                "Superior"           = $val
            }
        }
    }
}