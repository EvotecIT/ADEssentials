function Add-ADACL {
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ADObject')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ADObject')][alias('Identity')][Array] $ADObject,
        [Parameter(Mandatory, ParameterSetName = 'ACL')][Array] $ACL,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [string] $Principal,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [System.DirectoryServices.ActiveDirectoryRights] $AccessRule,

        [Parameter(Mandatory, ParameterSetName = 'ACL')]
        [Parameter(Mandatory, ParameterSetName = 'ADObject')]
        [System.Security.AccessControl.AccessControlType] $AccessControlType
    )
    if (-not $Script:ForestDetails) {
        Write-Verbose "Add-ADACL - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }
    if ($PSBoundParameters.ContainsKey('ADObject')) {
        foreach ($Object in $ADObject) {
            $MYACL = Get-ADACL -ADObject $Object -Verbose -NotInherited -Bundle
            foreach ($SubACL in $MYACL) {
                Add-PrivateACL -ACL $SubACL -Principal $Principal -WhatIf:$WhatIfPreference -AccessRule $AccessRule -AccessControlType $AccessControlType
            }
        }
    } elseif ($PSBoundParameters.ContainsKey('ACL')) {
        foreach ($SubACL in $ACL) {
            Add-PrivateACL -ACL $SubACL -Principal $Principal -WhatIf:$WhatIfPreference -AccessRule $AccessRule -AccessControlType $AccessControlType
        }
    }
}