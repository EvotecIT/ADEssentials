function Update-LastLogonTimestamp {
    <#
    .SYNOPSIS
    Uses Kerberos to impersonate a user and update the LastLogonTimestamp attribute

    .DESCRIPTION
    Uses Kerberos to impersonate a user and update the LastLogonTimestamp attribute
    It's a trick to last logon time updated without actually logging in

    .PARAMETER Identity
    The identity of the user to impersonate

    .EXAMPLE
    Update-LastLogonTimestamp -UserName 'PUID'

    .EXAMPLE
    Update-LastLogonTimestamp -UserName 'PUID@ad.evotec.xyz'

    .NOTES
    The lastLogontimeStamp attribute is not updated every time a user or computer logs on to the domain.
    The decision to update the value is based on the current date minus the value of the ( ms-DS-Logon-Time-Sync-Interval attribute minus a random percentage of 5).
    If the result is equal to or greater than lastLogontimeStamp the attribute is updated.

    If your Domain Admin is in Protected Users you may need to remove it from there to make it work
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Position = 0, Mandatory)][alias('UserName')][string]$Identity
    )

    begin {
        $impersonatedContext = $null
        $impersonationSuccessful = $false
        $ErrorMessage = $null
    }
    process {
        try {
            $windowsIdentity = [System.Security.Principal.WindowsIdentity]::new($Identity)
        } catch {
            Write-Warning "Update-LastLogonTimestamp - Failed to create WindowsIdentity for $Identity - $($_.Exception.Message)"
            $windowsIdentity = $null
            $ErrorMessage = $_.Exception.Message
        }
        if ($windowsIdentity) {
            try {
                if ($PSCmdlet.ShouldProcess("Impersonating user - $Identity")) {
                    Write-Verbose "Update-LastLogonTimestamp - Impersonating user - $Identity"
                    $impersonatedContext = $windowsIdentity.Impersonate()
                    $impersonationSuccessful = $true
                }
            } catch {
                Write-Warning "Update-LastLogonTimestamp - Failed to impersonate user $Identity - $($_.Exception.Message)"
                $impersonationSuccessful = $false
                $ErrorMessage = $_.Exception.Message
            } finally {
                if ($impersonatedContext) {
                    $impersonatedContext.Undo()
                }
            }
        }
    }
    end {
        [PSCustomObject] @{
            Identity                = $Identity
            WhatIf                  = $WhatIfPreference.ispresent
            UserName                = $windowsIdentity.Name
            ImpersonationSuccessful = $impersonationSuccessful
            ErrorMessage            = $ErrorMessage
            WindowsIdentity         = $windowsIdentity
        }
    }
}