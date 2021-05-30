Import-Module $PSScriptRoot\..\ADEssentials.psd1 -Force

#$ACLs = Get-ADACL -ADObject 'OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz' #-Principal 'NT AUTHORITY\SELF'
#$ACLs | Format-Table

#$PathACL = 'DCadDCevotecDCxyz:\CN=Test1,OU=SpecialDir+45,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
#$PathACL = Get-Acl -LiteralPath $PathACL -ErrorAction Stop

#
#'CN=Test4,OU=SpecialDir & Test,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
#'OU=GPO Date & Region\ ,OU=Servers,OU=EU50,OU=EU,OU=ITR02,DC=area1,DC=eurofins,DC=local'
#get-acl -LiteralPath 'CN=Test1,OU=SpecialDir+45,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'

function Get-DsAcl {
    <#
    .SYNOPSIS
        Get directory service access control lists from Active Directory.
    .DESCRIPTION
        Get-DsAcl uses ADSI to retrieve the security descriptor from an account. Descriptions of extended attributes are read from the Schema.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByObjectClass')]
    param (
        [String]$SearchBase,

        [Parameter(ParameterSetName = 'ByObjectClass')]
        [String]$ObjectType = "organizationalUnit",

        [Parameter(ParameterSetName = 'UsingLdapFilter')]
        [String]$LdapFilter = "(&(objectClass=$ObjectType)(objectCategory=$ObjectType))",

        [Switch]$Inherited
    )

    $rootDSE = [ADSI]'LDAP://RootDSE'
    $schema = [ADSI]('LDAP://{0}' -f $rootDSE.Get('schemaNamingContext'))
    $extendedRights = [ADSI]('LDAP://CN=Extended-Rights,{0}' -f $rootDSE.Get('configurationNamingContext'))

    $searcher = [ADSISearcher]$LdapFilter
    if ($SearchBase) {
        $searcher.SearchRoot = [ADSI]('LDAP://{0}' -f $SearchBase)
    }
    $searcher.PageSize = 1000
    $searcher.FindAll() | ForEach-Object {
        $Object = $_.GetDirectoryEntry()

        # Retrieve all Access Control Entries from the AD Object
        $acl = $Object.PsBase.ObjectSecurity.GetAccessRules($true, $Inherited, [Security.Principal.NTAccount])

        $ACL | Select-Object @{n = 'Name'; e = { $Object.Get("name") } },
        @{n = 'DN'; e = { $Object.Get("distinguishedName") } },
        @{n = 'ObjectClass'; e = { $Object.Class } },
        @{n = 'SecurityPrincipal'; e = { $_.IdentityReference.ToString() } },
        @{n = 'AccessType'; e = { $_.AccessControlType } },
        @{n = 'Permissions'; e = { $_.ActiveDirectoryRights } },
        @{n = 'AppliesTo'; e = {
                # Change the values for InheritanceType to friendly names
                switch ($_.InheritanceType) {
                    "None" { "This object only" }
                    "Descendents" { "All child objects" }
                    "SelfAndChildren" { "This object and one level Of child objects" }
                    "Children" { "One level of child objects" }
                    "All" { "This object and all child objects" }
                }
            }
        },
        @{n = 'AppliesToObjectType'; e = {
                if ($_.InheritedObjectType.ToString() -notmatch "0{8}.*") {
                    # Search for the Object Type in the Schema
                    $LdapFilter = "(SchemaIDGUID=$(($_.InheritedObjectType.ToByteArray() | ForEach-Object { '{0:X2}' -f $_ }) -join '')"

                    $Result = (New-Object DirectoryServices.DirectorySearcher( $Schema, $LdapFilter)).FindOne()
                    $Result.Properties["ldapdisplayname"]
                } else {
                    "All"
                }
            }
        },
        @{n = 'AppliesToProperty'; e = {
                if ($_.ObjectType.ToString() -notmatch "0{8}.*") {
                    # Search for a possible Extended-Right or Property Set
                    $LdapFilter = "(rightsGuid=$($_.ObjectType.ToString()))"
                    $Result = (New-Object DirectoryServices.DirectorySearcher( $ExtendedRights, $LdapFilter)).FindOne()

                    if ($Result) {
                        $Result.Properties["displayname"]
                    } else {
                        # Search for the attribute name in the Schema
                        $LdapFilter = "(SchemaIDGUID=$(($_.ObjectType.ToByteArray() | ForEach-Object { '{0:X2}' -f $_ }) -join ''))"

                        $Result = (New-Object DirectoryServices.DirectorySearcher( $Schema, $LdapFilter)).FindOne()
                        $Result.Properties["ldapdisplayname"]
                    }
                } else {
                    "All"
                }
            }
        },
        @{n = 'Inherited'; e = { $_.IsInherited } }
    }
}











#Get-DsAcl -SearchBase 'OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz' | Format-Table
Get-DsAcl -SearchBase 'CN=Test1,OU=SpecialDir\+45,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz' | Format-Table








return


$Comp = @(
    'AD:OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
    #'CN=AD3,OU=Domain Controllers,DC=ad,DC=evotec,DC=xyz'
    #'CN=ADPREVIEW2019,CN=Computers,DC=ad,DC=evotec,DC=pl'

    'AD:CN=Test1,OU=SpecialDir\\+45,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
    #'CN=Test4,OU=SpecialDir & Test,OU=Computers,OU=Devices,OU=Production,DC=ad,DC=evotec,DC=xyz'
)
foreach ($C in $Comp) {

    #System.DirectoryServices.ActiveDirectorySecurity
    $retVal = [System.DirectoryServices.ActiveDirectorySecurity]::new()
    #$retVal.GetAccessRules()
    # $retVal.SetSecurityDescriptorBinaryForm(sec);
    $retVal.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])

    #Get-Acl -Path $C
    # $ACLs = Get-ADACL -ADObject $C
    # $ACLs | Format-Table
}





return
