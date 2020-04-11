function Add-ADACL {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][Array] $ACL,
        [Parameter(Mandatory)][string] $Principal,
        [Parameter(Mandatory)][System.DirectoryServices.ActiveDirectoryRights] $AccessRule,
        [Parameter(Mandatory)][System.Security.AccessControl.AccessControlType] $AccessControlType
    )
    #System.Security.Principal.NTAccount new(string domainName, string accountName)
    #System.Security.Principal.NTAccount new(string name)

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

    foreach ($SubACL in $ACL) {
        $OutputRequiresCommit = foreach ($Rule in $AccessRule) {
            $AccessRuleToAdd = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($Identity, $Rule, $AccessControlType)
            try {
                Write-Verbose "Add-ADACL - Adding access for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights)"
                $SubACL.ACL.AddAccessRule($AccessRuleToAdd)
                $true
            } catch {
                Write-Warning "Add-ADACL - Error adding permissions for $($AccessRuleToAdd.IdentityReference) / $($AccessRuleToAdd.ActiveDirectoryRights) due to error: $($_.Exception.Message)"
                $false
            }
        }
        if ($OutputRequiresCommit -notcontains $false -and $OutputRequiresCommit -contains $true) {
            Write-Verbose "Add-ADACL - Saving permissions for $($SubACL.DistinguishedName)"
            Set-Acl -Path $SubACL.Path -AclObject $SubACL.ACL -ErrorAction Stop
        } elseif ($OutputRequiresCommit -contains $false) {
            Write-Warning "Add-ADACL - Skipping saving permissions for $($SubACL.DistinguishedName) due to errors."
        }
    }
}

<#
   TypeName: System.DirectoryServices.ActiveDirectorySecurity

Name                            MemberType     Definition
----                            ----------     ----------
Access                          CodeProperty   System.Security.AccessControl.AuthorizationRuleCollection Access{get=GetAccess;}
CentralAccessPolicyId           CodeProperty   System.Security.Principal.SecurityIdentifier CentralAccessPolicyId{get=GetCentralAccessPolicyId;}
CentralAccessPolicyName         CodeProperty   System.String CentralAccessPolicyName{get=GetCentralAccessPolicyName;}
Group                           CodeProperty   System.String Group{get=GetGroup;}
Owner                           CodeProperty   System.String Owner{get=GetOwner;}
Path                            CodeProperty   System.String Path{get=GetPath;}
Sddl                            CodeProperty   System.String Sddl{get=GetSddl;}
AccessRuleFactory               Method         System.Security.AccessControl.AccessRule AccessRuleFactory(System.Security.Principal.IdentityReference identityReference, int accessMask, bool isInherited, System.Security.AccessControl.InheritanceFlags inheritanceFlags, System.Security.AccessControl.PropagationFlags propagationFlags, System.Securi...
AddAccessRule                   Method         void AddAccessRule(System.DirectoryServices.ActiveDirectoryAccessRule rule)
AddAuditRule                    Method         void AddAuditRule(System.DirectoryServices.ActiveDirectoryAuditRule rule)
AuditRuleFactory                Method         System.Security.AccessControl.AuditRule AuditRuleFactory(System.Security.Principal.IdentityReference identityReference, int accessMask, bool isInherited, System.Security.AccessControl.InheritanceFlags inheritanceFlags, System.Security.AccessControl.PropagationFlags propagationFlags, System.Security...
Equals                          Method         bool Equals(System.Object obj)
GetAccessRules                  Method         System.Security.AccessControl.AuthorizationRuleCollection GetAccessRules(bool includeExplicit, bool includeInherited, type targetType)
GetAuditRules                   Method         System.Security.AccessControl.AuthorizationRuleCollection GetAuditRules(bool includeExplicit, bool includeInherited, type targetType)
GetGroup                        Method         System.Security.Principal.IdentityReference GetGroup(type targetType)
GetHashCode                     Method         int GetHashCode()
GetOwner                        Method         System.Security.Principal.IdentityReference GetOwner(type targetType)
GetSecurityDescriptorBinaryForm Method         byte[] GetSecurityDescriptorBinaryForm()
GetSecurityDescriptorSddlForm   Method         string GetSecurityDescriptorSddlForm(System.Security.AccessControl.AccessControlSections includeSections)
GetType                         Method         type GetType()
ModifyAccessRule                Method         bool ModifyAccessRule(System.Security.AccessControl.AccessControlModification modification, System.Security.AccessControl.AccessRule rule, [ref] bool modified)
ModifyAuditRule                 Method         bool ModifyAuditRule(System.Security.AccessControl.AccessControlModification modification, System.Security.AccessControl.AuditRule rule, [ref] bool modified)
PurgeAccessRules                Method         void PurgeAccessRules(System.Security.Principal.IdentityReference identity)
PurgeAuditRules                 Method         void PurgeAuditRules(System.Security.Principal.IdentityReference identity)
RemoveAccess                    Method         void RemoveAccess(System.Security.Principal.IdentityReference identity, System.Security.AccessControl.AccessControlType type)
RemoveAccessRule                Method         bool RemoveAccessRule(System.DirectoryServices.ActiveDirectoryAccessRule rule)
RemoveAccessRuleSpecific        Method         void RemoveAccessRuleSpecific(System.DirectoryServices.ActiveDirectoryAccessRule rule)
RemoveAudit                     Method         void RemoveAudit(System.Security.Principal.IdentityReference identity)
RemoveAuditRule                 Method         bool RemoveAuditRule(System.DirectoryServices.ActiveDirectoryAuditRule rule)
RemoveAuditRuleSpecific         Method         void RemoveAuditRuleSpecific(System.DirectoryServices.ActiveDirectoryAuditRule rule)
ResetAccessRule                 Method         void ResetAccessRule(System.DirectoryServices.ActiveDirectoryAccessRule rule)
SetAccessRule                   Method         void SetAccessRule(System.DirectoryServices.ActiveDirectoryAccessRule rule)
SetAccessRuleProtection         Method         void SetAccessRuleProtection(bool isProtected, bool preserveInheritance)
SetAuditRule                    Method         void SetAuditRule(System.DirectoryServices.ActiveDirectoryAuditRule rule)
SetAuditRuleProtection          Method         void SetAuditRuleProtection(bool isProtected, bool preserveInheritance)
SetGroup                        Method         void SetGroup(System.Security.Principal.IdentityReference identity)
SetOwner                        Method         void SetOwner(System.Security.Principal.IdentityReference identity)
SetSecurityDescriptorBinaryForm Method         void SetSecurityDescriptorBinaryForm(byte[] binaryForm), void SetSecurityDescriptorBinaryForm(byte[] binaryForm, System.Security.AccessControl.AccessControlSections includeSections)
SetSecurityDescriptorSddlForm   Method         void SetSecurityDescriptorSddlForm(string sddlForm), void SetSecurityDescriptorSddlForm(string sddlForm, System.Security.AccessControl.AccessControlSections includeSections)
ToString                        Method         string ToString()
PSChildName                     NoteProperty   string PSChildName=OU=Users
PSDrive                         NoteProperty   ADDriveInfo PSDrive=DCadDCevotecDCxyz
PSParentPath                    NoteProperty   string PSParentPath=Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/OU=Production,DC=ad,DC=evotec,DC=xyz
PSPath                          NoteProperty   string PSPath=Microsoft.ActiveDirectory.Management.dll\ActiveDirectory:://RootDSE/OU=Users,OU=Production,DC=ad,DC=evotec,DC=xyz
PSProvider                      NoteProperty   ProviderInfo PSProvider=Microsoft.ActiveDirectory.Management.dll\ActiveDirectory
AccessRightType                 Property       type AccessRightType {get;}
AccessRuleType                  Property       type AccessRuleType {get;}
AreAccessRulesCanonical         Property       bool AreAccessRulesCanonical {get;}
AreAccessRulesProtected         Property       bool AreAccessRulesProtected {get;}
AreAuditRulesCanonical          Property       bool AreAuditRulesCanonical {get;}
AreAuditRulesProtected          Property       bool AreAuditRulesProtected {get;}
AuditRuleType                   Property       type AuditRuleType {get;}
AccessToString                  ScriptProperty System.Object AccessToString {get=$toString = "";...
AuditToString                   ScriptProperty System.Object AuditToString {get=$toString = "";...
#>