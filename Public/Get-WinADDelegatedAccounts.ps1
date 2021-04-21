function Get-WinADDelegatedAccounts {
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
            $accounts = Get-ADObject -LDAPFilter $filter -SearchBase $ForestInformation.DomainsExtended[$Domain].DistinguishedName -SearchScope Subtree -Properties $propertylist -Server $ForestInformation.QueryServers[$Domain].HostName[0]
        } catch {
            $accounts = $null
            Write-Warning "Failed to query $Server. Consider investigating seperately. $($_.Exception.Message)"
        }

        foreach ($Account in $accounts) {
            $isDC = ($Account.useraccountcontrol -band $SERVER_TRUST_ACCOUNT) -ne 0
            $fullDelegation = ($Account.useraccountcontrol -band $TRUSTED_FOR_DELEGATION) -ne 0
            $constrainedDelegation = ($Account.'msDS-AllowedToDelegateTo').count -gt 0
            $isRODC = ($Account.useraccountcontrol -band $PARTIAL_SECRETS_ACCOUNT) -ne 0
            $resourceDelegation = $null -ne $Account.'msDS-AllowedToActOnBehalfOfOtherIdentity'
            $PasswordLastSet = [datetime]::FromFileTimeUtc($Account.pwdLastSet)
            $LastLogonDate = [datetime]::FromFileTimeUtc($Account.LastLogon)

            [PSCustomobject] @{
                DomainName                          = $Domain
                SamAccountName                      = $Account.samaccountname
                Enabled                             = $Account.Enabled
                ObjectClass                         = $Account.objectclass
                IsDC                                = $isDC
                IsRODC                              = $isRODC
                FullDelegation                      = $fullDelegation
                ConstrainedDelegation               = $constrainedDelegation
                ResourceDelegation                  = $resourceDelegation
                WhenCreated                         = $Account.WhenCreated
                WhenChanged                         = $Account.WhenChanged
                LastLogonDate                       = $LastLogonDate
                PasswordLastSet                     = $PasswordLastSet
                IsCriticalSystemObject              = $Account.IsCriticalSystemObject
                AllowedToDelagateTo                 = $Account.'msDS-AllowedToDelegateTo'
                AllowedToActOnBehalfOfOtherIdentity = $Account.'msDS-AllowedToActOnBehalfOfOtherIdentity'
            }
        }
    }
}