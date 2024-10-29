Import-Module .\ADEssentials.psd1 -Force

#$SchemaInformation = Get-WinADForestSchemaDetails #-Verbose
#$SchemaInformation

#$SchemaInformation['SchemaSummary']['File-Link-Tracking'] | Format-Table *
#$SchemaInformation['SchemaSummary'].Values | Format-Table *

Invoke-ADEssentials -Type Schema #-Verbose