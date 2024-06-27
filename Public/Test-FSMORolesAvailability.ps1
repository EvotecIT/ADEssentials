function Test-FSMORolesAvailability {
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