function Get-ADACLOwner {
    [cmdletBinding()]
    param(
        [Array] $ADObject
    )
    Begin { }
    Process {
        foreach ($Object in $ADObject) {
            if ($Object -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -or $Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
                [string] $DistinguishedName = $Object.DistinguishedName
                [string] $CanonicalName = $Object.CanonicalName
                [string] $ObjectClass = $Object.ObjectClass
            } elseif ($Object -is [string]) {
                [string] $DistinguishedName = $Object
                [string] $CanonicalName = ''
                [string] $ObjectClass = ''
            } else {
                Write-Warning "Get-ADACLOwner - Object not recognized. Skipping..."
                continue
            }
            $DNConverted = (ConvertFrom-DistinguishedName -DistinguishedName $DistinguishedName -ToDC) -replace '=' -replace ','
            if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                Write-Verbose "Get-ADACLOwner - Enabling PSDrives for $DistinguishedName to $DNConverted"
                New-ADForestDrives -ForestName $ForestName # -ObjectDN $DistinguishedName
                if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                    Write-Warning "Set-ADACLOwner - Drive $DNConverted not mapped. Terminating..."
                    return
                }
            }
            $PathACL = "$DNConverted`:\$($DistinguishedName)"
            $ACLs = Get-Acl -Path $PathACL -ErrorAction Stop
            [PSCustomObject] @{
                DistinguishedName = $DistinguishedName
                Owner             = $ACLs.Owner
                ACLs              = $ACLs
            }

        }
    }
    End { }
}