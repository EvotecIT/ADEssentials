function New-ADSite {
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
                    if (Get-ADReplicationSubnet -Filter { Name -eq $subnet }) {

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

# SIG # Begin signature bloc
