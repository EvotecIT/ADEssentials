function Test-LDAPPorts {
    [CmdletBinding()]
    param(
        [string] $ServerName,
        [int] $Port
    )
    if ($ServerName -and $Port -ne 0) {
        Write-Verbose "Test-LDAPPorts - Processing $ServerName / $Port"
        try {
            $LDAP = "LDAP://" + $ServerName + ':' + $Port
            $Connection = [ADSI]($LDAP)
            $Connection.Close()
            [PSCustomObject] @{
                Computer     = $ServerName
                Port         = $Port
                Status       = $true
                ErrorMessage = ''
            }
        } catch {
            $ErrorMessage = $($_.Exception.Message) -replace [System.Environment]::NewLine
            if ($_.Exception.ToString() -match "The server is not operational") {
                Write-Warning "Test-LDAPPorts - Can't open $ServerName`:$Port. Error: $ErrorMessage"
            } elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
                Write-Warning "Test-LDAPPorts - Current user ($Env:USERNAME) doesn't seem to have access to to LDAP on port $Server`:$Port. Error: $ErrorMessage"
            } else {
                Write-Warning -Message "Test-LDAPPorts - Error: $ErrorMessage"
            }
            [PSCustomObject] @{
                Computer     = $ServerName
                Port         = $Port
                Status       = $false
                ErrorMessage = $ErrorMessage
            }
        }
    }
}