function Get-WinADForestSchemaProperties {
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