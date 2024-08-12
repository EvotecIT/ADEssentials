function Get-WinADDelegatedAccounts {
    <#
    .SYNOPSIS
    Retrieves delegated accounts information from Active Directory.

    .DESCRIPTION
    This function retrieves delegated accounts information from Active Directory based on the specified parameters.

    .PARAMETER Forest
    Specifies the name of the forest to retrieve delegated accounts information from.

    .PARAMETER ExcludeDomains
    Specifies an array of domains to exclude from the search.

    .PARAMETER ExcludeDomainControllers
    Specifies an array of domain controllers to exclude from the search.

    .PARAMETER IncludeDomains
    Specifies an array of domains to include in the search.

    .PARAMETER IncludeDomainControllers
    Specifies an array of domain controllers to include in the search.

    .PARAMETER SkipRODC
    Indicates whether to skip Read-Only Domain Controllers (RODC) during the search.

    .PARAMETER ExtendedForestInformation
    Specifies additional forest information to include in the search.

    .NOTES
    File Name      : Get-WinADDelegatedAccounts.ps1
    Author         : Your Name
    Prerequisite   : This function requires the Active Directory module.

    .EXAMPLE
    Get-WinADDelegatedAccounts -Forest "contoso.com" -IncludeDomains "child1.contoso.com", "child2.contoso.com" -ExcludeDomains "test.contoso.com" -ExtendedForestInformation $ExtendedInfo
    Retrieves delegated accounts information from the "contoso.com" forest, including child domains "child1.contoso.com" and "child2.contoso.com", excluding the "test.contoso.com" domain, and using extended forest information.

    #>

    [CmdletBinding()]
    Param (
        [alias('ForestName')][string] $Forest,
        [string[]] $ExcludeDomains,
        [string[]] $ExcludeDomainControllers,
        [alias('Domain', 'Domains')][string[]] $IncludeDomains,
        [alias('DomainControllers', 'ComputerName')][string[]] $IncludeDomainControllers,
        [switch] $SkipRODC,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -IncludeDomains $IncludeDomains -ExcludeDomains $ExcludeDomains -ExtendedForestInformation $ExtendedForestInformation -Extended
    foreach ($Domain in $ForestInformation.Domains) {

        $SERVER_TRUST_ACCOUNT = 0x2000
        $TRUSTED_FOR_DELEGATION = 0x80000
        $TRUSTED_TO_AUTH_FOR_DELEGATION = 0x1000000
        $PARTIAL_SECRETS_ACCOUNT = 0x4000000

        $bitmask = $TRUSTED_FOR_DELEGATION -bor $TRUSTED_TO_AUTH_FOR_DELEGATION -bor $PARTIAL_SECRETS_ACCOUNT

        $filter = @"
(&
  (servicePrincipalname=*)
  (|
    (msDS-AllowedToActOnBehalfOfOtherIdentity=*)
    (msDS-AllowedToDelegateTo=*)
    (UserAccountControl:1.2.840.113556.1.4.804:=$bitmask)
  )
  (|
    (objectcategory=computer)
    (objectcategory=person)
    (objectcategory=msDS-GroupManagedServiceAccount)
    (objectcategory=msDS-ManagedServiceAccount)
  )
)
"@ -replace "[\s\n]", ''

        $PropertyList = @(
            'Enabled'
            "servicePrincipalname",
            "useraccountcontrol",
            "samaccountname",
            "msDS-AllowedToDelegateTo",
            "msDS-AllowedToActOnBehalfOfOtherIdentity"
            'IsCriticalSystemObject'
            'LastLogon'
            'PwdLastSet'
            'WhenChanged'
            'WhenCreated'
        )

        try {
            $Accounts = Get-ADObject -LDAPFilter $filter -SearchBase $ForestInformation.DomainsExtended[$Domain].DistinguishedName -SearchScope Subtree -Properties $propertylist -Server $ForestInformation.QueryServers[$Domain].HostName[0]
        } catch {
            $Accounts = $null
            Write-Warning -Message "Get-WinADDelegatedAccounts - Failed to get information: $($_.Exception.Message)"
        }

        foreach ($Account in $Accounts) {
            $UAC = Convert-UserAccountControl -UserAccountControl $Account.useraccountcontrol
            $IsDC = ($Account.useraccountcontrol -band $SERVER_TRUST_ACCOUNT) -ne 0
            $FullDelegation = ($Account.useraccountcontrol -band $TRUSTED_FOR_DELEGATION) -ne 0
            $ConstrainedDelegation = ($Account.'msDS-AllowedToDelegateTo').count -gt 0
            $IsRODC = ($Account.useraccountcontrol -band $PARTIAL_SECRETS_ACCOUNT) -ne 0
            $ResourceDelegation = $null -ne $Account.'msDS-AllowedToActOnBehalfOfOtherIdentity'
            $PasswordLastSet = [datetime]::FromFileTimeUtc($Account.pwdLastSet)
            $LastLogonDate = [datetime]::FromFileTimeUtc($Account.LastLogon)

            [PSCustomobject] @{
                DomainName                          = $Domain
                SamAccountName                      = $Account.samaccountname
                Enabled                             = $UAC -notcontains 'ACCOUNTDISABLE'
                ObjectClass                         = $Account.objectclass
                IsDC                                = $IsDC
                IsRODC                              = $IsRODC
                FullDelegation                      = $FullDelegation
                ConstrainedDelegation               = $ConstrainedDelegation
                ResourceDelegation                  = $ResourceDelegation
                LastLogonDate                       = $LastLogonDate
                PasswordLastSet                     = $PasswordLastSet
                UserAccountControl                  = $UAC
                WhenCreated                         = $Account.WhenCreated
                WhenChanged                         = $Account.WhenChanged
                IsCriticalSystemObject              = $Account.IsCriticalSystemObject
                AllowedToDelagateTo                 = $Account.'msDS-AllowedToDelegateTo'
                AllowedToActOnBehalfOfOtherIdentity = $Account.'msDS-AllowedToActOnBehalfOfOtherIdentity'
            }
        }
    }
}