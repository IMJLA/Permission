---
external help file: Permission-help.xml
Module Name: Permission
online version:
schema: 2.0.0
---

# Resolve-PermissionTarget

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Resolve-PermissionTarget [[-TargetPath] <DirectoryInfo[]>] [[-CimCache] <Hashtable>]
 [[-DebugOutputStream] <String>] [[-ThisHostname] <String>] [[-ThisFqdn] <String>] [[-WhoAmI] <String>]
 [[-LogBuffer] <Hashtable>] [[-Output] <Hashtable>] [[-ProgressParentId] <Int32>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
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

### -CimCache
{{ Fill CimCache Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DebugOutputStream
{{ Fill DebugOutputStream Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:
Accepted values: Silent, Quiet, Success, Debug, Verbose, Output, Host, Warning, Error, Information, 

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogBuffer
{{ Fill LogBuffer Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Output
{{ Fill Output Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressParentId
{{ Fill ProgressParentId Description }}

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetPath
{{ Fill TargetPath Description }}

```yaml
Type: System.IO.DirectoryInfo[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ThisFqdn
{{ Fill ThisFqdn Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThisHostname
{{ Fill ThisHostname Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhoAmI
{{ Fill WhoAmI Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.IO.DirectoryInfo[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
