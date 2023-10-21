function Restore-ADACL {
    <#
    .SYNOPSIS
    Restore default permissions for given object in Active Directory

    .DESCRIPTION
    Restore default permissions for given object in Active Directory.
    Equivalent of right click on object in Active Directory Users and Computers and selecting 'Restore defaults'

    .PARAMETER Object
    Specifies Active Directory objects to restore default permissions. This parameter is mandatory.

    .PARAMETER RemoveInheritedAccessRules
    Indicates whether to remove inherited ACEs from the object or principal.
    If this switch is specified, inherited ACEs are removed from the object or principal.
    If this switch is not specified, inherited ACEs are retained on the object or principal.

    .EXAMPLE
    $ObjectCheck = Get-ADObject -Id 'OU=_root,DC=ad,DC=evotec,DC=xyz' -Properties 'NtSecurityDescriptor', 'DistinguishedName'
    Restore-ADACL -Object $ObjectCheck -Verbose

    .EXAMPLE
    Restore-ADACL -Object 'OU=ITR01,DC=ad,DC=evotec,DC=xyz' -RemoveInheritedAccessRules -Verbose -WhatIf

    .NOTES
    General notes
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Identity')][Object] $Object,
        [switch] $RemoveInheritedAccessRules
    )
    # lets get our forest details
    if (-not $Script:ForestDetails) {
        Write-Verbose "Restore-ADACL - Gathering Forest Details"
        $Script:ForestDetails = Get-WinADForestDetails
    }
    # Lets get our schema
    if (-not $Script:RootDSESchema) {
        $Script:RootDSESchema = (Get-ADRootDSE).SchemaNamingContext
    }

    # lets try to asses what we have for object and if not get it properly
    if ($Object) {
        if ($Object -is [Microsoft.ActiveDirectory.Management.ADEntity]) {
            If ($Object.DistinguishedName -and $Object.NtSecurityDescriptor) {
                # We have what we need
            } else {
                $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $Object.DistinguishedName
                $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]
                $Object = Get-ADObject -Id $Object.DistinguishedName -Properties 'NtSecurityDescriptor', 'DistinguishedName' -Server $QueryServer
            }
        } elseif ($Object -is [string]) {
            $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $Object
            $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]
            $Object = Get-ADObject -Id $Object -Properties 'NtSecurityDescriptor', 'DistinguishedName' -Server $QueryServer
        } else {
            Write-Warning -Message "Restore-ADACL - Unknown object type $($Object.GetType().FullName)"
            return
        }
    } else {
        $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $Object
        $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]
        $Object = Get-ADObject -Id $Object -Properties 'NtSecurityDescriptor', 'DistinguishedName' -Server $QueryServer
    }

    # We have our object, now lets get the default permissions for given type

    if ($Object.ObjectClass -eq 'Unknown') {
        Write-Verbose -Message "Restore-ADACL - Unknown object type $($Object.ObjectClass), using default filter for Organizational-Unit"
        $Filter = 'name -eq "Organizational-Unit"'
    } else {
        $Class = $($Object.ObjectClass)
        $Filter = "lDAPDisplayName -eq '$Class'"
    }

    Write-Verbose "Restore-ADACL - Getting default permissions from $Script:RootDSESchema using filter $Filter"
    #$ADObject = Get-ADObject -Filter $Filter -SearchBase $Script:RootDSESchema -Properties defaultSecurityDescriptor
    $DefaultPermissionsObject = Get-ADObject -Filter $Filter -SearchBase (Get-ADRootDSE).SchemaNamingContext -Properties defaultSecurityDescriptor, canonicalName, lDAPDisplayName
    if (-not $DefaultPermissionsObject.defaultsecuritydescriptor) {
        Write-Warning -Message "Restore-ADACL - Unable to find default permissions for $($Object.ObjectClass)"
        return
    }
    $Descriptor = $DefaultPermissionsObject.defaultsecuritydescriptor

    $DomainName = ConvertFrom-DistinguishedName -ToDomainCN -DistinguishedName $Object.DistinguishedName
    $QueryServer = $Script:ForestDetails['QueryServers'][$DomainName].HostName[0]

    Write-Verbose -Message "Restore-ADACL - Disabling inheritance for $($Object.DistinguishedName)"
    Disable-ADACLInheritance -ADObject $Object.DistinguishedName -RemoveInheritedAccessRules -Verbose

    Write-Verbose -Message "Restore-ADACL - Removing permissions for $($Object.DistinguishedName)"
    Remove-ADACL -ADObject $Object.DistinguishedName

    # $Descriptor | ConvertFrom-SddlString -Type ActiveDirectoryRights
    # $SecurityDescriptor = [System.DirectoryServices.ActiveDirectorySecurity]::new()
    # $SecurityDescriptor.SetSecurityDescriptorSddlForm($Descriptor)
    # $SecurityDescriptor

    $Object.NtSecurityDescriptor.SetSecurityDescriptorSddlForm($Descriptor)

    Write-Verbose "Restore-ADACL - Saving permissions for $($Object.DistinguishedName) on $($QueryServer)"
    Set-ADObject -Identity $Object.DistinguishedName -Replace @{ ntSecurityDescriptor = $Object.NtSecurityDescriptor } -ErrorAction Stop -Server $QueryServer

    if ($RemoveInheritedAccessRules) {
        Write-Verbose -Message "Restore-ADACL - Disabling inheritance for $($Object.DistinguishedName)"
        Disable-ADACLInheritance -ADObject $Object.DistinguishedName -RemoveInheritedAccessRules
    }
}

<# Code to use to find default permissions for given object type
$Object = Get-ADObject -Id 'OU=_root,DC=ad,DC=evotec,DC=xyz' -Properties 'NtSecurityDescriptor', 'DistinguishedName'
$Class = $($Object.ObjectClass)
$List = Get-ADObject -Filter "lDAPDisplayName -eq '$Class'" -SearchBase (Get-ADRootDSE).SchemaNamingContext -Properties defaultSecurityDescriptor, canonicalName, lDAPDisplayName
$List
#>