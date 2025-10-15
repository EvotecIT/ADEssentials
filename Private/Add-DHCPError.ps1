function Add-DHCPError {
    <#
    .SYNOPSIS
    Internal helper function to log errors and warnings for DHCP operations.

    .DESCRIPTION
    Logs errors and warnings for DHCP operations.

    .PARAMETER Summary
    The DHCP summary object to add errors to. If not provided, attempts to use script scope $DHCPSummary.

    .PARAMETER ServerName
    The name of the DHCP server.
    This parameter is mandatory and should be the fully qualified domain name (FQDN) or IP address of the DHCP server.
    If the server is not reachable, this function will log an error.

    .PARAMETER ScopeId
    The ID of the DHCP scope. This parameter is optional and can be used to specify a particular scope for the error.

    .PARAMETER Component
    The name of the component where the error occurred.

    .PARAMETER Operation
    The name of the operation that was being performed when the error occurred.

    .PARAMETER ErrorMessage
    The error message to log.

    .PARAMETER Severity
    The severity level of the error (e.g., Error, Warning).

    .EXAMPLE
     Add-DHCPError -Summary $DHCPSummary -ServerName 'AD Discovery' -Component 'DHCP Server Discovery' -Operation 'Get-DhcpServerInDC' -ErrorMessage $_.Exception.Message -Severity 'Error'

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Summary,

        [string]$ServerName,
        [string]$ScopeId = $null,
        [string]$Component,
        [string]$Operation,
        [string]$ErrorMessage,
        [string]$Severity = 'Error',
        # Optional richer error metadata (if available)
        [string]$Reason,
        [string]$Category,
        [string]$ErrorId,
        [string]$Target,
        [string]$HResult
    )

    # Use provided Summary object or fall back to script-scope $DHCPSummary
    if (-not $Summary) {
        if (Get-Variable -Name 'DHCPSummary' -Scope Script -ErrorAction SilentlyContinue) {
            $Summary = $Script:DHCPSummary
        } else {
            Write-Warning "Add-DHCPError - No Summary object provided and no script-scope DHCPSummary found"
            return
        }
    }

    $ErrorObject = [PSCustomObject] @{
        Timestamp    = Get-Date
        ServerName   = $ServerName
        ScopeId      = $ScopeId
        Component    = $Component
        Operation    = $Operation
        Severity     = $Severity
        ErrorMessage = $ErrorMessage
        GatheredFrom = $env:COMPUTERNAME
        Reason       = $Reason
        Category     = $Category
        ErrorId      = $ErrorId
        Target       = $Target
        HResult      = $HResult
    }

    if ($Severity -eq 'Warning') {
        $Summary.Warnings.Add($ErrorObject)
        Write-Warning "Get-WinADDHCPSummary - $Component on $ServerName$(if($ScopeId){" (Scope: $ScopeId)"}): $ErrorMessage"
    } else {
        $Summary.Errors.Add($ErrorObject)
        Write-Warning "Get-WinADDHCPSummary - ERROR in $Component on $ServerName$(if($ScopeId){" (Scope: $ScopeId)"}): $ErrorMessage"
    }
}
