function Test-LDAPPorts {
    [CmdletBinding()]
    param(
        [string] $ServerName,
        [int] $Port
    )

    $Output = @{
        Status  = $false
        Comment = $null
    }
    if ($ServerName -and $Port -ne 0) {
        try {
            $LDAP = "LDAP://" + $ServerName + ':' + $Port
            # $LDAP = $LDAPPrep + ":389"
            $Connection = [ADSI]($LDAP)
            $Connection.Close()
            $Output['Status'] = $true
        } catch {
            if ($_.Exception.ToString() -match "The server is not operational") {
                #Write-Warning "Can't open $ServerName`:$Port."
                $Output['Comment'] = "Can't open $ServerName`:$Port."
            } elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
                #Write-Warning "Current user ($Env:USERNAME) doesn't seem to have access to to LDAP on port $Server`:$Port"
                $Output['Comment'] = "Current user ($Env:USERNAME) doesn't seem to have access to to LDAP on port $Server`:$Port"
            } else {
                # Write-Warning -Message $_
            }
        }
    }
    $Output
}