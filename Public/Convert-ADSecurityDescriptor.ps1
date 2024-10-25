function Convert-ADSecurityDescriptor {
    <#
    .SYNOPSIS
    Converts a security descriptor to a readable format.

    .DESCRIPTION
    This function converts a security descriptor to a readable format.

    .PARAMETER DistinguishedName
    Specifies the distinguished name of the object.
    This is for display purposes only.

    .PARAMETER SDDL
    Specifies the security descriptor in Security Descriptor Definition Language (SDDL) format.

    .PARAMETER Resolve
    If specified, resolves the identity reference in the security descriptor.

    .EXAMPLE
    $DomainDN = (Get-ADDomain).DistinguishedName
    $FindDN = "CN=Group-Policy-Container,CN=Schema,CN=Configuration,$DomainDN"
    $ADObject = Get-ADObject -Identity $FindDN -Properties *
    $SecurityDescriptor = Convert-ADSecurityDescriptor -SDDL $ADObject.defaultSecurityDescriptor -Resolve -DistinguishedName $FindDN
    $SecurityDescriptor | Format-Table *

    .NOTES
    More information https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.objectsecurity.setsecuritydescriptorsddlform?view=net-8.0
    #>
    [CmdletBinding()]
    param(
        [string] $DistinguishedName,
        [Parameter(Mandatory)][string] $SDDL,
        [switch] $Resolve
    )

    #$sd = [System.DirectoryServices.ActiveDirectorySecurity]::new()
    #$sd.SetSecurityDescriptorSddlForm($Test.defaultSecurityDescriptor)
    #$sd.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::All)

    Begin {
        if (-not $Script:ForestGUIDs) {
            Write-Verbose "Get-ADACL - Gathering Forest GUIDS"
            $Script:ForestGUIDs = Get-WinADForestGUIDs
        }
        if (-not $Script:ForestDetails) {
            Write-Verbose "Get-ADACL - Gathering Forest Details"
            $Script:ForestDetails = Get-WinADForestDetails
        }
        if ($Principal -and $Resolve) {
            $PrincipalRequested = Convert-Identity -Identity $Principal -Verbose:$false
        }
    }
    Process {
        $ACLs = [System.DirectoryServices.ActiveDirectorySecurity]::new()
        $ACLs.SetSecurityDescriptorSddlForm($SDDL)
        $AccessObjects = foreach ($ACL in $ACLs.Access) {
            $SplatFilteredACL = @{
                DistinguishedName                         = $DistinguishedName
                ACL                                       = $ACL
                Resolve                                   = $Resolve
                Principal                                 = $Principal
                Inherited                                 = $Inherited
                NotInherited                              = $NotInherited
                AccessControlType                         = $AccessControlType
                IncludeObjectTypeName                     = $IncludeObjectTypeName
                IncludeInheritedObjectTypeName            = $IncludeInheritedObjectTypeName
                ExcludeObjectTypeName                     = $ExcludeObjectTypeName
                ExcludeInheritedObjectTypeName            = $ExcludeInheritedObjectTypeName
                IncludeActiveDirectoryRights              = $IncludeActiveDirectoryRights
                ExcludeActiveDirectoryRights              = $ExcludeActiveDirectoryRights
                IncludeActiveDirectorySecurityInheritance = $IncludeActiveDirectorySecurityInheritance
                ExcludeActiveDirectorySecurityInheritance = $ExcludeActiveDirectorySecurityInheritance
                PrincipalRequested                        = $PrincipalRequested
                Bundle                                    = $Bundle
            }
            Remove-EmptyValue -Hashtable $SplatFilteredACL
            Get-FilteredACL @SplatFilteredACL
        }
        $AccessObjects
    }
}