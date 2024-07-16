function Add-PrivateACL {
    <#
    .SYNOPSIS
    Adds a new access control rule to a security descriptor.

    .DESCRIPTION
    This function adds a new access control rule to a security descriptor. It allows specifying various parameters such as the ACL, principal, access rule, access control type, object type name, inherited object type name, inheritance type, and NT security descriptor.

    .PARAMETER ACL
    Specifies the ACL object to be processed.

    .PARAMETER ADObject
    Specifies the Active Directory object to which the ACL belongs.

    .PARAMETER Principal
    Specifies the principal for which the access control rule is added.

    .PARAMETER AccessRule
    Specifies the access rule to be added.

    .PARAMETER AccessControlType
    Specifies the type of access control to be added.

    .PARAMETER ObjectType
    Specifies the object type name.

    .PARAMETER InheritedObjectType
    Specifies the inherited object type name.

    .PARAMETER InheritanceType
    Specifies the inheritance type to consider.

    .PARAMETER NTSecurityDescriptor
    Specifies the NT security descriptor to be updated.

    .PARAMETER ActiveDirectoryAccessRule
    Specifies the Active Directory access rule to be added.

    .EXAMPLE
    Add-PrivateACL -ACL $ACLObject -ADObject "CN=Example,DC=Domain,DC=com" -Principal "User1" -AccessRule "Read" -AccessControlType "Allow" -ObjectType "File" -InheritedObjectType "Folder" -InheritanceType All -NTSecurityDescriptor $SecurityDescriptor -ActiveDirectoryAccessRule $ADAccessRule

    Adds a new access control rule for User1 with Read access on files within folders with inheritance for all objects.

    .NOTES
    Author: Your Name
    Date: Date
    #>
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
        if ($AccessRuleToAdd) {
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
        } else {
            Write-Warning -Message "Add-PrivateACL - Unable to create ActiveDirectoryAccessRule for $($ADObject). Skipped."
            $false
        }
    )
    if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
        Write-Verbose "Add-ADACL - Saving permissions for $($ADObject)"
        Set-ADObject -Identity $ADObject -Replace @{ ntSecurityDescriptor = $ntSecurityDescriptor } -ErrorAction Stop -Server $QueryServer
    } elseif ($OutputRequiresCommit -contains $false) {
        Write-Warning "Add-ADACL - Skipping saving permissions for $($ADObject) due to errors."
    }
}