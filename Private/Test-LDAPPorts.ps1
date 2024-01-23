function Test-LDAPPorts {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .PARAMETER ServerName
    Parameter description

    .PARAMETER Port
    Parameter description

    .PARAMETER Credential
    Parameter description

    .PARAMETER Identity
    User to search for using LDAP query by objectGUID, objectSID, SamAccountName, UserPrincipalName, Name or DistinguishedName

    .EXAMPLE
    Test-LDAPPorts -ServerName 'SomeServer' -port 3269 -Credential (Get-Credential)

    .EXAMPLE
    Test-LDAPPorts -ServerName 'SomeServer' -port 3269

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string] $ServerName,
        [int] $Port,
        [pscredential] $Credential,
        [string] $Identity
    )
    if ($ServerName -and $Port -ne 0) {
        Write-Verbose "Test-LDAPPorts - Processing $ServerName / $Port"
        try {
            $LDAP = "LDAP://" + $ServerName + ':' + $Port
            if ($Credential) {
                $Connection = [ADSI]::new($LDAP, $Credential.UserName, $Credential.GetNetworkCredential().Password)
            } else {
                $Connection = [ADSI]($LDAP)
            }
            $Connection.Close()
            $ReturnData = [ordered] @{
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
                Write-Warning "Test-LDAPPorts - Current user ($Env:USERNAME) doesn't seem to have access to to LDAP on port $ServerName`:$Port. Error: $ErrorMessage"
            } else {
                Write-Warning -Message "Test-LDAPPorts - Error: $ErrorMessage"
            }
            $ReturnData = [ordered] @{
                Computer     = $ServerName
                Port         = $Port
                Status       = $false
                ErrorMessage = $ErrorMessage
            }
        }

        if ($Identity) {
            if ($ReturnData.Status -eq $true) {
                try {
                    Write-Verbose "Test-LDAPPorts - Processing $ServerName / $Port / $Identity"
                    $LDAP = "LDAP://" + $ServerName + ':' + $Port
                    if ($Credential) {
                        $Connection = [ADSI]::new($LDAP, $Credential.UserName, $Credential.GetNetworkCredential().Password)
                    } else {
                        $Connection = [ADSI]($LDAP)
                    }

                    $Searcher = [System.DirectoryServices.DirectorySearcher]$Connection
                    $Searcher.Filter = "(|(DistinguishedName=$Identity)(Name=$Identity)(SamAccountName=$Identity)(UserPrincipalName=$Identity)(objectGUID=$Identity)(objectSid=$Identity))"
                    $SearchResult = $Searcher.FindOne()
                    $SearchResult

                    if ($SearchResult) {
                        $UserFound = $true
                    } else {
                        $UserFound = $false
                    }

                    $ReturnData['Identity'] = $Identity
                    $ReturnData['IdentityStatus'] = $UserFound
                    $ReturnData['IdentityData'] = $SearchResult
                    $ReturnData['IdentityErrorMessage'] = ""

                    $Connection.Close()
                } catch {
                    $ErrorMessage = $($_.Exception.Message) -replace [System.Environment]::NewLine
                    if ($_.Exception.ToString() -match "The server is not operational") {
                        Write-Warning "Test-LDAPPorts - Can't open $ServerName`:$Port. Error: $ErrorMessage"
                    } elseif ($_.Exception.ToString() -match "The user name or password is incorrect") {
                        Write-Warning "Test-LDAPPorts - Current user ($Env:USERNAME) doesn't seem to have access to to LDAP on port $ServerName`:$Port. Error: $ErrorMessage"
                    } else {
                        Write-Warning -Message "Test-LDAPPorts - Error: $ErrorMessage"
                    }
                    $ReturnData['Identity'] = $Identity
                    $ReturnData['IdentityStatus'] = $false
                    $ReturnData['IdentityData'] = $null
                    $ReturnData['IdentityErrorMessage'] = $ErrorMessage
                }
            } else {
                $ReturnData['Identity'] = $Identity
                $ReturnData['IdentityStatus'] = $false
                $ReturnData['IdentityData'] = $null
                $ReturnData['IdentityErrorMessage'] = $ReturnData.ErrorMessage
            }
        }
        [PSCustomObject] $ReturnData
    }
}