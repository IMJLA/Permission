---
external help file: Permission-help.xml
Module Name: Permission
online version:
schema: 2.0.0
---

# Format-Permission

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Format-Permission [[-Permission] <PSObject>] [[-IgnoreDomain] <String[]>] [[-GroupBy] <String>]
 [[-FileFormat] <String[]>] [[-OutputFormat] <String>] [[-ShortestPath] <String>]
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

### -FileFormat
{{ Fill FileFormat Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:
Accepted values: csv, html, js, json, prtgxml, xml

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupBy
{{ Fill GroupBy Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:
Accepted values: none, item, account

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreDomain
{{ Fill IgnoreDomain Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFormat
{{ Fill OutputFormat Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:
Accepted values: passthru, none, csv, html, js, json, prtgxml, xml

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Permission
{{ Fill Permission Description }}

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShortestPath
{{ Fill ShortestPath Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
