function Set-ADACLInheritance {
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
    if ($ACL) {
        foreach ($A in $ACL) {

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
            } elseif ($Inheritance -eq 'Disabled') {
                $Action = "Inheritance $Inheritance, RemoveInheritedAccessRules $RemoveInheritedAccessRules"
                $ACL.ACL.SetAccessRuleProtection($true, -not $RemoveInheritedAccessRules.IsPresent)
            }
            $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $ACL.DistinguishedName
            $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

            if ($PSCmdlet.ShouldProcess($ACL.DistinguishedName, $Action)) {
                Write-Verbose "Set-ADACLInheritance - Saving permissions for $($ACL.DistinguishedName)"
                try {
                    Set-ADObject -Identity $ACL.DistinguishedName -Replace @{ ntSecurityDescriptor = $ACL.ACL } -ErrorAction Stop -Server $QueryServer
                    # Set-Acl -Path $ACL.Path -AclObject $ACL.ACL -ErrorAction Stop
                } catch {
                    Write-Warning "Set-ADACLInheritance - Saving permissions for $($ACL.DistinguishedName) failed: $($_.Exception.Message)"
                }
            }
        }
    }
}