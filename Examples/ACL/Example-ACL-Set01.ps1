Clear-Host
Import-Module $PSScriptRoot\..\..\ADEssentials.psd1 -Force

$Test = Set-ADACL -WhatIf:$false -Verbose -ADObject $FindOu -Inheritance Disabled -ACLSettings @(
    Export-ADACLObject -ADObject 'DC=ad,DC=evotec,DC=xyz' -OneLiner -ExcludePrincipal 'BUILTIN\Pre-Windows 2000 Compatible Access'
    Export-ADACLObject -ADObject 'DC=ad,DC=evotec,DC=xyz' -OneLiner -IncludePrincipal 'BUILTIN\Incoming Forest Trust Builders'
    @{
        Principal = 'EVOTEC\Key Admins', 'EVOTEC\Enterprise Key Admins'
        Action    = 'Skip'
    }
    @{
        Principal = 'EVOTEC\Domain Admins'
        Action    = 'Skip'
    }
    @{
        Principal         = 'Print Operators'
        Action            = 'Skip'
        AccessControlType = 'Allow'
    }
    @{
        Principal = 'EVOTEC\Exchange Servers'
        Action    = 'Skip'
    }
    @{
        Principal   = 'EVOTEC\Organization Management'
        Permissions = @(
            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'All'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'GenericRead'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Exchange-Personal-Information'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Show-In-Address-Book'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Admin-Display-Name'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Legacy-Exchange-DN'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Garbage-Coll-Period'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Display-Name'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Proxy-Addresses'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'ms-Exch-Public-Delegates'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'ms-Exch-Dynamic-Distribution-List'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'GenericAll'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Display-Name-Printable'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Exchange-Information'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'E-mail-Addresses'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Text-Encoded-OR-Address'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'WriteProperty'
                'InheritanceType'         = 'All'
            }
        )
    }
    @{
        Principal = 'EVOTEC\Exchange Trusted Subsystem'
        Action    = 'Skip'
    }
    @{
        Principal = 'EVOTEC\MSOL_6f0d1d4965ec'
        Action    = 'Skip'
    }
    @{
        Principal = 'EVOTEC\Exchange Windows Permissions'
        Action    = 'Skip'
    }
    @{
        Principal = 'NT AUTHORITY\SELF'
        Action    = 'Skip'
    }
    @{
        Principal = 'NT AUTHORITY\Authenticated Users'
        Action    = 'Skip'
    }
    @{
        Principal = 'NT AUTHORITY\SYSTEM'
        Action    = 'Skip'
    }
    New-ADACLObject -Principal 'przemyslaw.klys' -AccessControlType Allow -ObjectType All -InheritedObjectTypeName All -AccessRule GenericAll -InheritanceType None
    @{
        Principal   = 'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
        Permissions = @(
            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'All'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'GenericAll'
                'InheritanceType'         = 'None'
            }
            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'All'
                'InheritedObjectTypeName' = 'All'
                'ActiveDirectoryRights'   = 'GenericRead'
                'InheritanceType'         = 'None'
            }
            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Token-Groups'
                'InheritedObjectTypeName' = 'Computer'
                'ActiveDirectoryRights'   = 'ReadProperty'
                'InheritanceType'         = 'Descendents'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Token-Groups'
                'InheritedObjectTypeName' = 'Group'
                'ActiveDirectoryRights'   = 'ReadProperty'
                'InheritanceType'         = 'Descendents'
            }

            @{
                'AccessControlType'       = 'Allow'
                'ObjectTypeName'          = 'Token-Groups'
                'InheritedObjectTypeName' = 'User'
                'ActiveDirectoryRights'   = 'ReadProperty'
                'InheritanceType'         = 'Descendents'
            }
        )
    }
)
# Lets see the output
$Test
$Test.Skip | Format-Table
$Test.Remove | Format-Table
$Test.Add | Format-Table

# Lets verify ACL
$ACL = Get-ADACL -ADObject $FindOu
$IgnoreKeys = 'DistinguishedName', 'CanonicalName', 'ObjectClass', 'IsInherited', 'Principal'
$ACL | Where-Object { $_.Principal -eq 'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS' } | ConvertFrom-ObjectToString -ExcludeProperties $IgnoreKeys
$ACL | Where-Object { $_.Principal -eq 'EVOTEC\Organization Management' } | ConvertFrom-ObjectToString -ExcludeProperties $IgnoreKeys


