function New-ADSite {
    <#
    .SYNOPSIS
    Creates a new Active Directory site and configures its properties.

    .DESCRIPTION
    This cmdlet creates a new Active Directory site with the specified name and description. It also allows for the configuration of subnets, site links, and default sites. The cmdlet supports the use of credentials for authentication.

    .PARAMETER Site
    Specifies the name of the new Active Directory site to create.

    .PARAMETER Description
    Specifies the description of the new Active Directory site.

    .PARAMETER SitePartner
    Specifies the name of the partner site for the new site link.

    .PARAMETER DefaultSite
    Specifies the default site to which the new site will be added.

    .PARAMETER Subnets
    Specifies an array of subnet addresses to be associated with the new site.

    .PARAMETER Credential
    Specifies the credentials to use for authentication.

    .EXAMPLE
    New-ADSite -Site "NewSite" -Description "Description of the new site" -SitePartner "PartnerSite" -DefaultSite "DefaultSite" -Subnets @("10.0.0.0/8", "192.168.0.0/16") -Credential (Get-Credential)

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string]$Site,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][ValidateScript( { Get-ADReplicationSite -Identity $_ })][string]$SitePartner,
        [Parameter(Mandatory = $true)][array]$DefaultSite,
        [Parameter(Mandatory = $false)][array]$Subnets,
        [Parameter(Mandatory = $false)][System.Management.Automation.PSCredential]$Credential
    )
    begin {
        $InformationPreference = "Continue"
        [string]$sServer = (Get-ADDomainController -Writable -Discover).HostName
        $Site = $Site.ToUpper()
        $SitePartner = $SitePartner.ToUpper()
        $sSiteLink = "$($Site)-$($SitePartner)"
        $sSiteLinkDescr = "$($SitePartner)-$($Site)"
        $aSiteLinkSites = @($Site, $SitePartner)
    }

    process {

        #region Create site
        try {
            $hParams = @{
                Name        = $Site
                Description = $Description
                Server      = $sServer
            }
            if ($Credential) { $hParams.Credential = $Credential }

            New-ADReplicationSite @hParams
            Write-Verbose -Message "New-ADSite - Site $($Site) created"
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message "New-ADSite - Error: $ErrorMessage"
        }
        #endregion

        #region Create/reconnect subnets
        try {
            if ($Subnets) {
                foreach ($subnet in $Subnets) {
                    if (Get-ADReplicationSubnet -Filter "Name -eq '$subnet'") {

                        Write-Warning -Message "$($subnet) exists, will try reconnect to new site"

                        $hParams = @{
                            Identity    = $subnet
                            Site        = $Site
                            Description = $Description
                            Server      = $sServer
                        }
                        if ($Credential) { $hParams.Credential = $Credential }

                        Set-ADReplicationSubnet @hParams
                        Write-Verbose -Message "New-ADSite - Subnet $($subnet) reconnected"
                    } else {
                        $hParams = @{
                            Name        = $subnet
                            Site        = $Site
                            Description = $Description
                            Server      = $sServer
                        }
                        if ($Credential) { $hParams.Credential = $Credential }

                        New-ADReplicationSubnet @hParams
                        Write-Verbose -Message "New-ADSite - Subnet $($subnet) created"
                    }
                }
            }
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message "New-ADSite - Error: $ErrorMessage"
        }
        #endregion

        #region Create sitelink
        try {
            $hParams = @{
                Name                          = $sSiteLink
                Description                   = $sSiteLinkDescr
                ReplicationFrequencyInMinutes = 15
                Cost                          = 10
                SitesIncluded                 = $aSiteLinkSites
                Server                        = $sServer
            }
            if ($Credential) { $hParams.Credential = $Credential }

            New-ADReplicationSiteLink @hParams
            Write-Verbose -Message "New-ADSite - $($sSiteLink) site link created"
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message "New-ADSite - Error: $ErrorMessage"
        }
        #endregion

        #region Attach site to default sitelink
        try {
            $hParams = @{
                Identity      = $DefaultSite
                SitesIncluded = @{ Add = $Site }
                Server        = $sServer
            }
            if ($Credential) { $hParams.Credential = $Credential }

            Set-ADReplicationSiteLink @hParams
            Write-Verbose -Message "New-ADSite - $($Site) added to $($DefaultSite)"
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message "New-ADSite - Error: $ErrorMessage"
        }
        #endregion

    }
    end {}
}