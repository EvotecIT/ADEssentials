function Test-WinADSchemaAttribute {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Name,
        [string] $Server
    )

    try {
        $RootDSE = Get-ADRootDSE -Server $Server -ErrorAction Stop
        $Attribute = Get-ADObject -LDAPFilter "(&(objectClass=attributeSchema)(lDAPDisplayName=$Name))" -SearchBase $RootDSE.SchemaNamingContext -Server $Server -ErrorAction Stop
        $null -ne $Attribute
    } catch {
        Write-Verbose -Message "Test-WinADSchemaAttribute - Failed to query schema attribute '$Name' using server '$Server'. Error: $($_.Exception.Message)"
        $false
    }
}
