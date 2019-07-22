# Get currrent settings so that you can see what those are and change it back if needed
Get-WinADSiteLinks
Get-WinADSiteConnections -Verbose | Format-Table -Autosize
# Set command - BE CAREFUL, I would run read only commands first
Set-WinADReplication -ReplicationInterval 15 -Instant # you can use both or only one parameter.
Set-WinADReplicationConnections -Verbose
# Confirming the settings have applied correctly
Get-WinADSiteLinks -Verbose | Format-Table -Autosize
Get-WinADSiteConnections -Verbose | Format-Table -Autosize
# Syncing changes so that those spread around quickly
Sync-DomainController
# Verify sync
Get-WinADForestReplicationPartnerMetaData