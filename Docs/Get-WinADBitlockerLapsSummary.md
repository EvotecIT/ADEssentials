---
external help file: ADEssentials-help.xml
Module Name: ADEssentials
online version:
schema: 2.0.0
---

# Get-WinADBitlockerLapsSummary

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Default (Default)
```
Get-WinADBitlockerLapsSummary [-Forest <String>] [-IncludeDomains <String[]>] [-ExcludeDomains <String[]>]
 [-Filter <String>] [-SearchBase <String>] [-SearchScope <String>] [<CommonParameters>]
```

### BitlockerOnly
```
Get-WinADBitlockerLapsSummary [-Forest <String>] [-IncludeDomains <String[]>] [-ExcludeDomains <String[]>]
 [-Filter <String>] [-SearchBase <String>] [-SearchScope <String>] [-BitlockerOnly] [<CommonParameters>]
```

### LapsOnly
```
Get-WinADBitlockerLapsSummary [-Forest <String>] [-IncludeDomains <String[]>] [-ExcludeDomains <String[]>]
 [-Filter <String>] [-SearchBase <String>] [-SearchScope <String>] [-LapsOnly] [<CommonParameters>]
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

### -BitlockerOnly
{{ Fill BitlockerOnly Description }}

```yaml
Type: SwitchParameter
Parameter Sets: BitlockerOnly
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
{{ Fill Filter Description }}

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

### -Forest
{{ Fill Forest Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases: ForestName

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
Parameter Sets: (All)
Aliases: Domain, Domains

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LapsOnly
{{ Fill LapsOnly Description }}

```yaml
Type: SwitchParameter
Parameter Sets: LapsOnly
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchBase
{{ Fill SearchBase Description }}

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

### -SearchScope
{{ Fill SearchScope Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Base, OneLevel, SubTree, None

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
