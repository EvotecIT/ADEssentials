---
external help file: ADEssentials-help.xml
Module Name: ADEssentials
online version:
schema: 2.0.0
---

# Show-WinADGroupMember

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Default (Default)
```
Show-WinADGroupMember [[-Identity] <Array>] [[-Conditions] <ScriptBlock>] [-FilePath <String>]
 [-HideAppliesTo <String>] [-HideComputers] [-HideUsers] [-HideOther] [-Online] [-HideHTML]
 [-DisableBuiltinConditions] [-AdditionalStatistics] [-Summary] [<CommonParameters>]
```

### SummaryOnly
```
Show-WinADGroupMember [[-Identity] <Array>] [[-Conditions] <ScriptBlock>] [-FilePath <String>]
 [-HideAppliesTo <String>] [-HideComputers] [-HideUsers] [-HideOther] [-Online] [-HideHTML]
 [-DisableBuiltinConditions] [-AdditionalStatistics] [-SummaryOnly] [<CommonParameters>]
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

### -Identity
Group Name to search for

```yaml
Type: Array
Parameter Sets: (All)
Aliases: GroupName, Group

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Conditions
Provides ability to control look and feel of tables across HTML

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath
{{ Fill FilePath Description }}

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

### -HideAppliesTo
Allows to define to which diagram HideComputers,HideUsers,HideOther applies to

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Both
Accept pipeline input: False
Accept wildcard characters: False
```

### -HideComputers
Hide computers from diagrams - useful for performance reasons

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HideUsers
Hide users from diagrams - useful for performance reasons

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HideOther
Hide other objects from diagrams - useful for performance reasons

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Online
Forces use of online CDN for JavaScript/CSS which makes the file smaller. Default - use offline.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -HideHTML
Prevents HTML from opening up after command is done. Useful for automation

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisableBuiltinConditions
Disables table coloring allowing user to define it's own conditions

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalStatistics
Adds additional data to Self object. It includes count for NestingMax, NestingGroup, NestingGroupSecurity, NestingGroupDistribution. It allows for easy filtering where we expect security groups only when there are nested distribution groups.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Summary
{{ Fill Summary Description }}

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

### -SummaryOnly
{{ Fill SummaryOnly Description }}

```yaml
Type: SwitchParameter
Parameter Sets: SummaryOnly
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
