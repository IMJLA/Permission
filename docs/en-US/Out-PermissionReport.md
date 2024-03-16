---
external help file: Permission-help.xml
Module Name: Permission
online version:
schema: 2.0.0
---

# Out-PermissionReport

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Out-PermissionReport [[-ExcludeAccount] <String[]>] [[-ExcludeClass] <String[]>] [[-IgnoreDomain] <Object>]
 [[-TargetPath] <String[]>] [-NoMembers] [[-OutputDir] <Object>] [[-WhoAmI] <Object>] [[-ThisFqdn] <Object>]
 [[-StopWatch] <Object>] [[-Title] <Object>] [[-Permission] <Object>] [[-FormattedPermission] <Object>]
 [[-LogParams] <Object>] [[-RecurseDepth] <Object>] [[-LogFileList] <Object>] [[-ReportInstanceId] <Object>]
 [[-ACEsByGUID] <Hashtable>] [[-ACLsByPath] <Hashtable>] [[-PrincipalsByResolvedID] <Object>]
 [[-BestPracticeIssue] <Object>] [[-Parent] <String[]>] [[-Detail] <Int32[]>] [[-Culture] <CultureInfo>]
 [[-FileFormat] <String[]>] [[-OutputFormat] <String>] [[-GroupBy] <String>]
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

### -ACEsByGUID
{{ Fill ACEsByGUID Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ACLsByPath
{{ Fill ACLsByPath Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BestPracticeIssue
{{ Fill BestPracticeIssue Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 18
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Culture
{{ Fill Culture Description }}

```yaml
Type: System.Globalization.CultureInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: 21
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
Position: 20
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
Position: 22
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
Position: 10
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
Position: 24
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

### -LogFileList
{{ Fill LogFileList Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogParams
{{ Fill LogParams Description }}

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
Position: 23
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Parent
{{ Fill Parent Description }}

```yaml
Type: System.String[]
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
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrincipalsByResolvedID
{{ Fill PrincipalsByResolvedID Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
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
Position: 12
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
Position: 14
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
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetPath
{{ Fill TargetPath Description }}

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

### -ThisFqdn
{{ Fill ThisFqdn Description }}

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

### -Title
{{ Fill Title Description }}

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

### -WhoAmI
{{ Fill WhoAmI Description }}

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

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
