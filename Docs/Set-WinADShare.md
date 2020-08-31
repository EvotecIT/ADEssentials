---
external help file: ADEssentials-help.xml
Module Name: ADEssentials
online version:
schema: 2.0.0
---

# Set-WinADShare

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Type (Default)
```
Set-WinADShare [-Path <String>] [-ShareType <String[]>] [-Owner] -Type <String[]> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Principal
```
Set-WinADShare [-Path <String>] [-ShareType <String[]>] [-Owner] -Principal <String> [-WhatIf] [-Confirm]
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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Owner
{{ Fill Owner Description }}

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

### -Path
{{ Fill Path Description }}

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

### -Principal
{{ Fill Principal Description }}

```yaml
Type: String
Parameter Sets: Principal
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShareType
{{ Fill ShareType Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:
Accepted values: NetLogon

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
{{ Fill Type Description }}

```yaml
Type: String[]
Parameter Sets: Type
Aliases:
Accepted values: Default

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

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
