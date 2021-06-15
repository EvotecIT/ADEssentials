function New-CISADSite {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][string]$Site,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][ValidateScript( { Get-ADReplicationSite -Identity $_ })][string]$SitePartner,
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
            Write-Output -InputObject "[New] : $($Site) created"
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message $ErrorMessage
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
                        Write-Output -InputObject "[Set] : $($subnet) reconnected"
                    } else {
                        $hParams = @{
                            Name        = $subnet
                            Site        = $Site
                            Description = $Description
                            Server      = $sServer
                        }
                        if ($Credential) { $hParams.Credential = $Credential }

                        New-ADReplicationSubnet @hParams
                        Write-Output -InputObject "[New] : $($subnet) created"
                    }
                }
            }
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message $ErrorMessage
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
            Write-Output -InputObject "[New] : $($sSiteLink) site link created"
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message $ErrorMessage
        }
        #endregion

        #region Attach site to default sitelink
        try {
            $hParams = @{
                Identity      = "SWALL"
                SitesIncluded = @{ Add = $Site }
                Server        = $sServer
            }
            if ($Credential) { $hParams.Credential = $Credential }

            Set-ADReplicationSiteLink @hParams
            Write-Output -InputObject "[Set] : $($Site) added to SWALL"
        } catch {
            $ErrorMessage = $PSItem.Exception.Message
            Write-Warning -Message $ErrorMessage
        }
        #endregion

    }
    end {}
}

# SIG # Begin signature bloc
