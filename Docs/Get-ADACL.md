---
external help file: ADEssentials-help.xml
Module Name: ADEssentials
online version:
schema: 2.0.0
---

# Get-ADACL

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Get-ADACL [-ADObject] <Array> [-ForestName <String>] [-Extended] [-ResolveTypes] [-Inherited] [-NotInherited]
 [-Bundle] [-AccessControlType <AccessControlType>] [-IncludeObjectTypeName <String[]>]
 [-IncludeInheritedObjectTypeName <String[]>] [-ExcludeObjectTypeName <String[]>]
 [-ExcludeInheritedObjectTypeName <String[]>] [-IncludeActiveDirectoryRights <ActiveDirectoryRights[]>]
 [-ExcludeActiveDirectoryRights <ActiveDirectoryRights[]>]
 [-IncludeActiveDirectorySecurityInheritance <ActiveDirectorySecurityInheritance[]>]
 [-ExcludeActiveDirectorySecurityInheritance <ActiveDirectorySecurityInheritance[]>] [-ADRightsAsArray]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -ADObject
{{ Fill ADObject Description }}

```yaml
Type: Array
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ADRightsAsArray
{{ Fill ADRightsAsArray Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessControlType
{{ Fill AccessControlType Description }}

```yaml
Type: AccessControlType
Parameter Sets: (All)
Aliases:
Accepted values: Allow, Deny

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Bundle
{{ Fill Bundle Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeActiveDirectoryRights
{{ Fill ExcludeActiveDirectoryRights Description }}

```yaml
Type: ActiveDirectoryRights[]
Parameter Sets: (All)
Aliases:
Accepted values: CreateChild, DeleteChild, ListChildren, Self, ReadProperty, WriteProperty, DeleteTree, ListObject, ExtendedRight, Delete, ReadControl, GenericExecute, GenericWrite, GenericRead, WriteDacl, WriteOwner, GenericAll, Synchronize, AccessSystemSecurity

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeActiveDirectorySecurityInheritance
{{ Fill ExcludeActiveDirectorySecurityInheritance Description }}

```yaml
Type: ActiveDirectorySecurityInheritance[]
Parameter Sets: (All)
Aliases:
Accepted values: None, All, Descendents, SelfAndChildren, Children

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeInheritedObjectTypeName
{{ Fill ExcludeInheritedObjectTypeName Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeObjectTypeName
{{ Fill ExcludeObjectTypeName Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Extended
{{ Fill Extended Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForestName
{{ Fill ForestName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeActiveDirectoryRights
{{ Fill IncludeActiveDirectoryRights Description }}

```yaml
Type: ActiveDirectoryRights[]
Parameter Sets: (All)
Aliases:
Accepted values: CreateChild, DeleteChild, ListChildren, Self, ReadProperty, WriteProperty, DeleteTree, ListObject, ExtendedRight, Delete, ReadControl, GenericExecute, GenericWrite, GenericRead, WriteDacl, WriteOwner, GenericAll, Synchronize, AccessSystemSecurity

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeActiveDirectorySecurityInheritance
{{ Fill IncludeActiveDirectorySecurityInheritance Description }}

```yaml
Type: ActiveDirectorySecurityInheritance[]
Parameter Sets: (All)
Aliases:
Accepted values: None, All, Descendents, SelfAndChildren, Children

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeInheritedObjectTypeName
{{ Fill IncludeInheritedObjectTypeName Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeObjectTypeName
{{ Fill IncludeObjectTypeName Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Inherited
{{ Fill Inherited Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NotInherited
{{ Fill NotInherited Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResolveTypes
{{ Fill ResolveTypes Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Array

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
