---
external help file: Permission-help.xml
Module Name: Permission
online version:
schema: 2.0.0
---

# Initialize-Cache

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Initialize-Cache [[-Fqdn] <String[]>] [[-DebugOutputStream] <String>] [[-ThreadCount] <Int32>]
 [[-CimCache] <Hashtable>] [[-DirectoryEntryCache] <Hashtable>] [[-DomainsByNetbios] <Hashtable>]
 [[-DomainsBySid] <Hashtable>] [[-DomainsByFqdn] <Hashtable>] [[-ThisHostName] <String>] [[-ThisFqdn] <String>]
 [[-WhoAmI] <String>] [[-LogMsgCache] <Hashtable>] [[-ProgressParentId] <Int32>]
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
Position: 3
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
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntryCache
{{ Fill DirectoryEntryCache Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByFqdn
{{ Fill DomainsByFqdn Description }}

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

### -DomainsByNetbios
{{ Fill DomainsByNetbios Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsBySid
{{ Fill DomainsBySid Description }}

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

### -Fqdn
{{ Fill Fqdn Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -LogMsgCache
{{ Fill LogMsgCache Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
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
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThisFqdn
{{ Fill ThisFqdn Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThisHostName
{{ Fill ThisHostName Description }}

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThreadCount
{{ Fill ThreadCount Description }}

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
