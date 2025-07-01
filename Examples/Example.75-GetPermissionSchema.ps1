Import-Module .\ADEssentials.psd1 -Force

#$SchemaInformation = Get-WinADForestSchemaDetails #-Verbose
#$SchemaInformation

#$SchemaInformation['SchemaSummary']['File-Link-Tracking'] | Format-Table *
#$SchemaInformation['SchemaSummary'].Values | Format-Table *

$Test = Invoke-ADEssentials -Type Schema -PassThru -Verbose
$Test