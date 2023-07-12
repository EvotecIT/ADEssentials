function Get-WinADComputerACLLAPS {
    <#
    .SYNOPSIS
    Gathers information from all computers whether they have ACL to write to LAPS properties or not

    .DESCRIPTION
    Gathers information from all computers whether they have ACL to write to LAPS properties or not

    .PARAMETER ACLMissingOnly
    Show only computers which do not have ability to write to LAPS properties

    .EXAMPLE
    Get-WinADComputerAclLAPS | Format-Table *

    .EXAMPLE
    Get-WinADComputerAclLAPS -ACLMissingOnly | Format-Table *

    .NOTES
    General notes
    #>
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [switch] $ACLMissingOnly,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation

    foreach ($Domain in $ForestInformation.Domains) {
        $Computers = Get-ADComputer -Filter * -Properties PrimaryGroupID, LastLogonDate, PasswordLastSet, WhenChanged, OperatingSystem, servicePrincipalName -Server $ForestInformation.QueryServers[$Domain].HostName[0]
        foreach ($Computer in $Computers) {
            $ComputerLocation = ($Computer.DistinguishedName -split ',').Replace('OU=', '').Replace('CN=', '').Replace('DC=', '')
            $Region = $ComputerLocation[-4]
            $Country = $ComputerLocation[-5]
            $ACLs = Get-ADACL -ADObject $Computer.DistinguishedName -Principal 'NT AUTHORITY\SELF'

            $LAPS = $false
            $LAPSExpirationTime = $false
            $WindowsLAPS = $false
            $WindowsLAPSExpirationTime = $false
            $WindowsLAPSEncryptedPassword = $false
            #$WindowsLAPSEncryptedPasswordHistory = $false
            #$WindowsLAPSEncryptedDSRMPassword = $false
            # $WindowsLAPSEncryptedDSRMPasswordHistory = $false

            <#
            msLAPS-PasswordExpirationTime
            msLAPS-Password
            msLAPS-EncryptedPassword
            msLAPS-EncryptedPasswordHistory
            msLAPS-EncryptedDSRMPassword
            msLAPS-EncryptedDSRMPasswordHistory
            #>

            foreach ($ACL in $ACLs) {
                if ($ACL.ObjectTypeName -eq 'ms-Mcs-AdmPwd') {
                    # LAPS
                    if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                        $LAPS = $true
                    }
                } elseif ($ACL.ObjectTypeName -eq 'ms-Mcs-AdmPwdExpirationTime') {
                    # LAPS
                    if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                        $LAPSExpirationTime = $true
                    }
                } elseif ($ACL.ObjectTypeName -eq 'ms-LAPS-Password') {
                    # Windows LAPS
                    if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                        $WindowsLAPS = $true
                    }
                } elseif ($ACL.ObjectTypeName -eq 'ms-LAPS-PasswordExpirationTime') {
                    # Windows LAPS
                    if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                        $WindowsLAPSExpirationTime = $true
                    }
                } elseif ($ACL.ObjectTypeName -eq 'ms-LAPS-Encrypted-Password-Attributes') {
                    if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                        $WindowsLAPSEncryptedPassword = $true
                    }
                }
                #  elseif ($ACL.ObjectTypeName -eq 'ms-LAPS-EncryptedPasswordHistory') {
                #     if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                #         $WindowsLAPSEncryptedPasswordHistory = $true
                #     }
                # } elseif ($ACL.ObjectTypeName -eq 'ms-LAPS-EncryptedDSRMPassword') {
                #     if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                #         $WindowsLAPSEncryptedDSRMPassword = $true
                #     }
                # } elseif ($ACL.ObjectTypeName -eq 'ms-LAPS-EncryptedDSRMPasswordHistory') {
                #     if ($ACL.AccessControlType -eq 'Allow' -and $ACL.ActiveDirectoryRights -like '*WriteProperty*') {
                #         $WindowsLAPSEncryptedDSRMPasswordHistory = $true
                #     }
                # }
            }
            if ($ACLMissingOnly -and $LAPS -eq $true) {
                continue
            }

            [PSCustomObject] @{
                Name                         = $Computer.Name
                SamAccountName               = $Computer.SamAccountName
                DomainName                   = $Domain
                Enabled                      = $Computer.Enabled
                IsDC                         = if ($Computer.PrimaryGroupID -in 516, 521) { $true } else { $false }
                WhenChanged                  = $Computer.WhenChanged
                LapsACL                      = $LAPS
                LapsExpirationACL            = $LAPSExpirationTime
                WindowsLAPSACL               = $WindowsLAPS
                WindowsLAPSExpirationACL     = $WindowsLAPSExpirationTime
                WindowsLAPSEncryptedPassword = $WindowsLAPSEncryptedPassword
                #WindowsLAPSEncryptedPasswordHistory = $WindowsLAPSEncryptedPasswordHistory
                #WindowsLAPSEncryptedDSRMPassword        = $WindowsLAPSEncryptedDSRMPassword
                #WindowsLAPSEncryptedDSRMPasswordHistory = $WindowsLAPSEncryptedDSRMPasswordHistory
                OperatingSystem              = $Computer.OperatingSystem
                Level0                       = $Region
                Level1                       = $Country
                DistinguishedName            = $Computer.DistinguishedName
                LastLogonDate                = $Computer.LastLogonDate
                PasswordLastSet              = $Computer.PasswordLastSet
                ServicePrincipalName         = $Computer.servicePrincipalName
            }

        }
    }
}