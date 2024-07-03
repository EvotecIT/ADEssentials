function Test-FSMORolesAvailability {
    <#
    .SYNOPSIS
    Tests the availability of FSMO roles across domain controllers in a specified domain.

    .DESCRIPTION
    This cmdlet tests the availability of Flexible Single Master Operations (FSMO) roles across domain controllers in a specified domain. It returns a custom object with details about the role, the hostname of the domain controller, and the status of the connection to the domain controller.

    .PARAMETER Domain
    The name of the domain to test FSMO roles for. If not specified, the current user's DNS domain is used.

    .EXAMPLE
    Test-FSMORolesAvailability

    .EXAMPLE
    Test-FSMORolesAvailability -Domain "example.com"

    .NOTES
    This cmdlet is useful for monitoring the availability of FSMO roles across domain controllers in a domain.
    #>
    [cmdletBinding()]
    param(
        [string] $Domain = $Env:USERDNSDOMAIN
    )
    $DC = Get-ADDomainController -Server $Domain -Filter "*"
    $Output = foreach ($S in $DC) {
        if ($S.OperationMasterRoles.Count -gt 0) {
            $Status = Test-Connection -ComputerName $S.HostName -Count 2 -Quiet
        } else {
            $Status = $null
        }
        foreach ($_ in $S.OperationMasterRoles) {
            [PSCustomObject] @{
                Role     = $_
                HostName = $S.HostName
                Status   = $Status
            }
        }
    }
    $Output
}