
function ConvertTo-ClassExclusionDiv {

    param (

        <#
        Accounts whose objectClass property is in this list are excluded from the HTML report

        Note on the 'group' class:
        By default, a group with members is replaced in the report by its members unless the -NoGroupMembers switch is used.
        Any remaining groups are empty and not useful to see in the middle of a list of users/job titles/departments/etc).
        So the 'group' class is excluded here by default.
        #>
        [string[]]$ExcludeClass

    )

    if ($ExcludeClass) {

        $ListGroup = $ExcludeClass |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts whose objectClass property is in this list were excluded from the report.$ListGroup"

    } else {

        $Content = 'No accounts were excluded based on objectClass.'

    }

    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Class' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Class' -Content $Content

}
function ConvertTo-IgnoredDomainDiv {

    param (

        <#
        Domain(s) to ignore (they will be removed from the username)

        Can be used:
        to ensure accounts only appear once on the report when they have matching SamAccountNames in multiple domains.
        when the domain is often the same and doesn't need to be displayed
        #>
        [string[]]$IgnoreDomain

    )

    if ($IgnoreDomain) {

        $ListGroup = $IgnoreDomain |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts from these domains are listed in the report without their domain.$ListGroup"

    } else {

        $Content = 'No domains were ignored.  All accounts have their domain listed.'

    }

    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Domains Ignored by Name' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Domains Ignored by Name' -Content $Content

}
function ConvertTo-MemberExclusionDiv {

    param (

        <#
        Do not get group members (only report the groups themselves)

        Note: By default, the -ExcludeClass parameter will exclude groups from the report.
        If using -NoGroupMembers, you most likely want to modify the value of -ExcludeClass.
        Remove the 'group' class from ExcludeClass in order to see groups on the report.
        #>
        [switch]$NoMembers

    )

    if ($NoMembers) {

        $Content = 'Group members were excluded from the report.<br />Only accounts directly from the ACLs are included in the report.'

    } else {

        $Content = 'No accounts were excluded based on group membership.<br />Members of groups from the ACLs are included in the report.'

    }

    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Group Members' -Content '$Content'"
    return New-BootstrapDivWithHeading -HeadingText 'Group Members' -Content $Content

}
function ConvertTo-NameExclusionDiv {

    param (

        # Regular expressions matching names of security principals to exclude from the HTML report
        [string[]]$ExcludeAccount

    )

    if ($ExcludeAccount) {

        $ListGroup = $ExcludeAccount |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts whose names match these regular expressions were excluded from the report.$ListGroup"

    } else {

        $Content = 'No accounts were excluded based on name.'

    }

    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Name' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Name' -Content $Content

}
function ConvertTo-PermissionGroup {

    param (

        # Permission object from Expand-Permission
        [PSCustomObject]$Permission,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$Format,

        <#
        Level of detail to export to file
            0   Item paths                                                                                  $TargetPath
            1   Resolved item paths (server names resolved, DFS targets resolved)                           $ACLsByPath.Keys after Resolve-PermissionTarget but before Expand-PermissionTarget
            2   Expanded resolved item paths (parent paths expanded into children)                          $ACLsByPath.Keys after Expand-PermissionTarget
            3   Access control entries                                                                      $ACLsByPath.Values after Get-FolderAcl
            4   Resolved access control entries                                                             $ACEsByGUID.Values
                                                                                                            $PrincipalsByResolvedID.Values
            5   Expanded resolved access control entries (expanded with info from ADSI security principals) $Permissions
            6   XML custom sensor output for Paessler PRTG Network Monitor
        #>
        [int[]]$Detail = @(0..6)

    )

    $OutputObject = @{}

    switch ($Format) {

        'csv' {
            $OutputObject['Data'] = $Permission | ConvertTo-Csv
        }

        'html' {

            Write-LogMsg @LogParams -Text "`$Permission | ConvertTo-Html -Fragment | New-BootstrapTable"
            $Html = $Permission | ConvertTo-Html -Fragment
            $OutputObject['Data'] = $Html
            $OutputObject['Table'] = $Html | New-BootstrapTable

        }

        'json' {

            # Wrap input in a array because output must be a JSON array for jquery to work properly.
            $OutputObject['Data'] = ConvertTo-Json -Compress -InputObject @($Permission)

            Write-LogMsg @LogParams -Text "Get-FolderColumnJson -InputObject `$ObjectsForTable"
            $OutputObject['Columns'] = Get-FolderColumnJson -InputObject $Permission

            #TODO: Change table id to "Groupings" instead of Folders to allow for Grouping by Account
            Write-LogMsg @LogParams -Text "ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject `$Permission -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'"
            $OutputObject['Table'] = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $Permission -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance' -PageSize 25

        }

        'xml' {
            $OutputObject['Data'] = ($Permission | ConvertTo-Xml).InnerXml
        }

        default {}

    }

    return [PSCustomObject]$OutputObject

}
function ConvertTo-PermissionList {

    param (

        # Permission object from Expand-Permission
        [hashtable]$Permission,

        [PSCustomObject[]]$PermissionGrouping,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$Format,

        [string]$ShortestPath,

        [string]$GroupBy

    )

    # TODO: Replace .Item.Path with GroupingProperty variable somehow
    #$GroupingProperty = @($PermissionGrouping[0] | Get-Member -Type NoteProperty)[0].Name

    switch ($Format) {

        'csv' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $OutputObject['Data'] = $Permission.Values | Sort-Object -Property Item, Account | ConvertTo-Csv
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {
                    $OutputObject = @{}
                    $OutputObject['Data'] = $Permission[$Group.Item.Path] | ConvertTo-Csv
                    [PSCustomObject]$OutputObject
                }

            }

        }

        'html' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $Heading = New-HtmlHeading 'Permissions' -Level 5
                $Html = $Permission.Values | Sort-Object -Property Item, Account | ConvertTo-Html -Fragment
                $OutputObject['Data'] = $Html
                $Table = $Html | New-BootstrapTable
                $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $Table)
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {

                    $OutputObject = @{}
                    $GroupID = $Group.Item.Path
                    $Heading = New-HtmlHeading "Accounts with access to $GroupID" -Level 5
                    $SubHeading = Get-FolderPermissionTableHeader -Group $Group -GroupID $GroupID -ShortestFolderPath $ShortestPath
                    $Perm = $Permission[$GroupID]
                    $Html = $Perm | ConvertTo-Html -Fragment
                    $OutputObject['Data'] = $Html
                    $Table = $Html | New-BootstrapTable
                    $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $SubHeading + $Table)
                    [PSCustomObject]$OutputObject

                }

            }

        }

        'json' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $Heading = New-HtmlHeading 'Permissions' -Level 5

                $StartingPermissions = $Permission.Values | Sort-Object -Property Item, Account

                # Remove spaces from property titles
                $ObjectsForJsonData = ForEach ($Obj in $StartingPermissions) {
                    [PSCustomObject]@{
                        Item              = $Obj.Item
                        Account           = $Obj.Account
                        Access            = $Obj.Access
                        DuetoMembershipIn = $Obj.'Due to Membership In'
                        SourceofAccess    = $Obj.'Source of Access'
                        Name              = $Obj.Name
                        Department        = $Obj.Department
                        Title             = $Obj.Title
                    }

                }

                $OutputObject['Data'] = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                $OutputObject['Columns'] = Get-FolderColumnJson -InputObject $StartingPermissions -PropNames Item, Account, Access, 'Due to Membership In', 'Source of Access', Name, Department, Title
                $TableId = 'Perms'
                $OutputObject['Table'] = $TableId
                $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $StartingPermissions -DataFilterControl -AllColumnsSearchable -PageSize 25
                $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $Table)
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {

                    $OutputObject = @{}
                    $GroupID = $Group.Item.Path
                    $Heading = New-HtmlHeading "Accounts with access to $GroupID" -Level 5
                    $SubHeading = Get-FolderPermissionTableHeader -Group $Group -GroupID $GroupID -ShortestFolderPath $ShortestPath
                    $Perm = $Permission[$GroupID]

                    # Remove spaces from property titles
                    $ObjectsForJsonData = ForEach ($Obj in $Perm) {
                        [PSCustomObject]@{
                            Account           = $Obj.Account
                            Access            = $Obj.Access
                            DuetoMembershipIn = $Obj.'Due to Membership In'
                            SourceofAccess    = $Obj.'Source of Access'
                            Name              = $Obj.Name
                            Department        = $Obj.Department
                            Title             = $Obj.Title
                        }
                    }

                    $OutputObject['Data'] = ConvertTo-Json -Compress -InputObject @($ObjectsForJsonData)
                    $OutputObject['Columns'] = Get-FolderColumnJson -InputObject $Perm -PropNames Account, Access, 'Due to Membership In', 'Source of Access', Name, Department, Title
                    $TableId = "Perms_$($Group.Item.Path -replace '[^A-Za-z0-9\-_]', '-')"
                    $OutputObject['Table'] = $TableId
                    $Table = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $Perm -DataFilterControl -AllColumnsSearchable
                    $OutputObject['Div'] = New-BootstrapDiv -Text ($Heading + $SubHeading + $Table)
                    [PSCustomObject]$OutputObject

                }

            }

        }

        'prtgxml' {

            <#

            # ToDo: Users with ownership
            $NtfsIssueParams = @{
                FolderPermissions = $Permission.ItemPermissions
                UserPermissions   = $Permission.AccountPermissions
                GroupNameRule     = $GroupNameRule
                TodaysHostname    = $ThisHostname
                WhoAmI            = $WhoAmI
                LogMsgCache       = $LogCache
            }

            Write-LogMsg @LogParams -Text 'New-NtfsAclIssueReport @NtfsIssueParams'
            $NtfsIssues = New-NtfsAclIssueReport @NtfsIssueParams

            # Format the issues as a custom XML sensor for Paessler PRTG Network Monitor
            Write-LogMsg @LogParams -Text "Get-PrtgXmlSensorOutput -NtfsIssues `$NtfsIssues"
            $OutputObject['Data'] = Get-PrtgXmlSensorOutput -NtfsIssues $NtfsIssues
            [PSCustomObject]$OutputObject
            #>

        }

        'xml' {

            if ($GroupBy -eq 'none') {

                $OutputObject = @{}
                $OutputObject['Data'] = ($Permission.Values | ConvertTo-Xml).InnerXml
                [PSCustomObject]$OutputObject

            } else {

                ForEach ($Group in $PermissionGrouping) {
                    $OutputObject = @{}
                    $OutputObject['Data'] = ($Permission[$Group.Item.Path] | ConvertTo-Xml).InnerXml
                    [PSCustomObject]$OutputObject
                }

            }

        }

        default {}

    }

    return

}
function ConvertTo-ScriptHtml {

    param (
        $Permission,
        $PermissionGrouping,
        [string]$GroupBy
    )

    $ScriptHtmlBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Group in $Permission) {
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId "#$($Group.Table)" -ColumnJson $Group.Columns -DataJson $Group.Data))
    }

    if ($GroupBy -ne 'none') {

        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId '#Folders' -ColumnJson $PermissionGrouping.Columns -DataJson $PermissionGrouping.Data))

    }

    return $ScriptHtmlBuilder.ToString()

}
function Expand-AccountPermissionReference {

    param (

        $Reference,
        $PrincipalsByResolvedID,
        $ACEsByGUID

    )

    ForEach ($Account in $Reference) {

        $Access = ForEach ($PermissionRef in $Account.Access) {

            [PSCustomObject]@{
                Path       = $PermissionRef.Path
                Access     = $ACEsByGUID[$PermissionRef.AceGUIDs]
                PSTypeName = 'Permission.AccountPermissionItemAccess'
            }

        }

        [PSCustomObject]@{
            Account    = $PrincipalsByResolvedID[$Account.Account]
            Access     = $Access
            PSTypeName = 'Permission.AccountPermission'
        }

    }

}
function Expand-FlatPermissionReference {

    # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.

    param (

        $SortedPaths,
        $PrincipalsByResolvedID,
        $ACEsByGUID,
        $AceGUIDsByPath

    )

    ForEach ($Item in $SortedPaths) {

        ForEach ($ACE in $ACEsByGUID[$AceGUIDsByPath[$Item]]) {

            $Principal = $PrincipalsByResolvedID[$ACE.IdentityReferenceResolved]

            $OutputProperties = @{
                PSTypeName = 'Permission.FlatPermission'
                ItemPath   = $ACE.Path
                AdsiPath   = $Principal.Path
            }

            ForEach ($Prop in ($ACE | Get-Member -View All -MemberType Property, NoteProperty).Name) {
                $OutputProperties[$Prop] = $ACE.$Prop
            }

            ForEach ($Prop in ($Principal | Get-Member -View All -MemberType Property, NoteProperty).Name) {
                $OutputProperties[$Prop] = $Principal.$Prop
            }

            [pscustomobject]$OutputProperties

        }

    }

}
function Expand-ItemPermissionReference {

    param (

        $Reference,
        $PrincipalsByResolvedID,
        $ACEsByGUID

    )

    ForEach ($Item in $Reference) {

        $Access = ForEach ($PermissionRef in $Item.Access) {

            [PSCustomObject]@{
                Account    = $PrincipalsByResolvedID[$PermissionRef.Account]
                Access     = $ACEsByGUID[$PermissionRef.AceGUIDs]
                PSTypeName = 'Permission.ItemPermissionAccountAccess'
            }

        }

        [PSCustomObject]@{
            Item       = $Item.Item
            Access     = $Access
            PSTypeName = 'Permission.ItemPermission'
        }

    }

}
function Get-FolderPermissionTableHeader {
    [OutputType([System.String])]
    param (
        $Group,
        [string]$GroupID,
        [string]$ShortestFolderPath
    )
    $Parent = $GroupID | Split-Path -Parent
    $Leaf = $Parent | Split-Path -Leaf -ErrorAction SilentlyContinue
    if ($Leaf) {
        $ParentLeaf = $Leaf
    } else {
        $ParentLeaf = $Parent
    }
    if ('' -ne $ParentLeaf) {
        if ($Group.Item.AreAccessRulesProtected) {
            return "Inheritance is disabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) cannot access this folder unless they are listed below:"
        } else {
            if ($Group.Item.Path -eq $ShortestFolderPath) {
                return "Inherited permissions from the parent folder ($ParentLeaf) are included. This folder can only be accessed by the accounts listed below:"
            } else {
                return "Inheritance is enabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) can access this folder. So can any accounts listed below:"
            }
        }
    } else {
        return "This is the top-level folder. It can only be accessed by the accounts listed below:"
    }
}
function Get-HtmlBody {

    param (
        $TableOfContents,
        $HtmlFolderPermissions,
        $ReportFooter,
        $HtmlFileList,
        $HtmlExclusions
    )

    $StringBuilder = [System.Text.StringBuilder]::new()

    if ($TableOfContents) {
        $null = $StringBuilder.Append((New-HtmlHeading "Folders with Permissions in This Report" -Level 3))
        $null = $StringBuilder.Append($TableOfContents)
        $null = $StringBuilder.Append((New-HtmlHeading "Accounts Included in Those Permissions" -Level 3))
    } else {
        $null = $StringBuilder.Append((New-HtmlHeading "Permissions" -Level 3))
    }

    ForEach ($Perm in $HtmlFolderPermissions) {
        $null = $StringBuilder.Append($Perm)
    }

    if ($HtmlExclusions) {
        $null = $StringBuilder.Append((New-HtmlHeading "Exclusions from This Report" -Level 3))
        $null = $StringBuilder.Append($HtmlExclusions)
    }

    $null = $StringBuilder.Append((New-HtmlHeading "Files Generated" -Level 3))
    $null = $StringBuilder.Append($HtmlFileList)
    $null = $StringBuilder.Append($ReportFooter)

    return $StringBuilder.ToString()

}
function Get-ReportDescription {

    param (
        [int]$RecurseDepth
    )

    switch ($RecurseDepth ) {

        0 {
            'Does not include permissions on subfolders (option was declined)'
        }
        -1 {
            'Includes all subfolders with unique permissions (including ∞ levels of subfolders)'
        }
        default {
            "Includes all subfolders with unique permissions (down to $RecurseDepth levels of subfolders)"
        }

    }

}
function Get-SummaryTableHeader {
    param ($RecurseDepth)

    switch ($RecurseDepth ) {
        0 {
            'Includes the target folder only (option to report on subfolders was declined)'
        }
        -1 {
            'Includes the target folder and all subfolders with unique permissions'
        }
        default {
            "Includes the target folder and $RecurseDepth levels of subfolders with unique permissions"
        }
    }
}
function Group-AccountPermissionReference {

    param (
        $PrincipalsByResolvedID,
        $AceGUIDsByResolvedID,
        $ACEsByGUID
    )

    ForEach ($ID in $PrincipalsByResolvedID.Keys) {

        $ACEGuidsForThisID = $AceGUIDsByResolvedID[$ID]
        $ItemPaths = @{}

        ForEach ($Guid in $ACEGuidsForThisID) {

            $Ace = $ACEsByGUID[$Guid]
            Add-CacheItem -Cache $ItemPaths -Key $Ace.Path -Value $Guid -Type ([guid])

        }

        $ItemPermissionsForThisAccount = ForEach ($Item in $ItemPaths.Keys) {

            [PSCustomObject]@{
                Path     = $Item
                AceGUIDs = $ItemPaths[$Item]
            }

        }

        [PSCustomObject]@{
            Account = $ID
            Access  = $ItemPermissionsForThisAccount
        }

    }

}
function Group-ItemPermissionReference {

    param (
        $SortedPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $ACLsByPath,
        $PrincipalsByResolvedID
    )

    ForEach ($ItemPath in $SortedPath) {

        $Acl = $ACLsByPath[$ItemPath]
        $IDsWithAccess = Find-ResolvedIDsWithAccess -ItemPath $ItemPath -AceGUIDsByPath $AceGUIDsByPath -ACEsByGUID $ACEsByGUID -PrincipalsByResolvedID $PrincipalsByResolvedID

        $AccountPermissionsForThisItem = ForEach ($ID in ($IDsWithAccess.Keys | Sort-Object)) {

            [PSCustomObject]@{
                Account  = $ID
                AceGUIDs = $IDsWithAccess[$ID]
            }

        }

        [PSCustomObject]@{
            Item   = $Acl
            Access = $AccountPermissionsForThisItem
        }

    }

}
function Memory {
    <#
function SizeOfObj {
    param ([Type]$T, [Object]$thevalue, [System.Runtime.Serialization.ObjectIDGenerator]$gen)
    $type = $T
    [int]$returnval = 0
    if ($type.IsValueType) {
        $nulltype = [Nullable]::GetUnderlyingType($type)
        $returnval = [System.Runtime.InteropServices.Marshal]::SizeOf($nulltype ?? $type)
    } elseif ($null -eq $thevalue) {
        return 0
    } elseif ($thevalue.GetType().Name -eq 'String') {
        $returnval = ([System.Text.Encoding]::Default).GetByteCount([string]$thevalue)
    } elseif (
        $type.IsArray -and
        $type.GetElementType().IsValueType
    ) {
        $returnval = $thevalue.GetLength(0) * [System.Runtime.InteropServices.Marshal]::SizeOf($type.GetElementType())
    } elseif ($thevalue.GetType.Name -eq 'Stream') {
        [System.IO.Stream]$stream = [System.IO.Stream]$thevalue
        $returnval = [int]($stream.Length)
    } elseif ($type.IsSerializable) {
        try {
            [System.IO.MemoryStream]$s = [System.IO.MemoryStream]::new()
            [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]$formatter = [System.Runtime.Serialization.Formatters.Binary.BinaryFormatter]::new()
            $formatter.Serialize($s, $thevalue)
            $returnval = [int]($s.Length)
        } catch { }
    } elseif ($type.IsClass) {
        $returnval += SizeOfClass -thevalue $thevalue -gen ($gen ?? [System.Runtime.Serialization.ObjectIDGenerator]::new())
    }
    if ($returnval -eq 0) {
        try {
            $returnval = [System.Runtime.InteropServices.Marshal]::SizeOf($thevalue)
        } catch { }
    }
    return $returnval
}
function SizeOf {
    param ($T, $value)
    SizeOfObj -T ($T.GetType()) -thevalue $value -gen $null
}
function SizeOfClass {
    param (
        [Object]$thevalue, [System.Runtime.Serialization.ObjectIDGenerator]$gen
    )
    [bool]$isfirstTime = $null
    $gen.GetId($thevalue, [ref]$isfirstTime)
    if (-not $isfirstTime) { return 0 }
    $fields = $thevalue.GetType().GetFields([System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)

    [int]$returnval = 0
    for ($i = 0; $i -lt $fields.Length; $i++) {
        [Type]$t = $fields[$i].FieldType
        [Object]$v = $fields[$i].GetValue($thevalue)
        $returnval += 4 + (SizeOfObj -T $t -thevalue $v -gen $gen)
    }
    return $returnval
}

$Test = @{}

$n = 1000000
$i = 0
while ($i -lt $n) {
    $Test[$i] = [pscustomobject]@{prop1 = 'blah'}
    $i++
}
$Size = (SizeOf -t [hashtable] -value $Test)/1KB
"$Size KiB"
#>
}
function Resolve-SplitByParameter {

    param (

        <#
    How to split up the exported files:
        none    generate a single file with all permissions
        item    generate a file per item
        account generate a file per account
        all     generate 1 file per item and 1 file per account and 1 file with all permissions.
    #>
        [ValidateSet('none', 'all', 'item', 'account')]
        [string[]]$SplitBy = 'all'

    )

    $result = @{}

    foreach ($Split in $SplitBy) {

        if ($Split -eq 'none') {

            return @{'none' = $true }

        } elseif ($Split -eq 'all') {

            return @{
                'none'    = $true
                'item'    = $true
                'account' = $true
            }

        } else {

            $result[$Split] = $true

        }

    }

    return $result

}
function Select-ItemTableProperty {

    # For the HTML table

    param (
        $InputObject,
        $Culture = (Get-Culture)
    )

    ForEach ($Object in $InputObject) {

        [PSCustomObject]@{
            Folder      = $Object.Item.Path
            Inheritance = $Culture.TextInfo.ToTitleCase(-not $Object.Item.AreAccessRulesProtected)
        }

    }

}
function Select-PermissionTableProperty {

    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain,
        [hashtable]$OutputHash,
        [string]$GroupBy
    )

    switch ($GroupBy) {

        'none' {

            ForEach ($Object in $InputObject) {

                $OutputHash[[guid]::NewGuid()] = ForEach ($ACE in $Object) {

                    # Each ACE contains the original IdentityReference representing the group the Object is a member of
                    $GroupString = ($ACE.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                    # ToDo: param to allow setting [self] instead of the objects own name for this property
                    #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                    #    $GroupString = '[self]'
                    #} else {
                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
                    }
                    #}

                    [pscustomobject]@{
                        'Item'                 = $Object.ItemPath
                        'Account'              = $ACE.ResolvedAccountName
                        'Access'               = ($ACE.Access | Sort-Object -Unique) -join ' ; '
                        'Due to Membership In' = $GroupString
                        'Source of Access'     = ($ACE.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                        'Name'                 = $ACE.Name
                        'Department'           = $ACE.Department
                        'Title'                = $ACE.Title
                    }

                }

            }

        }

        # TODO: GroupBy account
        'account' {

        }

        #default is 'item'
        default {

            ForEach ($Object in $InputObject) {

                $OutputHash[$Object.Item.Path] = ForEach ($ACE in $Object.Access) {

                    # Each ACE contains the original IdentityReference representing the group the Object is a member of
                    $GroupString = ($ACE.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

                    # ToDo: param to allow setting [self] instead of the objects own name for this property
                    #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
                    #    $GroupString = '[self]'
                    #} else {
                    ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                        $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
                    }
                    #}

                    [pscustomobject]@{
                        'Account'              = $ACE.Account.ResolvedAccountName
                        'Access'               = ($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                        'Due to Membership In' = $GroupString
                        'Source of Access'     = ($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                        'Name'                 = $ACE.Account.Name
                        'Department'           = $ACE.Account.Department
                        'Title'                = $ACE.Account.Title
                    }

                }

            }
        }

    }

}
function Add-CacheItem {

    # Use a key to get a generic list from a hashtable
    # If it does not exist, create an empty list
    # Add the new item

    param (

        [hashtable]$Cache,

        $Key,

        $Value,

        [type]$Type

    )

    $CacheResult = $Cache[$Key]

    if (-not $CacheResult) {
        $Command = "`$CacheResult = [System.Collections.Generic.List[$($Type.ToString())]]::new()"
        Invoke-Expression $Command
    }

    $CacheResult.Add($Value)
    $Cache[$Key] = $CacheResult

}
function ConvertTo-ItemBlock {

    param (

        $ItemPermissions

    )

    $Culture = Get-Culture

    Write-LogMsg @LogParams -Text "`$ObjectsForTable = Select-ItemTableProperty -InputObject `$ItemPermissions -Culture '$Culture'"
    $ObjectsForTable = Select-ItemTableProperty -InputObject $ItemPermissions -Culture $Culture

    Write-LogMsg @LogParams -Text "`$ObjectsForTable | ConvertTo-Html -Fragment | New-BootstrapTable"
    $HtmlTable = $ObjectsForTable |
    ConvertTo-Html -Fragment |
    New-BootstrapTable

    $JsonData = $ObjectsForTable |
    ConvertTo-Json -Compress

    Write-LogMsg @LogParams -Text "Get-FolderColumnJson -InputObject `$ObjectsForTable"
    $JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForTable

    Write-LogMsg @LogParams -Text "ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject `$ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'"
    $JsonTable = ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject $ObjectsForTable -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'

    return [pscustomobject]@{
        HtmlDiv     = $HtmlTable
        JsonDiv     = $JsonTable
        JsonData    = $JsonData
        JsonColumns = $JsonColumns
    }

}
function Expand-Permission {

    # TODO: If SplitBy account or item, each file needs to include inherited permissions (with default $SplitBy = 'none', the parent folder's inherited permissions are already included)

    param (
        $SortedPaths,
        $SplitBy,
        $GroupBy,
        $AceGUIDsByPath,
        $AceGUIDsByResolvedID,
        $ACEsByGUID,
        $PrincipalsByResolvedID,
        $ACLsByPath
    )

    $HowToSplit = Resolve-SplitByParameter -SplitBy $SplitBy

    $CommonParams = @{
        ACEsByGUID             = $ACEsByGUID
        PrincipalsByResolvedID = $PrincipalsByResolvedID
    }

    if (
        $HowToSplit['account'] -or
        $GroupBy -eq 'account'
    ) {

        # Group reference GUIDs by the name of their associated account.
        $AccountPermissionReferences = Group-AccountPermissionReference @CommonParams -AceGUIDsByResolvedID $AceGUIDsByResolvedID

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        $AccountPermissions = Expand-AccountPermissionReference @CommonParams -Reference $AccountPermissionReferences

    }

    if (
        $HowToSplit['item'] -or
        $GroupBy -eq 'item'
    ) {

        # Group reference GUIDs by the path to their associated item.
        $ItemPermissionReferences = Group-ItemPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath -ACLsByPath $ACLsByPath

        # Expand reference GUIDs into their associated Access Control Entries and Security Principals.
        $ItemPermissions = Expand-ItemPermissionReference @CommonParams -Reference $ItemPermissionReferences

    }

    if (
        $HowToSplit['none'] -and
        $GroupBy -eq 'none'
    ) {

        # Expand each Access Control Entry with the Security Principal for the resolved IdentityReference.
        $FlatPermissions = Expand-FlatPermissionReference @CommonParams -SortedPath $SortedPaths -AceGUIDsByPath $AceGUIDsByPath

    }

    return [PSCustomObject]@{
        AccountPermissions = $AccountPermissions
        FlatPermissions    = $FlatPermissions
        ItemPermissions    = $ItemPermissions
        SplitBy            = $HowToSplit
    }

}
function Expand-PermissionTarget {

    # Expand a folder path into the paths of its subfolders

    param (

        <#
        How many levels of subfolder to enumerate

            Set to 0 to ignore all subfolders

            Set to -1 (default) to recurse infinitely

            Set to any whole number to enumerate that many levels
        #>
        $RecurseDepth,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $Progress = @{
        Activity = 'Expand-PermissionTarget'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $Targets = $ACLsByPath.Keys
    $TargetCount = $Targets.Count
    Write-Progress @Progress -Status "0% (item 0 of $TargetCount)" -CurrentOperation "Initializing..." -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    if ($ThreadCount -eq 1 -or $TargetCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($TargetCount / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Targets) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {
                [int]$PercentComplete = $i / $TargetCount * 100
                Write-Progress @Progress -Status "$PercentComplete% (item $($i + 1) of $TargetCount))" -CurrentOperation "Get-Subfolder '$($ThisFolder)'" -PercentComplete $PercentComplete
                $IntervalCounter = 0
            }

            $i++ # increment $i after the progress to show progress conservatively rather than optimistically
            $Subfolders = $null
            $Subfolders = Get-Subfolder -TargetPath $ThisFolder -FolderRecursionDepth $RecurseDepth -ErrorAction Continue @GetSubfolderParams
            Write-LogMsg @LogParams -Text "# Folders (including parent): $($Subfolders.Count + 1) for '$ThisFolder'"
            $Subfolders

        }

    } else {

        $SplitThreadParams = @{
            Command           = 'Get-Subfolder'
            InputObject       = $Targets
            InputParameter    = 'TargetPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $ThisHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetSubfolderParams
        }

        $Subfolders = Split-Thread @SplitThreadParams
        Write-LogMsg @LogParams -Text "# Folders (including parent): $($Subfolders.Count + 1) for all targets"
        $Subfolders

    }

    Write-Progress @Progress -Completed

}
function Find-ResolvedIDsWithAccess {

    param (
        $ItemPath,
        $AceGUIDsByPath,
        $ACEsByGUID,
        $PrincipalsByResolvedID
    )

    $IDsWithAccess = @{}

    ForEach ($Guid in $AceGUIDsByPath[$ItemPath]) {

        $Ace = $ACEsByGUID[$Guid]
        Add-CacheItem -Cache $IDsWithAccess -Key $Ace.IdentityReferenceResolved -Value $Guid -Type ([guid])

        ForEach ($Member in $PrincipalsByResolvedID[$Ace.IdentityReferenceResolved].Members) {

            Add-CacheItem -Cache $IDsWithAccess -Key $Member -Value $Guid -Type ([guid])

        }
    }

    $IDsWithAccess

}
function Format-Permission {

    param (

        # Permission object from Expand-Permission
        [PSCustomObject]$Permission,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Can be used:
          to ensure accounts only appear once on the report when they have matching SamAccountNames in multiple domains.
          when the domain is often the same and doesn't need to be displayed
        #>
        [string[]]$IgnoreDomain,

        # How to group the permissions in the output stream and within each exported file
        [ValidateSet('none', 'item', 'account')]
        [string]$GroupBy = 'item',

        # File formats to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru',

        [string]$ShortestPath,

        $Culture = (Get-Culture)

    )

    if ($GroupBy -eq 'none') {
        $Selection = $Permission.FlatPermissions
    } else {
        $Selection = $Permission."$GroupBy`Permissions"
    }

    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    $OutputProperties = @{
        passthru = $Selection
    }

    Write-LogMsg @LogParams -Text "`$PermissionGroupingsWithChosenProperties = Select-ItemTableProperty -InputObject `$Selection -Culture '$Culture'"
    $PermissionGroupingsWithChosenProperties = Select-ItemTableProperty -InputObject $Selection -Culture $Culture

    $PermissionsWithChosenProperties = [hashtable]::Synchronized(@{})

    Write-LogMsg @LogParams -Text "Select-PermissionTableProperty -InputObject `$Selection -IgnoreDomain '@('$($IgnoreDomain -join "','")')'"
    Select-PermissionTableProperty -InputObject $Selection -IgnoreDomain $IgnoreDomain -OutputHash $PermissionsWithChosenProperties -GroupBy $GroupBy

    ForEach ($Format in $Formats) {

        $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -Culture $Culture
        $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath $ShortestPath -GroupBy $GroupBy

    }

    [PSCustomObject]$OutputProperties

}
function Format-TimeSpan {
    param (
        [timespan]$TimeSpan,
        [string[]]$UnitsToResolve = @('day', 'hour', 'minute', 'second', 'millisecond')
    )
    $StringBuilder = [System.Text.StringBuilder]::new()
    $aUnitWithAValueHasBeenFound = $false
    foreach ($Unit in $UnitsToResolve) {
        if ($TimeSpan."$Unit`s") {
            if ($aUnitWithAValueHasBeenFound) {
                $null = $StringBuilder.Append(", ")
            }
            $aUnitWithAValueHasBeenFound = $true

            if ($TimeSpan."$Unit`s" -eq 1) {
                $null = $StringBuilder.Append("$($TimeSpan."$Unit`s") $Unit")
            } else {
                $null = $StringBuilder.Append("$($TimeSpan."$Unit`s") $Unit`s")
            }
        }
    }
    $StringBuilder.ToString()
}
function Get-CachedCimInstance {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Name of the CIM class whose instances to return
        [string]$ClassName,

        # CIM query to run. Overrides ClassName if used (but not efficiently, so don't use both)
        [string]$Query,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        [Parameter(Mandatory)]
        [string]$KeyProperty,

        [string[]]$CacheByProperty = $KeyProperty

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    if ($PSBoundParameters.ContainsKey('ClassName')) {
        $InstanceCacheKey = "$ClassName`By$KeyProperty"
    } else {
        $InstanceCacheKey = "$Query`By$KeyProperty"
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        Write-LogMsg @LogParams -Text " # CIM cache hit for '$ComputerName'"
        $CimCacheSubresult = $CimCacheResult[$InstanceCacheKey]

        if ($CimCacheSubresult) {
            Write-LogMsg @LogParams -Text " # CIM instance cache hit for '$InstanceCacheKey' on '$ComputerName'"
            return $CimCacheSubresult.Values
        } else {
            Write-LogMsg @LogParams -Text " # CIM instance cache miss for '$InstanceCacheKey' on '$ComputerName'"
        }

    } else {
        Write-LogMsg @LogParams -Text " # CIM cache miss for '$ComputerName'"
    }

    $CimSession = Get-CachedCimSession -ComputerName $ComputerName -CimCache $CimCache -ThisFqdn $ThisFqdn @LogParams

    if ($CimSession) {

        if ($PSBoundParameters.ContainsKey('ClassName')) {
            Write-LogMsg @LogParams -Text "Get-CimInstance -ClassName $ClassName -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -ClassName $ClassName -CimSession $CimSession -ErrorAction SilentlyContinue
        }

        if ($PSBoundParameters.ContainsKey('Query')) {
            Write-LogMsg @LogParams -Text "Get-CimInstance -Query '$Query' -CimSession `$CimSession"
            $CimInstance = Get-CimInstance -Query $Query -CimSession $CimSession -ErrorAction SilentlyContinue
        }

        if ($CimInstance) {

            $InstanceCache = [hashtable]::Synchronized(@{})

            ForEach ($Prop in $CacheByProperty) {

                if ($PSBoundParameters.ContainsKey('ClassName')) {
                    $InstanceCacheKey = "$ClassName`By$Prop"
                } else {
                    $InstanceCacheKey = "$Query`By$Prop"
                }

                ForEach ($Instance in $CimInstance) {
                    $InstancePropertyValue = $Instance.$Prop
                    Write-LogMsg @LogParams -Text " # Add '$InstancePropertyValue' to the '$InstanceCacheKey' cache for '$ComputerName'"
                    $InstanceCache[$InstancePropertyValue] = $Instance
                }

                $CimCache[$ComputerName][$InstanceCacheKey] = $InstanceCache

            }

            return $CimInstance

        }

    }

}
function Get-CachedCimSession {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $CimCacheResult = $CimCache[$ComputerName]

    if ($CimCacheResult) {

        Write-LogMsg @LogParams -Text " # CIM cache hit for '$ComputerName'"
        $CimCacheSubresult = $CimCacheResult['CimSession']

        if ($CimCacheSubresult) {
            Write-LogMsg @LogParams -Text " # CIM session cache hit for '$ComputerName'"
            return $CimCacheSubresult
        } else {
            Write-LogMsg @LogParams -Text " # CIM session cache miss for '$ComputerName'"
        }

    } else {

        Write-LogMsg @LogParams -Text " # CIM cache miss for '$ComputerName'"
        $CimCache[$ComputerName] = [hashtable]::Synchronized(@{})

    }

    if (
        $ComputerName -eq $ThisHostname -or
        $ComputerName -eq "$ThisHostname." -or
        $ComputerName -eq $ThisFqdn -or
        $ComputerName -eq "$ThisFqdn." -or
        $ComputerName -eq 'localhost' -or
        $ComputerName -eq '127.0.0.1' -or
        [string]::IsNullOrEmpty($ComputerName)
    ) {
        Write-LogMsg @LogParams -Text '$CimSession = New-CimSession'
        $CimSession = New-CimSession
    } else {
        # If an Active Directory domain is targeted there are no local accounts and CIM connectivity is not expected
        # Suppress errors and return nothing in that case
        Write-LogMsg @LogParams -Text "`$CimSession = New-CimSession -ComputerName $ComputerName"
        $CimSession = New-CimSession -ComputerName $ComputerName -ErrorAction SilentlyContinue
    }

    if ($CimSession) {
        $CimCache[$ComputerName]['CimSession'] = $CimSession
        return $CimSession
    }

}
function Get-FolderAcl {

    # Get folder access control lists
    # Returns an object representing each effective permission on a folder
    # This includes each Access Control Entry in the Discretionary Access List, as well as the folder's Owner

    param (

        # Path to the item whose permissions to export (inherited ACEs will be included)
        $Folder,

        # Path to the subfolders whose permissions to report (inherited ACEs will be skipped)
        $Subfolder,

        # Number of asynchronous threads to use
        [uint16]$ThreadCount = ((Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum),

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $Progress = @{
        Activity = 'Get-FolderAcl'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }
    $Progress['Id'] = $ProgressId
    $ChildProgress = @{
        Activity = 'Get folder access control lists'
        Id       = $ProgressId + 1
        ParentId = $ProgressId
    }

    Write-Progress @Progress -Status '0% (step 1 of 2)' -CurrentOperation 'Get parent folder access control lists' -PercentComplete 0

    $GetDirectorySecurity = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $TodaysHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        OwnerCache        = $OwnerCache
        ACLsByPath        = $ACLsByPath
    }

    # We expect a small number of folders and a large number of subfolders
    # We will multithread the subfolders but not the folders
    # Multithreading overhead actually hurts performance for such a fast operation (Get-FolderAcl) on a small number of items
    $i = 0
    $Count = $Folder.Count

    ForEach ($ThisFolder in $Folder) {

        [int]$PercentComplete = $i / $Count * 100
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $($i + 1) of $Count) Get-DirectorySecurity -IncludeInherited" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        $i++
        Get-DirectorySecurity -LiteralPath $ThisFolder -IncludeInherited @GetDirectorySecurity

    }

    Write-Progress @ChildProgress -Completed
    $ChildProgress['Activity'] = 'Get-FolderAcl (subfolders)'
    Write-Progress @Progress -Status '25% (step 2 of 4)' -CurrentOperation 'Get subfolder access control lists' -PercentComplete 25
    $SubfolderCount = $Subfolder.Count

    if ($ThreadCount -eq 1) {

        Write-Progress @ChildProgress -Status "0% (subfolder 0 of $SubfolderCount)" -CurrentOperation 'Initializing' -PercentComplete 0
        [int]$ProgressInterval = [math]::max(($SubfolderCount / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Subfolder) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $SubfolderCount) Get-DirectorySecurity" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after the progress to show progress conservatively rather than optimistically
            Get-DirectorySecurity -LiteralPath $ThisFolder @GetDirectorySecurity

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $SplitThread = @{
            Command           = 'Get-DirectorySecurity'
            InputObject       = $Subfolder
            InputParameter    = 'LiteralPath'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetDirectorySecurity

        }

        Split-Thread @SplitThread

    }

    # Update the cache with ACEs for the item owners (if they do not match the owner of the item's parent folder)
    # First return the owner of the parent item
    Write-Progress @Progress -Status '50% (step 3 of 4) Get-OwnerAce (parent folders)' -CurrentOperation 'Get parent folder owners' -PercentComplete 50
    $ChildProgress['Activity'] = 'Get-FolderAcl (parent owners)'
    $i = 0

    $GetOwnerAce = @{
        OwnerCache = $OwnerCache
        ACLsByPath = $ACLsByPath
    }

    ForEach ($ThisFolder in $Folder) {

        [int]$PercentComplete = $i / $Count * 100
        $i++
        Write-Progress @ChildProgress -Status "$PercentComplete% (parent $i of $Count) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
        Get-OwnerAce -Item $ThisFolder @GetOwnerAce

    }

    Write-Progress @ChildProgress -Completed
    Write-Progress @Progress -Status '75% (step 4 of 4) Get-OwnerAce (subfolders)' -CurrentOperation 'Get subfolder owners' -PercentComplete 75
    $ChildProgress['Activity'] = 'Get-FolderAcl (subfolder owners)'

    # Then return the owners of any items that differ from their parents' owners
    if ($ThreadCount -eq 1) {

        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisFolder in $Subfolder) {

            Write-Progress @ChildProgress -Status '0%' -CurrentOperation 'Initializing'
            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $SubfolderCount * 100
                Write-Progress @ChildProgress -Status "$PercentComplete% (subfolder $($i + 1) of $SubfolderCount)) Get-OwnerAce" -CurrentOperation $ThisFolder -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Get-OwnerAce -Item $ThisFolder @GetOwnerAce

        }

        Write-Progress @ChildProgress -Completed

    } else {

        $SplitThread = @{
            Command           = 'Get-OwnerAce'
            InputObject       = $Subfolder
            InputParameter    = 'Item'
            DebugOutputStream = $DebugOutputStream
            TodaysHostname    = $TodaysHostname
            WhoAmI            = $WhoAmI
            LogMsgCache       = $LogMsgCache
            Threads           = $ThreadCount
            AddParam          = $GetOwnerAce
        }

        Split-Thread @SplitThread

    }

    Write-Progress @Progress -Completed

}
function Get-FolderColumnJson {
    # For the JSON that will be used by JavaScript to generate the table
    param (
        $InputObject,
        [string[]]$PropNames
    )

    if (-not $PSBoundParameters.ContainsKey('PropNames')) {
        $PropNames = (@($InputObject)[0] | Get-Member -MemberType noteproperty).Name
    }

    $Columns = ForEach ($Prop in $PropNames) {
        $Props = @{
            'field' = $Prop -replace '\s', ''
            'title' = $Prop
        }
        if ($Prop -eq 'Inheritance') {
            $Props['width'] = '1'
        }
        [PSCustomObject]$Props
    }

    $Columns |
    ConvertTo-Json -Compress
}
function Get-FolderPermissionsBlock {
    param (

        # Output from Format-FolderPermission in the PsNtfsModule which has already been piped to Group-Object using the Folder property
        $FolderPermissions,

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        # Accounts whose objectClass property is in this list are excluded from the HTML report
        [string[]]$ExcludeClass = @('group', 'computer'),

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        $ShortestPath

    )

    # Convert the $ExcludeClass array into a dictionary for fast lookups
    $ClassExclusions = @{}
    ForEach ($ThisClass in $ExcludeClass) {
        $ClassExclusions[$ThisClass] = $true
    }

    ForEach ($ThisFolder in $FolderPermissions) {

        $ThisHeading = New-HtmlHeading "Accounts with access to $($ThisFolder.Item.Path)" -Level 5

        $ThisSubHeading = Get-FolderPermissionTableHeader -ThisFolder $ThisFolder -ShortestFolderPath $ShortestPath

        #$FilterContents = @{}

        $FilteredPermissions = $ThisFolder.Access |
        Where-Object -FilterScript {

            # On built-in groups like 'Authenticated Users' or 'Administrators' the SchemaClassName is null but we have an ObjectType instead.
            # TODO: Research where this difference came from, should these be normalized earlier in the process?
            # A user who was found by being a member of a local group not have an ObjectType (because they are not directly part of the AccessControlEntry)
            # They should have their parent group's AccessControlEntry there...do they?  Doesn't it have a Group ObjectType there?

            ###if ($_.Group.AccessControlEntry.ObjectType) {
            ###    $Schema = @($_.Group.AccessControlEntry.ObjectType)[0]
            ###    $Schema = @($_.Group.SchemaClassName)[0]
            # ToDo: SchemaClassName is a real property but may not exist on all objects.  ObjectType is my own property.  Need to verify+test all usage of both for accuracy.
            # ToDo: Why is $_.Group.SchemaClassName 'user' for the local Administrators group and Authenticated Users group, and it is 'Group' for the TestPC\Owner user?
            ###}

            # Exclude the object whose classes were specified in the parameters
            $SchemaExclusionResult = if ($ExcludeClass.Count -gt 0) {
                ###$ClassExclusions[$Schema]
                $ClassExclusions[$_.Account.SchemaClassName]
            }
            -not $SchemaExclusionResult -and

            # Exclude the objects whose names match the regular expressions specified in the parameters
            ![bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($_.Account.ResolvedAccountName -match $RegEx) {
                        #$FilterContents[$_.Account.ResolvedAccountName] += $_ #TODO: IMPLEMENT IN FUTURE WITH HASHTABLE, NOT += which is demonstrative only for now
                        $true
                    }
                }
            )

        }

        # Bugfix #48 https://github.com/IMJLA/Export-Permission/issues/48
        # Sending a dummy object down the line to avoid errors
        # TODO: More elegant solution needed. Downstream code should be able to handle null input.
        # TODO: Why does this suppress errors, but the object never appears in the tables? NOTE: Suspect this is now resolved by using -AsArray on ConvertTo-Json (lack of this was causing single objects to not be an array therefore not be displayed)
        if ($null -eq $FilteredPermissions) {
            $FilteredPermissions = [pscustomobject]@{
                'Account' = 'NoAccountsMatchingCriteria'
                'Access'  = [pscustomobject]@{
                    'IdentityReferenceResolved' = '.'
                    'FileSystemRights'          = '.'
                    'SourceOfAccess'            = '.'
                    'Name'                      = '.'
                    'Department'                = '.'
                    'Title'                     = '.'
                }
            }
        }

        $ObjectsForFolderPermissionTable = Select-ItemPermissionTableProperty -InputObject $FilteredPermissions -IgnoreDomain $IgnoreDomain |
        Sort-Object -Property Account

        $ThisTable = $ObjectsForFolderPermissionTable |
        ConvertTo-Html -Fragment |
        New-BootstrapTable

        $TableId = "Perms_$($ThisFolder.Item.Path -replace '[^A-Za-z0-9\-_]', '-')"

        $ThisJsonTable = ConvertTo-BootstrapJavaScriptTable -Id $TableId -InputObject $ObjectsForFolderPermissionTable -DataFilterControl -AllColumnsSearchable

        # Remove spaces from property titles
        $ObjectsForJsonData = ForEach ($Obj in $ObjectsForFolderPermissionTable) {
            [PSCustomObject]@{
                Account           = $Obj.Account
                Access            = $Obj.Access
                DuetoMembershipIn = $Obj.'Due to Membership In'
                SourceofAccess    = $Obj.'Source of Access'
                Name              = $Obj.Name
                Department        = $Obj.Department
                Title             = $Obj.Title
            }
        }

        [pscustomobject]@{
            HtmlDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisTable)
            JsonDiv     = New-BootstrapDiv -Text ($ThisHeading + $ThisSubHeading + $ThisJsonTable)
            JsonColumns = Get-FolderColumnJson -InputObject $ObjectsForFolderPermissionTable -PropNames Account, Access,
            'Due to Membership In', 'Source of Access', Name, Department, Title
            #JsonData    = $ObjectsForJsonData | ConvertTo-Json -AsArray # requires PS6+ , unknown if any performance benefit compared to wrapping in @()
            JsonData    = ConvertTo-Json -InputObject @($ObjectsForJsonData) -Compress
            JsonTable   = $TableId
            Path        = $ThisFolder.Item.Path
        }
    }
}
function Get-HtmlReportFooter {
    param (
        # Stopwatch that was started when report generation began
        [System.Diagnostics.Stopwatch]$StopWatch,

        # NT Account caption (CONTOSO\User) of the account running this function
        [string]$WhoAmI = (whoami.EXE),

        <#
        FQDN of the computer running this function

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        [uint64]$ItemCount,

        [uint64]$TotalBytes,

        [string]$ReportInstanceId,

        [UInt64]$PermissionCount,

        [UInt64]$PrincipalCount

    )
    $null = $StopWatch.Stop()
    $FinishTime = Get-Date
    $StartTime = $FinishTime.AddTicks(-$StopWatch.ElapsedTicks)
    $TimeZoneName = Get-TimeZoneName -Time $FinishTime
    $Duration = Format-TimeSpan -TimeSpan $StopWatch.Elapsed
    if ($TotalBytes) {
        $Size = " ($($TotalBytes / 1TB) TiB"
    }
    $Text = @"
Report generated by $WhoAmI on $ThisFQDN starting at $StartTime and ending at $FinishTime $TimeZoneName<br />
Processed $PermissionCount permissions for $PrincipalCount accounts on $ItemCount items$Size in $Duration<br />
Report instance: $ReportInstanceId
"@
    New-BootstrapAlert -Class Light -Text $Text
}
<#
$TagetPath.Count parent folders
$ItemCount total folders including children
$FolderPermissions folders with unique permissions
$Permissions.Count access control entries on those folders
$Identities.Count identities in those access control entries
$FormattedSecurityPrincipals principals represented by those identities
$UniqueAccountPermissions.Count unique accounts after filtering out any specified domain names
$ExpandedAccountPermissions.Count effective permissions belonging to those principals and applying to those folders
#>
function Get-PermissionPrincipal {

    param (

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of security principals keyed by resolved identity reference. END STATE
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entries keyed by their resolved identities. STARTING STATE
        [hashtable]$ACEsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        <#
        Do not get group members (only report the groups themselves)

        Note: By default, the -ExcludeClass parameter will exclude groups from the report.
          If using -NoGroupMembers, you most likely want to modify the value of -ExcludeClass.
          Remove the 'group' class from ExcludeClass in order to see groups on the report.
        #>
        [switch]$NoGroupMembers,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [string]$CurrentDomain = (Get-CurrentDomain)

    )

    $Progress = @{
        Activity = 'Get-PermissionPrincipal'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    [string[]]$IDs = $ACEsByResolvedID.Keys
    $Count = $IDs.Count
    Write-Progress @Progress -Status "0% (identity 0 of $Count)" -CurrentOperation 'Initialize' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ADSIConversionParams = @{
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsBySID           = $DomainsBySID
        DomainsByNetbios       = $DomainsByNetbios
        DomainsByFqdn          = $DomainsByFqdn
        ThisHostName           = $ThisHostName
        ThisFqdn               = $ThisFqdn
        WhoAmI                 = $WhoAmI
        LogMsgCache            = $LogMsgCache
        CimCache               = $CimCache
        DebugOutputStream      = $DebugOutputStream
        PrincipalsByResolvedID = $PrincipalsByResolvedID # end state
        ACEsByResolvedID       = $ACEsByResolvedID # start state
        CurrentDomain          = $CurrentDomain
    }

    if ($ThreadCount -eq 1) {

        if ($NoGroupMembers) {
            $ADSIConversionParams['NoGroupMembers'] = $true
        }

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisID in $IDs) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (identity $($i + 1) of $Count) ConvertFrom-IdentityReferenceResolved" -CurrentOperation $ThisID -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++
            Write-LogMsg @LogParams -Text "ConvertFrom-IdentityReferenceResolved -IdentityReference '$ThisID'"
            ConvertFrom-IdentityReferenceResolved -IdentityReference $ThisID @ADSIConversionParams

        }

    } else {

        if ($NoGroupMembers) {
            $ADSIConversionParams['AddSwitch'] = 'NoGroupMembers'
        }

        $SplitThreadParams = @{
            Command              = 'ConvertFrom-IdentityReferenceResolved'
            InputObject          = $IDs
            InputParameter       = 'IdentityReference'
            ObjectStringProperty = 'Name'
            TodaysHostname       = $ThisHostname
            WhoAmI               = $WhoAmI
            LogMsgCache          = $LogMsgCache
            Threads              = $ThreadCount
            AddParam             = $ADSIConversionParams
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'ConvertFrom-IdentityReferenceResolved' -InputParameter 'IdentityReference' -InputObject `$IDs"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
function Get-PrtgXmlSensorOutput {
    param (
        $NtfsIssues
    )

    $Channels = [System.Collections.Generic.List[string]]::new()


    # Build our XML output formatted for PRTG.
    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'Folders with inheritance disabled'
        Value      = ($NtfsIssues.FoldersWithBrokenInheritance | Measure-Object).Count
        CustomUnit = 'folders'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for groups breaking naming convention'
        Value      = ($NtfsIssues.NonCompliantGroups | Measure-Object).Count
        CustomUnit = 'ACEs'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for users instead of groups'
        Value      = ($NtfsIssues.UserACEs | Measure-Object).Count
        CustomUnit = 'ACEs'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }


    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for unresolvable SIDs'
        Value      = ($NtfsIssues.SIDsToCleanup | Measure-Object).Count
        CustomUnit = 'ACEs'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }


    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = "Folders with 'CREATOR OWNER' access"
        Value      = ($NtfsIssues.FoldersWithCreatorOwner | Measure-Object).Count
        CustomUnit = 'folders'
    }
    Format-PrtgXmlResult @ChannelParams |
    ForEach-Object { $null = $Channels.Add($_) }

    Format-PrtgXmlSensorOutput -PrtgXmlResult $Channels -IssueDetected:$($NtfsIssues.IssueDetected)

}
function Get-TimeZoneName {
    param (
        [datetime]$Time,
        [Microsoft.Management.Infrastructure.CimInstance]$TimeZone = (Get-CimInstance -ClassName Win32_TimeZone)
    )
    if ($Time.IsDaylightSavingTime()) {
        return $TimeZone.DaylightName
    } else {
        return $TimeZone.StandardName
    }
}

# Build a list of known ADSI server names to use to populate the caches
# Include the FQDN of the current computer and the known trusted domains
function Get-UniqueServerFqdn {

    param (

        # Known server FQDNs to include in the output
        [string[]]$Known,

        # File paths whose server FQDNs to include in the output
        [string[]]$FilePath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Get-UniqueServerFqdn'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }

    $Progress['Id'] = $ProgressId
    $Count = $FilePath.Count
    Write-Progress @Progress -Status "0% (path 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $UniqueValues = @{
        $ThisFqdn = $null
    }

    ForEach ($Value in $Known) {
        $UniqueValues[$Value] = $null
    }

    # Add server names from the ACL paths

    $ProgressStopWatch = [System.Diagnostics.Stopwatch]::new()
    $ProgressStopWatch.Start()
    $LastRemainder = [int]::MaxValue
    $i = 0

    ForEach ($ThisPath in $FilePath) {

        $NewRemainder = $ProgressStopWatch.ElapsedTicks % 5000

        if ($NewRemainder -lt $LastRemainder) {

            $LastRemainder = $NewRemainder
            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @Progress -Status "$PercentComplete% (path $($i + 1) of $Count)" -CurrentOperation "Find-ServerNameInPath '$ThisPath'" -PercentComplete $PercentComplete

        }

        $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
        $UniqueValues[(Find-ServerNameInPath -LiteralPath $ThisPath -ThisFqdn $ThisFqdn)] = $null
    }

    Write-Progress @Progress -Completed

    return $UniqueValues.Keys

}
function Initialize-Cache {

    <#
    Pre-populate caches in memory to avoid redundant ADSI and CIM queries
    Use known ADSI and CIM server FQDNs to populate six caches:
       Three caches of known ADSI directory servers
         The first cache is keyed on domain SID (e.g. S-1-5-2)
         The second cache is keyed on domain FQDN (e.g. ad.contoso.com)
         The first cache is keyed on domain NetBIOS name (e.g. CONTOSO)
       Two caches of known Win32_Account instances
         The first cache is keyed on SID (e.g. S-1-5-2)
         The second cache is keyed on the Caption (NT Account name e.g. CONTOSO\user1)
       Also populate a cache of DirectoryEntry objects for any domains that have them
     This prevents threads that start near the same time from finding the cache empty and attempting costly operations to populate it
     This prevents repetitive queries to the same directory servers
    #>

    param (

        # FQDNs of the ADSI servers to use to populate the cache
        [string[]]$Fqdn,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )


    $Progress = @{
        Activity = 'Initialize-Cache'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $ProgressId = $ProgressParentId + 1
    } else {
        $ProgressId = 0
    }

    $Progress['Id'] = $ProgressId
    $Count = $ServerFqdns.Count
    Write-Progress -Status "0% (FQDN 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0 @Progress

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $GetAdsiServer = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
        ThisHostName        = $ThisHostName
        ThisFqdn            = $ThisFqdn
        WhoAmI              = $WhoAmI
        LogMsgCache         = $LogMsgCache
        CimCache            = $CimCache
    }

    if ($ThreadCount -eq 1) {

        $ProgressStopWatch = [System.Diagnostics.Stopwatch]::new()
        $ProgressStopWatch.Start()
        $LastRemainder = [int]::MaxValue
        $i = 0

        ForEach ($ThisServerName in $ServerFqdns) {

            $NewRemainder = $ProgressStopWatch.ElapsedTicks % 5000

            if ($NewRemainder -lt $LastRemainder) {

                $LastRemainder = $NewRemainder
                [int]$PercentComplete = $i / $Count * 100
                Write-Progress -Status "$PercentComplete% (FQDN $($i + 1) of $Count) Get-AdsiServer" -CurrentOperation "Get-AdsiServer '$ThisServerName'" -PercentComplete $PercentComplete @Progress

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-LogMsg @LogParams -Text "Get-AdsiServer -Fqdn '$ThisServerName'"
            $null = Get-AdsiServer -Fqdn $ThisServerName @GetAdsiServer

        }

    } else {

        $SplitThread = @{
            Command        = 'Get-AdsiServer'
            InputObject    = $ServerFqdns
            InputParameter = 'Fqdn'
            TodaysHostname = $ThisHostname
            WhoAmI         = $WhoAmI
            LogMsgCache    = $LogMsgCache
            Timeout        = 600
            Threads        = $ThreadCount
            AddParam       = $GetAdsiServer
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Get-AdsiServer' -InputParameter AdsiServer -InputObject @('$($ServerFqdns -join "',")')"
        $null = Split-Thread @SplitThread

    }

    Write-Progress @Progress -Completed

}
function Invoke-PermissionCommand {

    param (

        [string]$Command

    )

    $Steps = [System.Collections.Specialized.OrderedDictionary]::New()
    $Steps.Add(
        'Get the NTAccount caption of the user running the script, with the correct capitalization',
        { HOSTNAME.EXE }
    )
    $Steps.Add(
        'Get the hostname of the computer running the script',
        { Get-CurrentWhoAmI -LogMsgCache $LogMsgCache -ThisHostName $ThisHostname }
    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        #Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $StepCount = $Steps.Count
    Write-LogMsg @LogParams -Type Verbose -Text $Command
    $ScriptBlock = $Steps[$Command]
    Write-LogMsg @LogParams -Type Debug -Text $ScriptBlock
    Invoke-Command -ScriptBlock $ScriptBlock

}
function Out-PermissionReport {

    # missing

    param (

        # Regular expressions matching names of security principals to exclude from the HTML report
        [string[]]$ExcludeAccount,

        # Accounts whose objectClass property is in this list are excluded from the HTML report
        [string[]]$ExcludeClass = @('group', 'computer'),

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        $IgnoreDomain,

        # Path to the NTFS folder whose permissions are being exported
        [string[]]$TargetPath,

        # Group members are not being exported (only the groups themselves)
        [switch]$NoMembers,

        # Path to the folder to save the logs and reports generated by this script
        $OutputDir,

        # NTAccount caption of the user running the script
        $WhoAmI,

        # FQDN of the computer running the script
        $ThisFqdn,

        # Timer to measure progress and performance
        $StopWatch,

        # Title at the top of the HTML report
        $Title,

        $Permission,
        $FormattedPermission,
        $LogParams,
        $RecurseDepth,
        [string[]]$ReportFileList = @(),
        $ReportFile,
        $LogFileList,
        $ReportInstanceId,
        [hashtable]$ACEsByGUID,
        [hashtable]$ACLsByPath,
        $PrincipalsByResolvedID,
        $BestPracticeIssue,
        [string[]]$Parent,

        <#
        Level of detail to export to file
            0   Item paths                                                                                  $TargetPath
            1   Resolved item paths (server names resolved, DFS targets resolved)                           $Parents
            2   Expanded resolved item paths (parent paths expanded into children)                          $ACLsByPath.Keys
            3   Access rules                                                                                $ACLsByPath.Values
            4   Resolved access rules (server names resolved, inheritance flags resolved)                   $ACEsByGUID.Values | %{$_} | Sort Path,IdentityReferenceResolved
            5   Accounts with access                                                                        $PrincipalsByResolvedID.Values | %{$_} | Sort ResolvedAccountName
            6   Expanded resolved access rules (expanded with account info)                                 $Permissions
            7   Formatted permissions                                                                       $FormattedPermissions
            8   Best Practice issues                                                                        $BestPracticeIssues
            9   XML custom sensor output for Paessler PRTG Network Monitor                                  $PrtgXml
            10  Permission Report
        #>
        [int[]]$Detail = @(0..10),

        $Culture = (Get-Culture)

    )

    Write-LogMsg @LogParams -Text "Get-ReportDescription -RecurseDepth $RecurseDepth"
    $ReportDescription = Get-ReportDescription -RecurseDepth $RecurseDepth

    Write-LogMsg @LogParams -Text "Get-SummaryTableHeader -RecurseDepth $RecurseDepth"
    $SummaryTableHeader = Get-SummaryTableHeader -RecurseDepth $RecurseDepth

    # Convert the target path(s) to a Bootstrap alert
    $TargetPathString = $TargetPath -join '<br />'
    Write-LogMsg @LogParams -Text "New-BootstrapAlert -Class Dark -Text '$TargetPathString'"
    $TargetAlert = New-BootstrapAlert -Class Dark -Text $TargetPathString

    $ReportParameters = @{
        Title       = $Title
        Description = "$TargetAlert $ReportDescription"
    }

    $ExcludedNames = ConvertTo-NameExclusionDiv -ExcludeAccount $ExcludeAccount
    $ExcludedClasses = ConvertTo-ClassExclusionDiv -ExcludeClass $ExcludeClass
    $IgnoredDomains = ConvertTo-IgnoredDomainDiv -IgnoreDomain $IgnoreDomain
    $ExcludedMembers = ConvertTo-MemberExclusionDiv -NoMembers:$NoMembers

    # Arrange the exclusions in two Bootstrap columns
    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$ExcludedMembers`$ExcludedClasses',`$IgnoredDomains`$ExcludedNames"
    $ExclusionsDiv = New-BootstrapColumn -Html "$ExcludedMembers$ExcludedClasses", "$IgnoredDomains$ExcludedNames" -Width 6

    # Convert the list of generated log files to a Bootstrap list group
    $HtmlListOfLogs = $LogFileList |
    Split-Path -Leaf |
    ConvertTo-HtmlList |
    ConvertTo-BootstrapListGroup

    # Prepare headings for 2 columns listing report and log files generated, respectively
    $HtmlReportsHeading = New-HtmlHeading -Text 'Reports' -Level 6
    $HtmlLogsHeading = New-HtmlHeading -Text 'Logs' -Level 6

    # Convert the output directory path to a Boostrap alert
    $HtmlOutputDir = New-BootstrapAlert -Text $OutputDir -Class 'secondary'

    # Determine all formats specified by the parameters
    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    ForEach ($Format in $Formats) {

        # Convert the list of permission groupings list to an HTML table
        $PermissionGroupings = $FormattedPermission."$Format`Group"
        $Permissions = $FormattedPermission.$Format

        $DetailScripts = @(
            { $TargetPath },
            { $Parent },
            { $ACLsByPath.Keys },
            { $ACLsByPath.Values },
            { ForEach ($val in $ACEsByGUID.Values) { $val } },
            { ForEach ($val in $PrincipalsByResolvedID.Values) { $val } },
            { $Permission },
            { $Permissions.Data },
            { $BestPracticeIssues },
            { $PrtgXml },
            {}
        )

        $ReportObjects = @{}

        ForEach ($Level in $Detail) {

            # Save the report
            $ReportObjects[$Level] = Invoke-Command -ScriptBlock $DetailScripts[$Level]

        }

        # String translations indexed by value in the $Detail parameter
        # TODO: Move to i18n
        $DetailStrings = @(
            'Target paths',
            'Resolved target paths (server names and DFS targets resolved)'
            'Item paths (resolved target paths expanded into their children)',
            'Access lists',
            'Access rules (resolved identity references and inheritance flags)',
            'Accounts with access',
            'Expanded access rules (expanded with account info)', # #ToDo: Expand DirectoryEntry objects in the DirectoryEntry and Members properties
            'Formatted permissions',
            'Best Practice issues',
            'Custom sensor output for Paessler PRTG Network Monitor'
            'Permission report'
        )

        switch ($Format) {

            'csv' {

                $DetailExports = @(
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile },
                    { $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile },
                    { $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> },
                    { <# $Report | Export-Csv -NoTypeInformation -LiteralPath $ThisReportFile#> }
                )

                ForEach ($Level in $Detail) {

                    # Get shorter versions of the detail strings to use in file names
                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                    # Convert the shorter strings to Title Case
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                    # Remove spaces from the shorter strings
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                    # Build the file path
                    $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail.$Format"

                    # Add the file path to the list of created files
                    $ReportFileList += $ThisReportFile

                    # Generate the report
                    $Report = $ReportObjects[$Level]

                    # Save the report
                    $null = Invoke-Command -ScriptBlock $DetailExports[$Level]

                    # Output the name of the report file to the Information stream
                    Write-Information $ThisReportFile

                }

            }

            'html' {

                $DetailScripts[10] = {

                    # Convert the list of generated report files to a Bootstrap list group
                    $HtmlListOfReports = $ReportFileList |
                    Split-Path -Leaf |
                    #Sort-Object |
                    ConvertTo-HtmlList |
                    ConvertTo-BootstrapListGroup

                    # Arrange the lists of generated files in two Bootstrap columns
                    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$HtmlReportsHeading`$HtmlListOfReports',`$HtmlLogsHeading`$HtmlListOfLogs"
                    $FileListColumns = New-BootstrapColumn -Html "$HtmlReportsHeading$HtmlListOfReports", "$HtmlLogsHeading$HtmlListOfLogs" -Width 6

                    # Combine the alert and the columns of generated files inside a Bootstrap div
                    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Output Folder:' -Content '`$HtmlOutputDir`$FileListColumns'"
                    $FileList = New-BootstrapDivWithHeading -HeadingText "Output Folder:" -Content "$HtmlOutputDir$FileListColumns"

                    # Generate a footer to include at the bottom of the report
                    Write-LogMsg @LogParams -Text "Get-ReportFooter -StopWatch `$StopWatch -ReportInstanceId '$ReportInstanceId' -WhoAmI '$WhoAmI' -ThisFqdn '$ThisFqdn'"
                    $FooterParams = @{
                        StopWatch        = $StopWatch
                        ReportInstanceId = $ReportInstanceId
                        WhoAmI           = $WhoAmI
                        ThisFqdn         = $ThisFqdn
                        ItemCount        = $ACLsByPath.Keys.Count
                        PermissionCount  = $Permission.ItemPermissions.Access.Access.Count
                        PrincipalCount   = $PrincipalsByResolvedID.Keys.Count
                    }
                    $ReportFooter = Get-HtmlReportFooter @FooterParams

                    $BodyParams = @{
                        HtmlFolderPermissions = $Permissions.Div
                        HtmlExclusions        = $ExclusionsDiv
                        HtmlFileList          = $FileList
                        ReportFooter          = $ReportFooter
                    }

                    if ($Permission.FlatPermissions) {

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody @BodyParams

                        # Apply the report template to the generated HTML report body and description
                        Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
                        New-BootstrapReport -Body $Body @ReportParameters

                    } else {

                        # Combine the header and table inside a Bootstrap div
                        Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                        $TableOfContents = New-BootstrapDivWithHeading -HeadingText $SummaryTableHeader -Content $PermissionGroupings.Table

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                        # Apply the report template to the generated HTML report body and description
                        Write-LogMsg @LogParams -Text "New-BootstrapReport @ReportParameters"
                        New-BootstrapReport -Body $Body @ReportParameters

                    }

                }

                $DetailExports = @(
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { $Report -join "<br />`r`n" | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                    { $Report | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                    { <#$Report | ConvertTo-Html -Fragment | Out-File -LiteralPath $ThisReportFile#> },
                    { $null = Set-Content -LiteralPath $ThisReportFile -Value $Report }
                )

                ForEach ($Level in $Detail) {

                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''
                    $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail.htm"
                    $ReportFileList += $ThisReportFile

                    # Save the report
                    $Report = Invoke-Command -ScriptBlock $DetailScripts[$Level]
                    $null = Invoke-Command -ScriptBlock $DetailExports[$Level]

                    # Output the name of the report file to the Information stream
                    Write-Information $ThisReportFile

                }

            }

            'json' {

                $DetailScripts[10] = {

                    # Convert the list of generated report files to a Bootstrap list group
                    $HtmlListOfReports = $ReportFileList |
                    Split-Path -Leaf |
                    #Sort-Object |
                    ConvertTo-HtmlList |
                    ConvertTo-BootstrapListGroup

                    # Arrange the lists of generated files in two Bootstrap columns
                    Write-LogMsg @LogParams -Text "New-BootstrapColumn -Html '`$HtmlReportsHeading`$HtmlListOfReports',`$HtmlLogsHeading`$HtmlListOfLogs"
                    $FileListColumns = New-BootstrapColumn -Html "$HtmlReportsHeading$HtmlListOfReports", "$HtmlLogsHeading$HtmlListOfLogs" -Width 6

                    # Combine the alert and the columns of generated files inside a Bootstrap div
                    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Output Folder:' -Content '`$HtmlOutputDir`$FileListColumns'"
                    $FileList = New-BootstrapDivWithHeading -HeadingText "Output Folder:" -Content "$HtmlOutputDir$FileListColumns"

                    # Generate a footer to include at the bottom of the report
                    Write-LogMsg @LogParams -Text "Get-ReportFooter -StopWatch `$StopWatch -ReportInstanceId '$ReportInstanceId' -WhoAmI '$WhoAmI' -ThisFqdn '$ThisFqdn'"
                    $FooterParams = @{
                        StopWatch        = $StopWatch
                        ReportInstanceId = $ReportInstanceId
                        WhoAmI           = $WhoAmI
                        ThisFqdn         = $ThisFqdn
                        ItemCount        = $ACLsByPath.Keys.Count
                        PermissionCount  = $Permission.ItemPermissions.Access.Access.Count
                        PrincipalCount   = $PrincipalsByResolvedID.Keys.Count
                    }
                    $ReportFooter = Get-HtmlReportFooter @FooterParams

                    $BodyParams = @{
                        HtmlFolderPermissions = $Permissions.Div
                        HtmlExclusions        = $ExclusionsDiv
                        HtmlFileList          = $FileList
                        ReportFooter          = $ReportFooter
                    }

                    if ($Permission.FlatPermissions) {

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody @BodyParams

                        $GroupBy = 'none'

                    } else {

                        # Combine the header and table inside a Bootstrap div
                        Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText '$SummaryTableHeader' -Content `$FormattedPermission.$Format`Group.Table"
                        $TableOfContents = New-BootstrapDivWithHeading -HeadingText $SummaryTableHeader -Content $PermissionGroupings.Table

                        # Combine all the elements into a single string which will be the innerHtml of the <body> element of the report
                        Write-LogMsg @LogParams -Text "Get-HtmlBody -TableOfContents `$TableOfContents -HtmlFolderPermissions `$FormattedPermission.$Format.Div"
                        $Body = Get-HtmlBody -TableOfContents $TableOfContents @BodyParams

                    }

                    # Build the JavaScript scripts
                    Write-LogMsg @LogParams -Text "ConvertTo-ScriptHtml -Permission `$Permissions -PermissionGrouping `$PermissionGroupings"
                    $ScriptHtml = ConvertTo-ScriptHtml -Permission $Permissions -PermissionGrouping $PermissionGroupings -GroupBy $GroupBy

                    # Apply the report template to the generated HTML report body and description
                    Write-LogMsg @LogParams -Text "New-BootstrapReport -JavaScript @ReportParameters"
                    New-BootstrapReport -JavaScript -AdditionalScriptHtml $ScriptHtml -Body $Body @ReportParameters

                }

                $DetailExports = @(
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                    { $Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile },
                    { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                    { <#$Report | ConvertTo-Json -Compress | Out-File -LiteralPath $ThisReportFile#> },
                    { $null = Set-Content -LiteralPath $ThisReportFile -Value $Report }
                )

                ForEach ($Level in $Detail) {

                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''
                    $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail`_$Format.htm"
                    $ReportFileList += $ThisReportFile

                    # Save the report
                    $Report = Invoke-Command -ScriptBlock $DetailScripts[$Level]
                    $null = Invoke-Command -ScriptBlock $DetailExports[$Level]

                    # Output the name of the report file to the Information stream
                    Write-Information $ThisReportFile

                    # Return the report file path of the highest level for the Interactive switch of Export-Permission
                    if ($Level -eq 10) {
                        $ThisReportFile
                    }

                }

            }

            'prtgxml' {

                # Output the full path of the XML file (result of the custom XML sensor for Paessler PRTG Network Monitor) to the Information stream
                #Write-Information $XmlFile

                # Save the XML file to disk
                #$null = Set-Content -LiteralPath $XmlFile -Value $XMLOutput

            }

            default {}

        }

    }

}
function Remove-CachedCimSession {

    param (

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{}))

    )

    ForEach ($CacheResult in $CimCache.Values) {

        if ($CacheResult) {

            $CimSession = $CacheResult['CimSession']

            if ($CimSession) {
                $null = Remove-CimSession -CimSession $CimSession
            }

        }

    }

}
function Resolve-AccessControlList {

    # Wrapper to multithread Resolve-Acl
    # Resolve identities in access control lists to their SIDs and NTAccount names

    param (

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Maximum number of concurrent threads to allow
        [int]$ThreadCount = (Get-CimInstance -ClassName CIM_Processor | Measure-Object -Sum -Property NumberOfLogicalProcessors).Sum,

        # Cache of access control entries keyed by GUID generated in this function
        [hashtable]$ACEsByGUID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [hashtable]$AceGUIDsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [hashtable]$AceGUIDsByPath = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    )

    $Progress = @{
        Activity = 'Resolve-AccessControlList'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }

    $Paths = $ACLsByPath.Keys
    $Count = $Paths.Count
    Write-Progress @Progress -Status "0% (ACL 0 of $Count)" -CurrentOperation 'Initializing' -PercentComplete 0

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $ACEPropertyName = (Get-Member -InputObject $ACLsByPath.Values.Access[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

    $ResolveAclParams = @{
        DirectoryEntryCache     = $DirectoryEntryCache
        DomainsBySID            = $DomainsBySID
        DomainsByNetbios        = $DomainsByNetbios
        DomainsByFqdn           = $DomainsByFqdn
        ThisHostName            = $ThisHostName
        ThisFqdn                = $ThisFqdn
        WhoAmI                  = $WhoAmI
        LogMsgCache             = $LogMsgCache
        CimCache                = $CimCache
        ACEsByGuid              = $ACEsByGUID
        AceGUIDsByPath          = $AceGUIDsByPath
        AceGUIDsByResolvedID    = $AceGUIDsByResolvedID
        ACLsByPath              = $ACLsByPath
        ACEPropertyName         = $ACEPropertyName
        InheritanceFlagResolved = $InheritanceFlagResolved
    }

    if ($ThreadCount -eq 1) {

        [int]$ProgressInterval = [math]::max(($Count / 100), 1)
        $IntervalCounter = 0
        $i = 0

        ForEach ($ThisPath in $Paths) {

            $IntervalCounter++

            if ($IntervalCounter -eq $ProgressInterval) {

                [int]$PercentComplete = $i / $Count * 100
                Write-Progress @Progress -Status "$PercentComplete% (ACL $($i + 1) of $Count) Resolve-Acl" -CurrentOperation $ThisPath -PercentComplete $PercentComplete
                $IntervalCounter = 0

            }

            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-LogMsg @LogParams -Text "Resolve-Acl -InputObject '$ThisPath' -ACLsByPath `$ACLsByPath -ACEsByGUID `$ACEsByGUID"
            Resolve-Acl -ItemPath $ThisPath @ResolveAclParams

        }

    } else {

        $SplitThreadParams = @{
            Command        = 'Resolve-Acl'
            InputObject    = $Paths
            InputParameter = 'ItemPath'
            TodaysHostname = $ThisHostname
            WhoAmI         = $WhoAmI
            LogMsgCache    = $LogMsgCache
            Threads        = $ThreadCount
            AddParam       = $ResolveAclParams
            #DebugOutputStream    = 'Debug'
        }

        Write-LogMsg @LogParams -Text "Split-Thread -Command 'Resolve-Acl' -InputParameter InputObject -InputObject @('$($ACLsByPath.Keys -join "','")') -AddParam @{ACLsByPath=`$ACLsByPath;ACEsByGUID=`$ACEsByGUID}"
        Split-Thread @SplitThreadParams

    }

    Write-Progress @Progress -Completed

}
function Resolve-Ace {
    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    Add these properties (IdentityReferenceSID,IdentityReferenceResolved) to the object and return it
    .INPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]$ACE
    .OUTPUTS
    [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceResolved, and AdsiProvider properties
    .EXAMPLE
    Get-Acl |
    Expand-Acl |
    Resolve-Ace

    Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
    This works in either Windows Powershell or in Powershell
    Get-Acl does not support long paths (>256 characters)
    That was why I originally used the .Net Framework method
    .EXAMPLE
    Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
    Resolve-Ace
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.SecurityIdentifier]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
    [System.Security.AccessControl.AccessControlSections]::Owner -bor
    [System.Security.AccessControl.AccessControlSections]::Group
    $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.NTAccount]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
    [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
    $AuthRules | Resolve-Ace

    Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
    Only works in Windows PowerShell
    Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
    This method is removed in modern versions of .Net Core

    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

    The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
    It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

    .NOTES
    Dependencies:
        Get-DirectoryEntry
        Add-SidInfo
        Get-TrustedDomain
        Find-AdsiProvider

    if ($FolderPath.Length -gt 255) {
        $FolderPath = "\\?\$FolderPath"
    }
#>
    [OutputType([void])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [object]$ACE,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        [Parameter(
            ValueFromPipeline
        )]
        [object]$ItemPath,

        # Cache of access control entries keyed by GUID generated in this function
        [hashtable]$ACEsByGUID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [hashtable]$AceGUIDsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [hashtable]$AceGUIDsByPath = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
    Hostname of the computer running this function.

    Can be provided as a string to avoid calls to HOSTNAME.EXE
    #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
    FQDN of the computer running this function.

    Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
    #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [string[]]$ACEPropertyName = (Get-Member -InputObject $ACE -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name,

        # Will be set as the Source property of the output object.
        # Intended to reflect permissions resulting from Ownership rather than Discretionary Access Lists
        [string]$Source,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $Log = @{
        ThisHostname = $ThisHostname
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $Cache1 = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
    }

    $Cache2 = @{
        DomainsByNetBIOS = $DomainsByNetbios
        DomainsBySid     = $DomainsBySid
        CimCache         = $CimCache
    }

    Write-LogMsg @LogParams -Text "Resolve-IdentityReferenceDomainDNS -IdentityReference '$($ACE.IdentityReference)' -ItemPath '$ItemPath' -ThisFqdn '$ThisFqdn' @Cache2 @Log"
    $DomainDNS = Resolve-IdentityReferenceDomainDNS -IdentityReference $ACE.IdentityReference -ItemPath $ItemPath -ThisFqdn $ThisFqdn @Cache2 @Log

    Write-LogMsg @LogParams -Text "`$AdsiServer = Get-AdsiServer -Fqdn '$DomainDNS' -ThisFqdn '$ThisFqdn'"
    $AdsiServer = Get-AdsiServer -Fqdn $DomainDNS -ThisFqdn $ThisFqdn @GetAdsiServerParams @Cache1 @Cache2 @Log

    Write-LogMsg @LogParams -Text "Resolve-IdentityReference -IdentityReference '$($ACE.IdentityReference)' -AdsiServer `$AdsiServer -ThisFqdn '$ThisFqdn' # ADSI server '$($AdsiServer.AdsiProvider)://$($AdsiServer.Dns)'"
    $ResolvedIdentityReference = Resolve-IdentityReference -IdentityReference $ACE.IdentityReference -AdsiServer $AdsiServer -ThisFqdn $ThisFqdn @Cache1 @Cache2 @Log

    # TODO: add a param to offer DNS instead of or in addition to NetBIOS

    $ObjectProperties = @{
        Access                    = "$($ACE.AccessControlType) $($ACE.FileSystemRights) $($InheritanceFlagResolved[$ACE.InheritanceFlags])"
        AdsiProvider              = $AdsiServer.AdsiProvider
        AdsiServer                = $AdsiServer.Dns
        IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
        IdentityReferenceResolved = $ResolvedIdentityReference.IdentityReferenceNetBios
        Path                      = $ItemPath
        SourceOfAccess            = $Source
        PSTypeName                = 'Permission.AccessControlEntry'
    }

    ForEach ($ThisProperty in $ACEPropertyName) {
        $ObjectProperties[$ThisProperty] = $ACE.$ThisProperty
    }

    $OutputObject = [PSCustomObject]$ObjectProperties
    $Guid = [guid]::NewGuid()
    Add-CacheItem -Cache $ACEsByGUID -Key $Guid -Value $OutputObject -Type ([object])
    $Type = [guid]
    Add-CacheItem -Cache $AceGUIDsByResolvedID -Key $OutputObject.IdentityReferenceResolved -Value $Guid -Type $Type
    Add-CacheItem -Cache $AceGUIDsByPath -Key $OutputObject.Path -Value $Guid -Type $Type

}
function Resolve-Acl {
    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it
    .INPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]$ItemPath
    .OUTPUTS
    [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
    .EXAMPLE
    Get-Acl |
    Expand-Acl |
    Resolve-Ace

    Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
    This works in either Windows Powershell or in Powershell
    Get-Acl does not support long paths (>256 characters)
    That was why I originally used the .Net Framework method
    .EXAMPLE
    Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
    Resolve-Ace
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.SecurityIdentifier]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
    [System.Security.AccessControl.AccessControlSections]::Owner -bor
    [System.Security.AccessControl.AccessControlSections]::Group
    $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.NTAccount]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
    [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
    $AuthRules | Resolve-Ace

    Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
    Only works in Windows PowerShell
    Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
    This method is removed in modern versions of .Net Core

    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

    The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
    It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

    .NOTES
    Dependencies:
        Get-DirectoryEntry
        Add-SidInfo
        Get-TrustedDomain
        Find-AdsiProvider

    if ($FolderPath.Length -gt 255) {
        $FolderPath = "\\?\$FolderPath"
    }
#>
    [OutputType([PSCustomObject])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [object]$ItemPath,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        # Cache of access control entries keyed by GUID generated in this function
        [hashtable]$ACEsByGUID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [hashtable]$AceGUIDsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [hashtable]$AceGUIDsByPath = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [string[]]$ACEPropertyName = (Get-Member -InputObject $ItemPath -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders', 'this folder and subfolders', 'this folder and files, but not subfolders', 'this folder, subfolders, and files')

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $ACL = $ACLsByPath[$ItemPath]

    if ($ACL.Owner.IdentityReference) {
        Write-LogMsg -Text "Resolve-Ace -ACE $($ACL.Owner) -ACEPropertyName @('$($ACEPropertyName -join "','")') @PSBoundParameters" @LogParams
        Resolve-Ace -ACE $ACL.Owner -Source 'Ownership' @PSBoundParameters
    }

    ForEach ($ACE in $ACL.Access) {
        Write-LogMsg -Text "Resolve-Ace -ACE $ACE -ACEPropertyName @('$($ACEPropertyName -join "','")') @PSBoundParameters" @LogParams
        Resolve-Ace -ACE $ACE -Source 'Discretionary ACL' @PSBoundParameters
    }

}
function Resolve-Folder {

    # Resolve the provided FolderPath to all of its associated UNC paths, including all DFS folder targets

    param (

        # Path of the folder(s) to resolve to all their associated UNC paths
        [string]$TargetPath,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputstream
        WhoAmI       = $WhoAmI
    }

    $LoggingParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    $RegEx = '^(?<DriveLetter>\w):'

    if ($TargetPath -match $RegEx) {

        Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName $ThisHostname -ClassName Win32_MappedLogicalDisk"
        $MappedNetworkDrives = Get-CachedCimInstance -ComputerName $ThisHostname -ClassName Win32_MappedLogicalDisk -KeyProperty DeviceID -CimCache $CimCache -ThisFqdn $ThisFqdn @LoggingParams

        $MatchingNetworkDrive = $MappedNetworkDrives |
        Where-Object -FilterScript { $_.DeviceID -eq "$($Matches.DriveLetter):" }

        if ($MatchingNetworkDrive) {
            # Resolve mapped network drives to their UNC path
            $UNC = $MatchingNetworkDrive.ProviderName
        } else {
            # Resolve local drive letters to their UNC paths using administrative shares
            $UNC = $TargetPath -replace $RegEx, "\\$(hostname)\$($Matches.DriveLetter)$"
        }

        if ($UNC) {
            # Replace hostname with FQDN in the path
            $Server = $UNC.split('\')[2]
            $FQDN = ConvertTo-DnsFqdn -ComputerName $Server
            $UNC -replace "^\\\\$Server\\", "\\$FQDN\"
        }

    } else {

        ## Workaround in place: Get-NetDfsEnum -Verbose parameter is not used due to errors when it is used with the PsRunspace module for multithreading
        ## https://github.com/IMJLA/Export-Permission/issues/46
        ## https://github.com/IMJLA/PsNtfs/issues/1
        Write-LogMsg @LogParams -Text "Get-NetDfsEnum -FolderPath '$TargetPath'"
        $AllDfs = Get-NetDfsEnum -FolderPath $TargetPath -ErrorAction SilentlyContinue

        if ($AllDfs) {

            $MatchingDfsEntryPaths = $AllDfs |
            Group-Object -Property DfsEntryPath |
            Where-Object -FilterScript {
                $TargetPath -match [regex]::Escape($_.Name)
            }

            # Filter out the DFS Namespace
            # TODO: I know this is an inefficient n2 algorithm, but my brain is fried...plez...halp...leeloo dallas multipass
            $RemainingDfsEntryPaths = $MatchingDfsEntryPaths |
            Where-Object -FilterScript {
                -not [bool]$(
                    ForEach ($ThisEntryPath in $MatchingDfsEntryPaths) {
                        if ($ThisEntryPath.Name -match "$([regex]::Escape("$($_.Name)")).+") { $true }
                    }
                )
            } |
            Sort-Object -Property Name

            $RemainingDfsEntryPaths |
            Select-Object -Last 1 -ExpandProperty Group |
            ForEach-Object {
                $_.FullOriginalQueryPath -replace [regex]::Escape($_.DfsEntryPath), $_.DfsTarget
            }

        } else {

            $Server = $TargetPath.split('\')[2]
            $FQDN = ConvertTo-DnsFqdn -ComputerName $Server
            $TargetPath -replace "^\\\\$Server\\", "\\$FQDN\"

        }

    }

}
function Resolve-FormatParameter {
    param (

        # File formats to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru'

    )

    $AllFormats = @{}

    ForEach ($Format in $FileFormat) {
        $AllFormats[$Format] = $null
    }

    if ($OutputFormat -ne 'passthru' -and $OutputFormat -ne 'none') {
        $AllFormats[$OutputFormat] = $null
    }

    return [string[]]$AllFormats.Keys

}
function Resolve-IdentityReferenceDomainDNS {

    param (

        [string]$IdentityReference,

        [object]$ItemPath,

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{}))

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    switch -Wildcard ($IdentityReference) {

        "S-1-*" {
            # IdentityReference is a SID (Revision 1)
            $IndexOfLastHyphen = $IdentityReference.LastIndexOf("-")
            $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)
            if ($DomainSid) {
                $DomainCacheResult = $DomainsBySID[$DomainSid]
                if ($DomainCacheResult) {
                    Write-LogMsg @LogParams -Text " # Domain SID cache hit for '$DomainSid' for '$IdentityReference'"
                    $DomainDNS = $DomainCacheResult.Dns
                } else {
                    Write-LogMsg @LogParams -Text " # Domain SID cache miss for '$DomainSid' for '$IdentityReference'"
                }
            }
        }
        "NT SERVICE\*" {}
        "BUILTIN\*" {}
        "NT AUTHORITY\*" {}
        default {
            $DomainNetBIOS = ($IdentityReference -split '\\')[0]
            if ($DomainNetBIOS) {
                $DomainDNS = $DomainsByNetbios[$DomainNetBIOS].Dns #Doesn't work for BUILTIN, etc.
            }
            if (-not $DomainDNS) {
                $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                $DomainDNS = ConvertTo-Fqdn -DistinguishedName $ThisServerDn -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
            }
        }
    }

    if (-not $DomainDNS) {
        # TODO - Bug: I think this will report incorrectly for a remote domain not in the cache (trust broken or something)
        Write-LogMsg @LogParams -Text "Find-ServerNameInPath -LiteralPath '$ItemPath' -ThisFqdn '$ThisFqdn'"
        $DomainDNS = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
    }

    return $DomainDNS

}
function Resolve-PermissionTarget {

    # Resolve each target path to all of its associated UNC paths (including all DFS folder targets)

    param (

        # Path to the NTFS folder whose permissions to export
        [Parameter(ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [System.IO.DirectoryInfo[]]$TargetPath,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        Type         = $DebugOutputstream
        WhoAmI       = $WhoAmI
    }

    $ResolveFolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        CimCache          = $CimCache
        ThisFqdn          = $ThisFqdn
    }

    ForEach ($ThisTargetPath in $TargetPath) {

        Write-LogMsg @LogParams -Text "Resolve-Folder -TargetPath '$ThisTargetPath'"
        $Resolved = Resolve-Folder -TargetPath $ThisTargetPath @ResolveFolderParams

        ForEach ($ThisOne in $Resolved) {
            $ACLsByPath[$ThisOne] = $null
        }

    }

}
function Select-UniquePrincipal {

    param (

        # Cache of security principals keyed by resolved identity reference
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Regular expressions matching names of Users or Groups to exclude from the Html report
        [string[]]$ExcludeAccount,

        <#
        Domain(s) to ignore (they will be removed from the username)

        Intended when a user has matching SamAccountNames in multiple domains but you only want them to appear once on the report.

        Can also be used to remove all domains simply for brevity in the report.
        #>
        [string[]]$IgnoreDomain,

        # Hashtable will be used to deduplicate
        $UniquePrincipal = [hashtable]::Synchronized(@{}),

        $UniquePrincipalsByResolvedID = [hashtable]::Synchronized(@{})

    )

    $FilterContents = @{}

    ForEach ($ThisID in $PrincipalsByResolvedID.Keys) {

        if (
            # Exclude the objects whose names match the regular expressions specified in the parameters
            [bool]$(
                ForEach ($RegEx in $ExcludeAccount) {
                    if ($ThisID -match $RegEx) {
                        $FilterContents[$ThisID] = $ThisID
                        $true
                    }
                }
            )
        ) { continue }

        $ShortName = $ThisID

        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $ShortName = $ShortName -replace "^$IgnoreThisDomain\\", ''
        }

        $ThisKnownUser = $null
        $ThisKnownUser = $UniquePrincipal[$ShortName]
        if ($null -eq $ThisKnownUser) {
            $UniquePrincipal[$ShortName] = [System.Collections.Generic.List[string]]::new()

        }

        $null = $UniquePrincipal[$ShortName].Add($ThisID)
        $UniquePrincipalsByResolvedID[$ThisID] = $ShortName

    }

}

# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

Export-ModuleMember -Function @('Add-CacheItem','ConvertTo-ItemBlock','Expand-Permission','Expand-PermissionTarget','Find-ResolvedIDsWithAccess','Format-Permission','Format-TimeSpan','Get-CachedCimInstance','Get-CachedCimSession','Get-FolderAcl','Get-FolderColumnJson','Get-FolderPermissionsBlock','Get-HtmlReportFooter','Get-PermissionPrincipal','Get-PrtgXmlSensorOutput','Get-TimeZoneName','Get-UniqueServerFqdn','Initialize-Cache','Invoke-PermissionCommand','Out-PermissionReport','Remove-CachedCimSession','Resolve-AccessControlList','Resolve-Ace','Resolve-Acl','Resolve-Folder','Resolve-FormatParameter','Resolve-IdentityReferenceDomainDNS','Resolve-PermissionTarget','Select-UniquePrincipal')


























































































































































































































































































































