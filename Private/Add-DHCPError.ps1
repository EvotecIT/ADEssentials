function Add-DHCPError {
    <#
    .SYNOPSIS
    Internal helper function to log errors and warnings for DHCP operations.

    .DESCRIPTION
    Logs errors and warnings for DHCP operations.

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
     Add-DHCPError -ServerName 'AD Discovery' -Component 'DHCP Server Discovery' -Operation 'Get-DhcpServerInDC' -ErrorMessage $_.Exception.Message -Severity 'Error'

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [string]$ServerName,
        [string]$ScopeId = $null,
        [string]$Component,
        [string]$Operation,
        [string]$ErrorMessage,
        [string]$Severity = 'Error'
    )

    $ErrorObject = [PSCustomObject] @{
        Timestamp    = Get-Date
        ServerName   = $ServerName
        ScopeId      = $ScopeId
        Component    = $Component
        Operation    = $Operation
        Severity     = $Severity
        ErrorMessage = $ErrorMessage
        GatheredFrom = $env:COMPUTERNAME
    }

    if ($Severity -eq 'Warning') {
        $DHCPSummary.Warnings.Add($ErrorObject)
        Write-Warning "Get-WinADDHCPSummary - $Component on $ServerName$(if($ScopeId){" (Scope: $ScopeId)"}): $ErrorMessage"
    } else {
        $DHCPSummary.Errors.Add($ErrorObject)
        Write-Warning "Get-WinADDHCPSummary - ERROR in $Component on $ServerName$(if($ScopeId){" (Scope: $ScopeId)"}): $ErrorMessage"
    }
}