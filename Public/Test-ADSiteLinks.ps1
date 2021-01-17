function Test-ADSiteLinks {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [string] $Splitter,
        [System.Collections.IDictionary] $ExtendedForestInformation
    )

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    if (($ForestInformation.ForestDomainControllers).Count -eq 1) {
        [ordered] @{
            SiteLinksManual                     = 'No sitelinks, single DC'
            SiteLinksAutomatic                  = 'No sitelinks, single DC'

            SiteLinksCrossSiteUseNotify         = 'No sitelinks, single DC'
            SiteLinksCrossSiteNotUseNotify      = 'No sitelinks, single DC'
            SiteLinksSameSiteUseNotify          = 'No sitelinks, single DC'
            SiteLinksSameSiteNotUseNotify       = 'No sitelinks, single DC'

            SiteLinksDisabled                   = 'No sitelinks, single DC'
            SiteLinksEnabled                    = 'No sitelinks, single DC'

            SiteLinksCrossSiteUseNotifyCount    = 0
            SiteLinksCrossSiteNotUseNotifyCount = 0
            SiteLinksSameSiteUseNotifyCount     = 0
            SiteLinksSameSiteNotUseNotifyCount  = 0

            SiteLinksManualCount                = 0
            SiteLinksAutomaticCount             = 0
            SiteLinksDisabledCount              = 0
            SiteLinksEnabledCount               = 0
            SiteLinksTotalCount                 = 0
            SiteLinksTotalActiveCount           = 0
            Comment                             = 'No sitelinks, single DC'
        }
    } else {
        [Array] $SiteLinks = Get-WinADSiteConnections -ExtendedForestInformation $ForestInformation
        if ($SiteLinks) {
            $Collection = @($SiteLinks).Where( { $_.Options -notcontains 'IsGenerated' -and $_.EnabledConnection -eq $true }, 'Split')
            [Array] $LinksManual = foreach ($Link in $Collection[0]) {
                "$($Link.ServerFrom) to $($Link.ServerTo)"
            }
            [Array] $LinksAutomatic = foreach ($Link in $Collection[1]) {
                "$($Link.ServerFrom) to $($Link.ServerTo)"
            }
            $LinksUsingNotificationsUnnessecary = [System.Collections.Generic.List[string]]::new()
            $LinksUsingNotifications = [System.Collections.Generic.List[string]]::new()
            $LinksNotUsingNotifications = [System.Collections.Generic.List[string]]::new()
            $LinksUsingNotificationsWhichIsOk = [System.Collections.Generic.List[string]]::new()
            $DisabledLinks = [System.Collections.Generic.List[string]]::new()
            $EnabledLinks = [System.Collections.Generic.List[string]]::new()
            foreach ($Link in $SiteLinks) {
                if ($Link.EnabledConnection -eq $true) {
                    $EnabledLinks.Add("$($Link.ServerFrom) to $($Link.ServerTo)")
                } else {
                    $DisabledLinks.Add("$($Link.ServerFrom) to $($Link.ServerTo)")
                }
                if ($Link.SiteFrom -eq $Link.SiteTo) {
                    if ($Link.Options -contains 'UseNotify') {
                        # Bad
                        $LinksUsingNotificationsUnnessecary.Add("$($Link.ServerFrom) to $($Link.ServerTo)")
                    } else {
                        # Good
                        $LinksUsingNotificationsWhichIsOk.Add("$($Link.ServerFrom) to $($Link.ServerTo)")
                    }
                } else {
                    if ($Link.Options -contains 'UseNotify') {
                        # Good
                        $LinksUsingNotifications.Add("$($Link.ServerFrom) to $($Link.ServerTo)")
                    } else {
                        # Bad
                        $LinksNotUsingNotifications.Add("$($Link.ServerFrom) to $($Link.ServerTo)")
                    }
                }
            }
            [ordered] @{
                SiteLinksManual                     = if ($Splitter -eq '') { $LinksManual } else { $LinksManual -join $Splitter }
                SiteLinksAutomatic                  = if ($Splitter -eq '') { $LinksAutomatic } else { $LinksAutomatic -join $Splitter }

                SiteLinksCrossSiteUseNotify         = if ($Splitter -eq '') { $LinksUsingNotifications } else { $LinksUsingNotifications -join $Splitter }
                SiteLinksCrossSiteNotUseNotify      = if ($Splitter -eq '') { $LinksNotUsingNotifications } else { $LinksNotUsingNotifications -join $Splitter }
                SiteLinksSameSiteUseNotify          = if ($Splitter -eq '') { $LinksUsingNotificationsUnnessecary } else { $LinksUsingNotificationsUnnessecary -join $Splitter }
                SiteLinksSameSiteNotUseNotify       = if ($Splitter -eq '') { $LinksUsingNotificationsWhichIsOk } else { $LinksUsingNotificationsWhichIsOk -join $Splitter }

                SiteLinksDisabled                   = if ($Splitter -eq '') { $DisabledLinks } else { $DisabledLinks -join $Splitter }
                SiteLinksEnabled                    = if ($Splitter -eq '') { $EnabledLinks } else { $EnabledLinks -join $Splitter }

                SiteLinksCrossSiteUseNotifyCount    = $LinksUsingNotifications.Count
                SiteLinksCrossSiteNotUseNotifyCount = $LinksNotUsingNotifications.Count
                SiteLinksSameSiteUseNotifyCount     = $LinksUsingNotificationsUnnessecary.Count
                SiteLinksSameSiteNotUseNotifyCount  = $LinksUsingNotificationsWhichIsOk.Count

                SiteLinksManualCount                = $Collection[0].Count
                SiteLinksAutomaticCount             = $Collection[1].Count
                SiteLinksDisabledCount              = $DisabledLinks.Count
                SiteLinksEnabledCount               = $EnabledLinks.Count
                SiteLinksTotalCount                 = $SiteLinks.Count
                SiteLinksTotalActiveCount           = ($SiteLinks | Where-Object { $_.EnabledConnection -eq $true } ).Count
                Comment                             = 'OK'
            }
        } else {
            [ordered] @{
                SiteLinksManual                     = 'No sitelinks'
                SiteLinksAutomatic                  = 'No sitelinks'

                SiteLinksCrossSiteUseNotify         = 'No sitelinks'
                SiteLinksCrossSiteNotUseNotify      = 'No sitelinks'
                SiteLinksSameSiteUseNotify          = 'No sitelinks'
                SiteLinksSameSiteNotUseNotify       = 'No sitelinks'

                SiteLinksDisabled                   = 'No sitelinks'
                SiteLinksEnabled                    = 'No sitelinks'

                SiteLinksCrossSiteUseNotifyCount    = 0
                SiteLinksCrossSiteNotUseNotifyCount = 0
                SiteLinksSameSiteUseNotifyCount     = 0
                SiteLinksSameSiteNotUseNotifyCount  = 0

                SiteLinksManualCount                = 0
                SiteLinksAutomaticCount             = 0
                SiteLinksDisabledCount              = 0
                SiteLinksEnabledCount               = 0
                SiteLinksTotalCount                 = 0
                SiteLinksTotalActiveCount           = 0
                Comment                             = 'Error'
            }
        }
    }
}