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
            SiteLinksManual              = 'No sitelinks, single DC'
            SiteLinksAutomatic           = 'No sitelinks, single DC'
            SiteLinksUseNotify           = 'No sitelinks, single DC'
            SiteLinksNotUsingNotify      = 'No sitelinks, single DC'
            SiteLinksUseNotifyCount      = 0
            SiteLinksNotUsingNotifyCount = 0
            SiteLinksManualCount         = 0
            SiteLinksAutomaticCount      = 0
            SiteLinksTotalCount          = 0
            Comment                      = 'No sitelinks, single DC'
        }
    } else {
        [Array] $SiteLinks = Get-WinADSiteConnections -ExtendedForestInformation $ForestInformation
        if ($SiteLinks) {
            $Collection = @($SiteLinks).Where( { $_.Options -notcontains 'IsGenerated' -and $_.EnabledConnection -eq $true }, 'Split')
            $LinksManual = foreach ($Link in $Collection[0]) {
                "$($Link.ServerFrom) to $($Link.ServerTo)"
            }
            $LinksAutomatic = foreach ($Link in $Collection[1]) {
                "$($Link.ServerFrom) to $($Link.ServerTo)"
            }
            $CollectionNotifications = @($SiteLinks).Where( { $_.Options -notcontains 'UseNotify' -and $_.EnabledConnection -eq $true }, 'Split')
            $LinksNotUsingNotifications = foreach ($Link in $CollectionNotifications[0]) {
                "$($Link.ServerFrom) to $($Link.ServerTo)"
            }
            $LinksUsingNotifications = foreach ($Link in $CollectionNotifications[1]) {
                "$($Link.ServerFrom) to $($Link.ServerTo)"
            }
            [ordered] @{
                SiteLinksManual              = if ($Splitter -eq '') { $LinksManual } else { $LinksManual -join $Splitter }
                SiteLinksAutomatic           = if ($Splitter -eq '') { $LinksAutomatic } else { $LinksAutomatic -join $Splitter }
                SiteLinksUseNotify           = if ($Splitter -eq '') { $LinksUsingNotifications } else { $LinksUsingNotifications -join $Splitter }
                SiteLinksNotUsingNotify      = if ($Splitter -eq '') { $LinksNotUsingNotifications } else { $LinksNotUsingNotifications -join $Splitter }
                SiteLinksUseNotifyCount      = $CollectionNotifications[1].Count
                SiteLinksNotUsingNotifyCount = $CollectionNotifications[0].Count
                SiteLinksManualCount         = $Collection[0].Count
                SiteLinksAutomaticCount      = $Collection[1].Count
                SiteLinksTotalCount          = ($SiteLinks | Where-Object { $_.EnabledConnection -eq $true } ).Count
                Comment                      = 'OK'
            }
        } else {
            [ordered] @{
                SiteLinksManual              = 'No sitelinks'
                SiteLinksAutomatic           = 'No sitelinks'
                SiteLinksUseNotify           = 'No sitelinks'
                SiteLinksNotUsingNotify      = 'No sitelinks'
                SiteLinksUseNotifyCount      = 0
                SiteLinksNotUsingNotifyCount = 0
                SiteLinksManualCount         = 0
                SiteLinksAutomaticCount      = 0
                SiteLinksTotalCount          = 0
                Comment                      = 'Error'
            }
        }
    }
}