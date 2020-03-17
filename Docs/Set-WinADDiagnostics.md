---
external help file: ADEssentials-help.xml
Module Name: ADEssentials
online version:
schema: 2.0.0
---

# Set-WinADDiagnostics

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Default (Default)
```
Set-WinADDiagnostics [-Forest <String>] [-ExcludeDomains <String[]>] [-ExcludeDomainControllers <String[]>]
 [-IncludeDomains <String[]>] [-IncludeDomainControllers <String[]>] [-SkipRODC] [-Diagnostics <String[]>]
 [-Level <String>] [-ExtendedForestInformation <IDictionary>] [<CommonParameters>]
```

### Computer
```
Set-WinADDiagnostics [-ComputerName <String[]>] [-Diagnostics <String[]>] [-Level <String>]
 [-ExtendedForestInformation <IDictionary>] [<CommonParameters>]
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

### -ComputerName
{{ Fill ComputerName Description }}

```yaml
Type: String[]
Parameter Sets: Computer
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Diagnostics
{{ Fill Diagnostics Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:
Accepted values: Knowledge Consistency Checker (KCC), Security Events, ExDS Interface Events, MAPI Interface Events, Replication Events, Garbage Collection, Internal Configuration, Directory Access, Internal Processing, Performance Counters, Initialization / Termination, Service Control, Name Resolution, Backup, Field Engineering, LDAP Interface Events, Setup, Global Catalog, Inter-site Messaging, Group Caching, Linked-Value Replication, DS RPC Client, DS RPC Server, DS Schema, Transformation Engine, Claims-Based Access Control, Netlogon

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeDomainControllers
{{ Fill ExcludeDomainControllers Description }}

```yaml
Type: String[]
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeDomains
{{ Fill ExcludeDomains Description }}

```yaml
Type: String[]
Parameter Sets: Default
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtendedForestInformation
{{ Fill ExtendedForestInformation Description }}

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Forest
{{ Fill Forest Description }}

```yaml
Type: String
Parameter Sets: Default
Aliases: ForestName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeDomainControllers
{{ Fill IncludeDomainControllers Description }}

```yaml
Type: String[]
Parameter Sets: Default
Aliases: DomainControllers

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeDomains
{{ Fill IncludeDomains Description }}

```yaml
Type: String[]
Parameter Sets: Default
Aliases: Domain, Domains

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Level
{{ Fill Level Description }}

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

### -SkipRODC
{{ Fill SkipRODC Description }}

```yaml
Type: SwitchParameter
Parameter Sets: Default
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
