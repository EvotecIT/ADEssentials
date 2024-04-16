function Sync-WinADObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string[]]$SourceDC,
        [Parameter(Mandatory = $true)][string] $TargetDC,
        [System.Management.Automation.PSCredential] $Credential,
        [string] $Identity = 'krbtgt',
        [ValidateSet('LDAP', 'WinRM')][string] $ReplicationMode = 'LDAP',
        [switch] $EnableException
    )

    begin {
        $credParam = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
        try {
            $krbtgtDN = (Get-ADUser @credParam -Identity $Identity -Server $TargetDC -ErrorAction Stop).DistinguishedName
        } catch {
            # Stop-PSFFunction -String 'Sync-KrbAccount.UserNotFound' -StringValues $Identity, $TargetDC -ErrorRecord $_
            return
        }
    }
    process {
        $errorVar = @()
        $pwdLastSet = [System.DateTime]::FromFileTimeUtc((Get-ADObject @credParam -Identity $krbtgtDN -Server $TargetDC -Properties PwdLastSet).PwdLastSet)
        switch ($ReplicationMode) {
            #region LDAP Based
            'LDAP' {
                Sync-LdapObjectParallel @credParam -Object $krbtgtDN -Server $SourceDC -Target $TargetDC -Reverse
            }
            #endregion LDAP Based
            #region WinRM Based
            'WinRM' {
                Write-PSFMessage -String 'Sync-KrbAccount.Connecting' -StringValues ($SourceDC -join ', '), $krbtgtDN -Target $SourceDC
                Invoke-PSFCommand @credParam -ComputerName $SourceDC -ScriptBlock {
                    param (
                        $TargetDC,

                        $KrbtgtDN,

                        $PwdLastSet
                    )

                    $message = repadmin.exe /replsingleobj $env:COMPUTERNAME $TargetDC $KrbtgtDN *>&1
                    $result = 0 -eq $LASTEXITCODE

                    # Verify the password change was properly synced
                    $pwdLastSetLocal = [System.DateTime]::FromFileTimeUtc((Get-ADObject -Identity $KrbtgtDN -Server $env:COMPUTERNAME -Properties PwdLastSet).PwdLastSet)
                    if ($pwdLastSetLocal -ne $PwdLastSet) { $result = $false }

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        Success      = $result
                        Message      = ($message | Where-Object { $_ })
                        ExitCode     = $LASTEXITCODE
                        Error        = $null
                    }
                } -ArgumentList $TargetDC, $krbtgtDN, $pwdLastSet -ErrorVariable errorVar -ErrorAction SilentlyContinue | Select-PSFObject -KeepInputObject -TypeName 'Krbtgt.SyncResult'

                foreach ($errorObject in $errorVar) {
                    Write-PSFMessage -Level Warning -String 'Sync-KrbAccount.ConnectError' -StringValues $errorObject.TargetObject -ErrorRecord $errorObject
                    [PSCustomObject]@{
                        PSTypeName   = 'Krbtgt.SyncResult'
                        ComputerName = $errorObject.TargetObject
                        Success      = $false
                        Message      = $errorObject.Exception.Message
                        ExitCode     = 1
                        Error        = $errorObject
                    }
                }
            }
            #endregion WinRM Based
        }
    }
}