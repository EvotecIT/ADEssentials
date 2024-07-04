function Get-WinADForestSchemaProperties {
    <#
    .SYNOPSIS
    Retrieves schema properties for a specified Active Directory forest.

    .DESCRIPTION
    Retrieves detailed information about schema properties within the specified Active Directory forest.

    .PARAMETER Forest
    Specifies the target forest to retrieve schema properties from.

    .PARAMETER Schema
    Specifies the type of schema properties to retrieve. Valid values are 'Computers' and 'Users'.

    .PARAMETER ExtendedForestInformation
    Specifies additional information about the forest.

    .EXAMPLE
    Get-WinADForestSchemaProperties -Forest "example.com" -Schema @('Computers', 'Users')

    .NOTES
    This cmdlet requires the Active Directory PowerShell module to be installed and imported. It also requires appropriate permissions to query the Active Directory forest.
    #>
    [cmdletBinding()]
    param(
        [alias('ForestName')][string] $Forest,
        [validateSet('Computers', 'Users')][string[]] $Schema = @('Computers', 'Users'),
        [System.Collections.IDictionary] $ExtendedForestInformation
    )
    <#
    Name                   : dLMemRejectPermsBL
    CommonName             : ms-Exch-DL-Mem-Reject-Perms-BL
    Oid                    : 1.2.840.113556.1.2.293
    Syntax                 : DN
    Description            :
    IsSingleValued         : False
    IsIndexed              : False
    IsIndexedOverContainer : False
    IsInAnr                : False
    IsOnTombstonedObject   : False
    IsTupleIndexed         : False
    IsInGlobalCatalog      : True
    RangeLower             :
    RangeUpper             :
    IsDefunct              : False
    Link                   : dLMemRejectPerms
    LinkId                 : 117
    SchemaGuid             : a8df73c3-c5ea-11d1-bbcb-0080c76670c0
    #>
    $ForestInformation = Get-WinADForestDetails -Forest $Forest -ExtendedForestInformation $ExtendedForestInformation
    if ($Forest) {
        $Type = [System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest
        $Context = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new($Type, $ForestInformation.Forest)
        $CurrentSchema = [directoryservices.activedirectory.activedirectoryschema]::GetSchema($Context)
    } else {
        $CurrentSchema = [directoryservices.activedirectory.activedirectoryschema]::GetCurrentSchema()
    }
    if ($Schema -contains 'Computers') {
        $CurrentSchema.FindClass("computer").mandatoryproperties | Select-Object -Property name, commonname, description, syntax , SchemaGuid
        $CurrentSchema.FindClass("computer").optionalproperties | Select-Object -Property name, commonname, description, syntax, SchemaGuid

    }
    if ($Schema -contains 'Users') {
        $CurrentSchema.FindClass("user").mandatoryproperties | Select-Object -Property name, commonname, description, syntax, SchemaGuid
        $CurrentSchema.FindClass("user").optionalproperties | Select-Object -Property name, commonname, description, syntax, SchemaGuid
    }
}