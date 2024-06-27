function Get-WinADDomainControllerOption {
    <#
    .SYNOPSIS
    Command to get the options of a domain controller

    .DESCRIPTION
    Command to get the options of a domain controller that uses the repadmin command

    Provides information about:
    - DISABLE_OUTBOUND_REPL: Disables outbound replication.
    - DISABLE_INBOUND_REPL: Disables inbound replication.
    - DISABLE_NTDSCONN_XLATE: Disables the translation of NTDSConnection objects.
    - DISABLE_SPN_REGISTRATION: Disables Service Principal Name (SPN) registration.
    - IS_GC: Sets or unsets the Global Catalog (GC) for the domain controller.

    .PARAMETER DomainController
    The domain controller to get the options from

    .EXAMPLE
    Get-WinADDomainControllerOption -DomainController 'AD1', 'AD2','AD3' | Format-Table *

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][string[]] $DomainController
    )
    foreach ($DC in $DomainController) {
        # Execute the repadmin command and capture the output
        Write-Verbose -Message "Get-WinADDomainControllerOption - Executing repadmin /options $DC"
        $AvailableOptions = $null
        $repadminOutput = & repadmin /options $DC
        if ($repadminOutput[0].StartsWith("Repadmin can't connect to a", $true, [System.Globalization.CultureInfo]::InvariantCulture)) {
            Write-Warning -Message "Get-WinADDomainControllerOption - Unable to connect to [$DC]. Error: $($_.Exception.Message)"
        } else {
            $AvailableOptions = $repadminOutput[0].Replace("Current DSA Options: ", "")
        }
        if ($AvailableOptions) {
            $Options = $AvailableOptions -split " "
        } else {
            $Options = @()
        }
        $Output = [ordered] @{
            Name    = $DC
            Status  = if ($AvailableOptions) { $true } else { $false }
            Options = foreach ($O in $Options) {
                $Value = $O.Trim()
                if ($Value) {
                    $Value
                }
            }
        }
        if ($Output.Options -contains 'IS_GC') {
            $Output['IsGlobalCatalog'] = $true
        } else {
            $Output['IsGlobalCatalog'] = $false
        }
        if ($Output.Options -contains 'IS_RODC') {
            $Output['IsReadOnlyDomainController'] = $true
        } else {
            $Output['IsReadOnlyDomainController'] = $false
        }
        if ($Output.Options -contains 'DISABLE_OUTBOUND_REPL') {
            $Output['DisabledOutboundReplication'] = $true
        } else {
            $Output['DisabledOutboundReplication'] = $false
        }
        if ($Output.Options -contains 'DISABLE_INBOUND_REPL') {
            $Output['DisabledInboundReplication'] = $true
        } else {
            $Output['DisabledInboundReplication'] = $false
        }
        if ($Output.Options -contains 'DISABLE_NTDSCONN_XLATE') {
            $Output['DisabledNTDSConnectionTranslation'] = $true
        } else {
            $Output['DisabledNTDSConnectionTranslation'] = $false
        }
        if ($Output.Options -contains 'DISABLE_SPN_REGISTRATION') {
            $Output['DisabledSPNRegistration'] = $true
        } else {
            $Output['DisabledSPNRegistration'] = $false
        }
        [PSCustomObject] $Output
    }
}