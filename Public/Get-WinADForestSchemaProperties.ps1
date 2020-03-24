function Get-WinADForestSchemaProperties {
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [validateSet('Computers', 'Users')][string[]] $Schema = @('Computers', 'Users'),
        [System.Collections.IDictionary] $ExtendedForestInformation
    )

    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    if ($Forest) {
        $Type = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest
        $Context = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new($Type, $ForestInformation.Forest)
        $CurrentSchema = [directoryservices.activedirectory.activedirectoryschema]::GetSchema($Context)
    } else {
        $CurrentSchema = [directoryservices.activedirectory.activedirectoryschema]::GetCurrentSchema()
    }
    if ($Schema -contains 'Computers') {
        @(
            $CurrentSchema.FindClass("computer").mandatoryproperties | Select-Object -Property name, commonname, description, syntax
            $CurrentSchema.FindClass("computer").optionalproperties | Select-Object -Property name, commonname, description, syntax
        )
    }
    if ($Schema -contains 'Users') {
        @(
            $CurrentSchema.FindClass("user").mandatoryproperties | Select-Object -Property name, commonname, description, syntax
            $CurrentSchema.FindClass("user").optionalproperties | Select-Object -Property name, commonname, description, syntax
        )
    }
}