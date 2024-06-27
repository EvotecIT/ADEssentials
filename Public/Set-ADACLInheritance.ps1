function Set-ADACLInheritance {
    <#
    .SYNOPSIS
    Enables or Disables the inheritance of access control entries (ACEs) from parent objects for one or more Active Directory objects or security principals.

    .DESCRIPTION
    Enables or Disables the inheritance of access control entries (ACEs) from parent objects for one or more Active Directory objects or security principals.

    .PARAMETER ADObject
    Specifies one or more Active Directory objects or security principals to enable or disable inheritance of ACEs from parent objects.
    This parameter is mandatory when the 'ADObject' parameter set is used.

    .PARAMETER ACL
    Specifies one or more access control lists (ACLs) to enable or disable inheritance of ACEs from parent objects.
    This parameter is mandatory when the 'ACL' parameter set is used.

    .PARAMETER Inheritance
    Specifies whether to enable or disable inheritance of ACEs from parent objects.

    .PARAMETER RemoveInheritedAccessRules
    Indicates whether to remove inherited ACEs from the object or principal.

    .EXAMPLE
    Set-ADACLInheritance -ADObject 'CN=TestOU,DC=contoso,DC=com' -Inheritance 'Disabled' -RemoveInheritedAccessRules

    .EXAMPLE
    Set-ADACLInheritance -ACL $ACL -Inheritance 'Disabled' -RemoveInheritedAccessRules

    .EXAMPLE
    Set-ADACLInheritance -ADObject 'CN=TestOU,DC=contoso,DC=com' -Inheritance 'Enabled'

    .NOTES
    General notes
    #>
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ADObject')]
    param(
        [parameter(ParameterSetName = 'ADObject', Mandatory)][alias('Identity')][Array] $ADObject,
        [parameter(ParameterSetName = 'ACL', Mandatory)][Array] $ACL,

        [Parameter(Mandatory)][ValidateSet('Enabled', 'Disabled')] $Inheritance,
        [switch] $RemoveInheritedAccessRules
    )
    if (-not $Script:ForestDetails) {
        Write-Verbose "Set-ADACLInheritance - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }

    $PreserveInheritance = -not $RemoveInheritedAccessRules.IsPresent

    if ($ACL) {
        foreach ($A in $ACL) {
            # isProtected -  true to protect the access rules associated with this ObjectSecurity object from inheritance; false to allow inheritance.
            # preserveInheritance - true to preserve inherited access rules; false to remove inherited access rules. This parameter is ignored if isProtected is false.
            if ($Inheritance -eq 'Enabled') {
                $A.ACL.SetAccessRuleProtection($false, -not $RemoveInheritedAccessRules.IsPresent)
                $Action = "Inheritance $Inheritance"
                Write-Verbose "Set-ADACLInheritance - Enabling inheritance for $($A.DistinguishedName)"
            } elseif ($Inheritance -eq 'Disabled') {
                $Action = "Inheritance $Inheritance, RemoveInheritedAccessRules $RemoveInheritedAccessRules"
                $A.ACL.SetAccessRuleProtection($true, $PreserveInheritance)
                Write-Verbose "Set-ADACLInheritance - Disabling inheritance for $($A.DistinguishedName) / Remove Inherited Rules: $($RemoveInheritedAccessRules.IsPresent)"
            }
            $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $A.DistinguishedName
            $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

            if ($PSCmdlet.ShouldProcess($A.DistinguishedName, $Action)) {
                Write-Verbose "Set-ADACLInheritance - Saving permissions for $($A.DistinguishedName) on $QueryServer"
                try {
                    Set-ADObject -Identity $A.DistinguishedName -Replace @{ ntSecurityDescriptor = $A.ACL } -ErrorAction Stop -Server $QueryServer
                } catch {
                    Write-Warning "Set-ADACLInheritance - Saving permissions for $($A.DistinguishedName) on $QueryServer failed: $($_.Exception.Message)"
                }
            }
        }
    } else {
        foreach ($Object in $ADObject) {
            $getADACLSplat = @{
                ADObject = $ADObject
                Bundle   = $true
                Resolve  = $true
            }
            $ACL = Get-ADACL @getADACLSplat
            # isProtected -  true to protect the access rules associated with this ObjectSecurity object from inheritance; false to allow inheritance.
            # preserveInheritance - true to preserve inherited access rules; false to remove inherited access rules. This parameter is ignored if isProtected is false.
            if ($Inheritance -eq 'Enabled') {
                $ACL.ACL.SetAccessRuleProtection($false, -not $RemoveInheritedAccessRules.IsPresent)
                $Action = "Inheritance $Inheritance"
                Write-Verbose "Set-ADACLInheritance - Enabling inheritance for $($ACL.DistinguishedName)"
            } elseif ($Inheritance -eq 'Disabled') {
                $Action = "Inheritance $Inheritance, RemoveInheritedAccessRules $RemoveInheritedAccessRules"
                $ACL.ACL.SetAccessRuleProtection($true, $PreserveInheritance)
                Write-Verbose "Set-ADACLInheritance - Disabling inheritance for $($ACL.DistinguishedName) / Remove Inherited Rules: $($RemoveInheritedAccessRules.IsPresent)"
            }
            $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $ACL.DistinguishedName
            $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

            if ($PSCmdlet.ShouldProcess($ACL.DistinguishedName, $Action)) {
                Write-Verbose "Set-ADACLInheritance - Saving permissions for $($ACL.DistinguishedName) on $QueryServer"
                try {
                    Set-ADObject -Identity $ACL.DistinguishedName -Replace @{ ntSecurityDescriptor = $ACL.ACL } -ErrorAction Stop -Server $QueryServer
                    # Set-Acl -Path $ACL.Path -AclObject $ACL.ACL -ErrorAction Stop
                } catch {
                    Write-Warning "Set-ADACLInheritance - Saving permissions for $($ACL.DistinguishedName) on $QueryServer failed: $($_.Exception.Message)"
                }
            }
        }
    }
}