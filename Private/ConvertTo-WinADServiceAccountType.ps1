function ConvertTo-WinADServiceAccountType {
    [cmdletBinding()]
    param(
        [AllowNull()][string] $ObjectClass
    )

    switch ($ObjectClass) {
        'msDS-ManagedServiceAccount' {
            'Standalone Managed Service Account (sMSA/MSA)'
        }
        'msDS-GroupManagedServiceAccount' {
            'Group Managed Service Account (gMSA)'
        }
        'msDS-DelegatedManagedServiceAccount' {
            'Delegated Managed Service Account (dMSA)'
        }
        default {
            if ($ObjectClass) {
                $ObjectClass
            } else {
                'Unknown'
            }
        }
    }
}
