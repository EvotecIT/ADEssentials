function Set-ADACLOwner {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [string] $ADObject,
        [Parameter(Mandatory)][string] $Principal
    )
    Begin {
        if ($Principal -is [string]) {
            if ($Principal -like '*/*') {
                $SplittedName = $Principal -split '/'
                [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($SplittedName[0], $SplittedName[1])
            } else {
                [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
            }
        } else {
            # Not yet ready
            return
        }
    }
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
                Write-Warning "Set-ADACLOwner - Object not recognized. Skipping..."
                continue
            }
            $DNConverted = (ConvertFrom-DistinguishedName -DistinguishedName $DistinguishedName -ToDC) -replace '=' -replace ','
            if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                Write-Verbose "Set-ADACLOwner - Enabling PSDrives for $DistinguishedName to $DNConverted"
                New-ADForestDrives -ForestName $ForestName # -ObjectDN $DistinguishedName
                if (-not (Get-PSDrive -Name $DNConverted -ErrorAction SilentlyContinue)) {
                    Write-Warning "Set-ADACLOwner - Drive $DNConverted not mapped. Terminating..."
                    return
                }
            }
            $PathACL = "$DNConverted`:\$($DistinguishedName)"
            $ACLs = Get-Acl -Path $PathACL -ErrorAction Stop
            $CurrentOwner = $ACLs.Owner
            #if ($PSCmdlet.ShouldProcess($ACLs.Path, "Changing owner from $($CurrentOwner) to $Identity for $($ACLs.Path)")) {
            Write-Verbose "Set-ADACLOwner - Changing owner from $($CurrentOwner) to $Identity for $($ACLs.Path)"
            try {
                $ACLs.SetOwner($Identity)
            } catch {
                Write-Warning "Set-ADACLOwner - Unable to change owner from $($CurrentOwner) to $Identity for $($ACLs.Path): $($_.Exception.Message)"
                break
            }
            try {
                Set-Acl -Path $PathACL -AclObject $ACLs -ErrorAction Stop
            } catch {
                Write-Warning "Set-ADACLOwner - Unable to change owner from $($CurrentOwner) to $Identity for $($ACLs.Path): $($_.Exception.Message)"
            }
            # }
        }
    }
    End {

    }
}