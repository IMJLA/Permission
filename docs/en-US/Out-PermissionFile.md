---
external help file: Permission-help.xml
Module Name: Permission
online version:
schema: 2.0.0
---

# Out-PermissionFile

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Out-PermissionFile [[-ExcludeAccount] <String[]>] [[-ExcludeClass] <String[]>] [[-IgnoreDomain] <Object>]
 [[-SourcePath] <String[]>] [-NoMembers] [[-OutputDir] <Object>] [[-StopWatch] <Object>] [[-Title] <Object>]
 [[-Permission] <Object>] [[-FormattedPermission] <Object>] [[-RecurseDepth] <Object>]
 [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>] [[-Detail] <Int32[]>] [[-FileFormat] <String[]>]
 [[-OutputFormat] <String>] [[-GroupBy] <String>] [[-SplitBy] <String[]>] [[-Analysis] <PSObject>]
 [[-SourceCount] <UInt64>] [[-ParentCount] <UInt64>] [[-ChildCount] <UInt64>] [[-ItemCount] <UInt64>]
 [[-FqdnCount] <UInt64>] [[-AclCount] <UInt64>] [[-AceCount] <UInt64>] [[-IdCount] <UInt64>]
 [[-PrincipalCount] <UInt64>] [-Cache] <PSReference> [-ProgressAction <ActionPreference>] [<CommonParameters>]
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

### -AceCount
{{ Fill AceCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 24
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AclCount
{{ Fill AclCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 23
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Analysis
{{ Fill Analysis Description }}

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Cache
{{ Fill Cache Description }}

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 27
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChildCount
{{ Fill ChildCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 20
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Detail
{{ Fill Detail Description }}

```yaml
Type: System.Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeAccount
{{ Fill ExcludeAccount Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeClass
{{ Fill ExcludeClass Description }}

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

### -FileFormat
{{ Fill FileFormat Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:
Accepted values: csv, html, js, json, prtgxml, xml

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FormattedPermission
{{ Fill FormattedPermission Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FqdnCount
{{ Fill FqdnCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 22
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
Accepted values: account, item, none, source

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdCount
{{ Fill IdCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 25
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IgnoreDomain
{{ Fill IgnoreDomain Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ItemCount
{{ Fill ItemCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 21
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogFileList
{{ Fill LogFileList Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoMembers
{{ Fill NoMembers Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputDir
{{ Fill OutputDir Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentCount
{{ Fill ParentCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 19
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Permission
{{ Fill Permission Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrincipalCount
{{ Fill PrincipalCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 26
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

### -RecurseDepth
{{ Fill RecurseDepth Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReportInstanceId
{{ Fill ReportInstanceId Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceCount
{{ Fill SourceCount Description }}

```yaml
Type: System.UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: 18
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourcePath
{{ Fill SourcePath Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SplitBy
{{ Fill SplitBy Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:
Accepted values: account, item, none, source

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StopWatch
{{ Fill StopWatch Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
{{ Fill Title Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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
