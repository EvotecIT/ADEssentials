function Set-ADACLOwner {
    <#
    .SYNOPSIS
    Sets the owner of the ACLs on specified Active Directory objects to a specified principal.

    .DESCRIPTION
    This cmdlet sets the owner of the ACLs on specified Active Directory objects to a specified principal. It supports setting the owner on multiple objects at once and can handle both local and remote operations. It also provides verbose and warning messages to facilitate troubleshooting.

    .PARAMETER ADObject
    Specifies the Active Directory objects on which to set the owner. This can be a list of objects or a list of Distinguished Names of objects.

    .PARAMETER Principal
    Specifies the principal to set as the owner of the ACLs. This can be a string in the format of 'Domain\Username' or 'Username@Domain'.

    .EXAMPLE
    Set-ADACLOwner -ADObject 'OU=Users,DC=example,DC=com', 'CN=Computers,DC=example,DC=com' -Principal 'example\DomainAdmins'

    This example sets the owner of the ACLs on the specified OU and CN to 'example\DomainAdmins'.

    .EXAMPLE
    Set-ADACLOwner -ADObject 'CN=User1,DC=example,DC=com', 'CN=Computer1,DC=example,DC=com' -Principal 'DomainAdmins@example.com'

    This example sets the owner of the ACLs on the specified user and computer to 'DomainAdmins@example.com'.
    #>
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Identity')][Array] $ADObject,
        [Parameter(Mandatory)][string] $Principal
    )
    Begin {
        if ($Principal -is [string]) {
            if ($Principal -like '*/*') {
                $SplittedName = $Principal -split '/'
                [System.Security.Principal.IdentityReference] $PrincipalIdentity = [System.Security.Principal.NTAccount]::new($SplittedName[0], $SplittedName[1])
            } else {
                [System.Security.Principal.IdentityReference] $PrincipalIdentity = [System.Security.Principal.NTAccount]::new($Principal)
            }
        } else {
            # Not yet ready
            return
        }
    }
    Process {
        foreach ($Object in $ADObject) {
            #$ADObjectData = $null
            if ($Object -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit] -or $Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
                # if object already has proper security descriptor we don't need to do additional querying
                #if ($Object.ntSecurityDescriptor) {
                #    $ADObjectData = $Object
                #}
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
                    continue
                }
            }
            $PathACL = "$DNConverted`:\$($DistinguishedName)"
            try {
                $ACLs = Get-Acl -Path $PathACL -ErrorAction Stop
            } catch {
                Write-Warning "Get-ADACL - Path $DistinguishedName / $PathACL - Error: $($_.Exception.Message)"
                continue
            }
            <#
            if (-not $ADObjectData) {
                try {
                    $ADObjectData = Get-ADObject -Identity $DistinguishedName -Properties ntSecurityDescriptor -ErrorAction Stop
                    $ACLs = $ADObjectData.ntSecurityDescriptor
                } catch {
                    Write-Warning "Get-ADACL - Path $DistinguishedName - Error: $($_.Exception.Message)"
                    continue
                }
            }
            #>
            $CurrentOwner = $ACLs.Owner
            Write-Verbose "Set-ADACLOwner - Changing owner from $($CurrentOwner) to $PrincipalIdentity for $($DistinguishedName)"
            try {
                $ACLs.SetOwner($PrincipalIdentity)
            } catch {
                Write-Warning "Set-ADACLOwner - Unable to change owner from $($CurrentOwner) to $PrincipalIdentity for $($DistinguishedName): $($_.Exception.Message)"
                continue
            }
            try {
                #Set-ADObject -Identity $DistinguishedName -Replace @{ ntSecurityDescriptor = $ACLs } -ErrorAction Stop
                Set-Acl -Path $PathACL -AclObject $ACLs -ErrorAction Stop
            } catch {
                Write-Warning "Set-ADACLOwner - Unable to change owner from $($CurrentOwner) to $PrincipalIdentity for $($DistinguishedName): $($_.Exception.Message)"
            }
            # }
        }
    }
    End {

    }
}