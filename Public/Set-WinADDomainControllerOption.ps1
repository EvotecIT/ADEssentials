function Set-WinADDomainControllerOption {
    <#
    .SYNOPSIS
    Command to set the options of a domain controller

    .DESCRIPTION
    Command to set the options of a domain controller that uses the repadmin command

    Available options:
    - DISABLE_OUTBOUND_REPL: Disables outbound replication.
    - DISABLE_INBOUND_REPL: Disables inbound replication.
    - DISABLE_NTDSCONN_XLATE: Disables the translation of NTDSConnection objects.
    - DISABLE_SPN_REGISTRATION: Disables Service Principal Name (SPN) registration.
    - IS_GC: Sets or unsets the Global Catalog (GC) for the domain controller.

    .PARAMETER DomainController
    The domain controller to set the options on

    .PARAMETER Option
    Choose one or more options from the list of available options to enable or disable

    Options:
    - DISABLE_OUTBOUND_REPL: Disables outbound replication.
    - DISABLE_INBOUND_REPL: Disables inbound replication.
    - DISABLE_NTDSCONN_XLATE: Disables the translation of NTDSConnection objects.
    - DISABLE_SPN_REGISTRATION: Disables Service Principal Name (SPN) registration.
    - IS_GC: Sets or unsets the Global Catalog (GC) for the domain controller.

    .PARAMETER Action
    Choose to enable or disable the option(s)

    .EXAMPLE
    Set-WinADDomainControllerOption -DomainController 'ADRODC' -Option 'IS_GC' -Action Enable

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][string]$DomainController,
        [ValidateSet(
            "DISABLE_OUTBOUND_REPL", "DISABLE_INBOUND_REPL",
            "DISABLE_NTDSCONN_XLATE", "DISABLE_SPN_REGISTRATION",
            "IS_GC"
        )]
        [parameter(Mandatory)][string[]]$Option,
        [parameter(Mandatory)][ValidateSet("Enable", "Disable")][string]$Action
    )

    # Validate Domain Controller input
    if (-not $DomainController) {
        Write-Host "Domain Controller is required."
        return
    }

    # Determine the action to be taken
    $actionFlag = switch ($Action) {
        "Enable" { "+" }
        "Disable" { "-" }
    }

    foreach ($O in $Option) {
        # Construct the repadmin command
        # Execute the repadmin command
        try {
            $NewOptions = $null
            $CurrentOptions = $null
            Write-Verbose -Message "Set-WinADDomainControllerOption - Executing repadmin /options $DomainController $actionFlag$O"
            $Output = & repadmin /options $DomainController $actionFlag$O
            if ($Output) {
                foreach ($O in $Output) {
                    if ($O.StartsWith("Current DSA Options:")) {
                        $Options = $O.Split(":")[1].Trim().Split(",")
                        $CurrentOptions = foreach ($O in $Options) {
                            $Value = $O.Trim()
                            if ($Value) {
                                $Value
                            }
                        }
                    } elseif ($O.StartsWith("New DSA Options:")) {
                        $Options = $O.Split(":")[1].Trim().Split(",")
                        $NewOptions = foreach ($O in $Options) {
                            $Value = $O.Trim()
                            if ($Value) {
                                $Value
                            }
                        }
                    }
                }
                If ($CurrentOptions) {
                    $Status = $true
                } else {
                    $Status = $false
                }
                if ($CurrentOptions -eq $NewOptions) {
                    $ActionStatus = $false
                } else {
                    $ActionStatus = $true
                }
                [PSCustomObject] @{
                    DomainController = $DomainController
                    Status           = $Status
                    Action           = $Action
                    ActionStatus     = $ActionStatus
                    ActionStatusText = if ($ActionStatus) { "Changed" } else { "No changes" }
                    CurrentOptions   = $CurrentOptions -split " "
                    NewOptions       = $NewOptions -split " "
                    Output           = $Output
                }
            }
        } catch {
            Write-Warning -Message "Set-WinADDomainControllerOption - Failed to execute repadmin /options $DomainController $actionFlag$O. Exception: $($_.Exception.Message)"
        }
    }
}