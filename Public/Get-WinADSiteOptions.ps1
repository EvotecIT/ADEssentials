Function Get-WinADSiteOptions {
    [CmdletBinding()]
    Param(

    )

    [Flags()]
    enum nTDSSiteSettingsFlags {
        NTDSSETTINGS_OPT_IS_AUTO_TOPOLOGY_DISABLED = 0x1
        NTDSSETTINGS_OPT_IS_TOPL_CLEANUP_DISABLED = 0x2
        NTDSSETTINGS_OPT_IS_TOPL_MIN_HOPS_DISABLED = 0x4
        NTDSSETTINGS_OPT_IS_TOPL_DETECT_STALE_DISABLED = 0x8
        NTDSSETTINGS_OPT_IS_INTER_SITE_AUTO_TOPOLOGY_DISABLED = 0x10
        NTDSSETTINGS_OPT_IS_GROUP_CACHING_ENABLED = 0x20
        NTDSSETTINGS_OPT_FORCE_KCC_WHISTLER_BEHAVIOR = 0x40
        NTDSSETTINGS_OPT_FORCE_KCC_W2K_ELECTION = 0x80
        NTDSSETTINGS_OPT_IS_RAND_BH_SELECTION_DISABLED = 0x100
        NTDSSETTINGS_OPT_IS_SCHEDULE_HASHING_ENABLED = 0x200
        NTDSSETTINGS_OPT_IS_REDUNDANT_SERVER_TOPOLOGY_ENABLED = 0x400
        NTDSSETTINGS_OPT_W2K3_IGNORE_SCHEDULES = 0x800
        NTDSSETTINGS_OPT_W2K3_BRIDGES_REQUIRED = 0x1000
    }

    $RootDSE = Get-ADRootDSE
    $Sites = Get-ADObject -Filter 'objectClass -eq "site"' -SearchBase $RootDSE.ConfigurationNamingContext
    foreach ($Site In $Sites) {
        $SiteSettings = Get-ADObject "CN=NTDS Site Settings,$($Site.DistinguishedName)" -Properties Options
        If (-not $SiteSettings.PSObject.Properties.Match('Options').Count -OR $SiteSettings.Options -EQ 0) {

            [PSCustomObject]@{
                SiteName          = $Site.Name
                DistinguishedName = $Site.DistinguishedName
                SiteOptions       = '(none)'
            }
        } Else {
            [PSCustomObject]@{
                SiteName          = $Site.Name;
                DistinguishedName = $Site.DistinguishedName;
                Options           = $SiteSettings.Options
                SiteOptions       = [nTDSSiteSettingsFlags] $SiteSettings.Options
            }
        }
    }
}