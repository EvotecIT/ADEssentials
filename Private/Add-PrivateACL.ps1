function Add-PrivateACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [PSCustomObject] $ACL,
        [string] $ADObject,
        [string] $Principal,
        [alias('ActiveDirectoryRights')][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [System.Security.AccessControl.AccessControlType] $AccessControlType,
        [alias('ObjectTypeName')][string] $ObjectType,
        [alias('InheritedObjectTypeName')][string] $InheritedObjectType,
        [alias('ActiveDirectorySecurityInheritance')][nullable[System.DirectoryServices.ActiveDirectorySecurityInheritance]] $InheritanceType,
        [alias('ActiveDirectorySecurity')][System.DirectoryServices.ActiveDirectorySecurity] $NTSecurityDescriptor,
        [System.DirectoryServices.ActiveDirectoryAccessRule] $ActiveDirectoryAccessRule
    )
    if ($ACL) {
        $ADObject = $ACL.DistinguishedName
    } else {
        if (-not $ADObject) {
            Write-Warning "Add-PrivateACL - No ACL or ADObject specified"
            return
        }
    }

    $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $ADObject
    if (-not $DomainName) {
        Write-Warning -Message "Add-PrivateACL - Unable to determine domain name for $($ADObject)"
        return
    }
    $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

    if (-not $ActiveDirectoryAccessRule) {
        if ($Principal -like '*/*') {
            $SplittedName = $Principal -split '/'
            [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($SplittedName[0], $SplittedName[1])
        } else {
            [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.NTAccount]::new($Principal)
        }
    }

    $OutputRequiresCommit = @(
        $newActiveDirectoryAccessRuleSplat = @{
            Identity                  = $Identity
            ActiveDirectoryAccessRule = $ActiveDirectoryAccessRule
            ObjectType                = $ObjectType
            InheritanceType           = $InheritanceType
            InheritedObjectType       = $InheritedObjectType
            AccessControlType         = $AccessControlType
            AccessRule                = $AccessRule
        }
        Remove-EmptyValue -Hashtable $newActiveDirectoryAccessRuleSplat
        $AccessRuleToAdd = New-ActiveDirectoryAccessRule @newActiveDirectoryAccessRuleSplat
        $RuleAdded = Add-ACLRule -AccessRuleToAdd $AccessRuleToAdd -ntSecurityDescriptor $NTSecurityDescriptor -ACL $ACL
        if (-not $RuleAdded.Success -and $RuleAdded.Reason -eq 'Identity') {
            # rule failed to add, so we need to convert the identity and try with SID
            $AlternativeSID = (Convert-Identity -Identity $Identity).SID
            [System.Security.Principal.IdentityReference] $Identity = [System.Security.Principal.SecurityIdentifier]::new($AlternativeSID)
            $newActiveDirectoryAccessRuleSplat = @{
                Identity                  = $Identity
                ActiveDirectoryAccessRule = $ActiveDirectoryAccessRule
                ObjectType                = $ObjectType
                InheritanceType           = $InheritanceType
                InheritedObjectType       = $InheritedObjectType
                AccessControlType         = $AccessControlType
                AccessRule                = $AccessRule
            }
            Remove-EmptyValue -Hashtable $newActiveDirectoryAccessRuleSplat
            $AccessRuleToAdd = New-ActiveDirectoryAccessRule @newActiveDirectoryAccessRuleSplat
            $RuleAdded = Add-ACLRule -AccessRuleToAdd $AccessRuleToAdd -ntSecurityDescriptor $NTSecurityDescriptor -ACL $ACL
        }
        # lets now return value
        $RuleAdded.Success
    )
    if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
        Write-Verbose "Add-ADACL - Saving permissions for $($ADObject)"
        #Set-Acl -Path $ACL.Path -AclObject $ACL.ACL -ErrorAction Stop

        Set-ADObject -Identity $ADObject -Replace @{ ntSecurityDescriptor = $ntSecurityDescriptor } -ErrorAction Stop -Server $QueryServer
    } elseif ($OutputRequiresCommit -contains $false) {
        Write-Warning "Add-ADACL - Skipping saving permissions for $($ADObject) due to errors."
    }
}