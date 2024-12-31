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

        <#
        How to group the permissions in the output stream and within each exported file. Interacts with the SplitBy parameter:

        | SplitBy | GroupBy | Behavior |
        |---------|---------|----------|
        | none    | none    | 1 file with all permissions in a flat list |
        | none    | account | 1 file with all permissions grouped by account |
        | none    | item    | 1 file with all permissions grouped by item |
        | account | none    | 1 file per account; in each file, sort ACEs by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group ACEs by item and sort by item path |
        | item    | none    | 1 file per item; in each file, sort ACEs by account name |
        | item    | account | 1 file per item; in each file, group ACEs by account and sort by account name |
        | item    | item    | (same as -SplitBy item -GroupBy none) |
        | source  | none    | 1 file per source path; in each file, sort ACEs by source path |
        | source  | account | 1 file per source path; in each file, group ACEs by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group ACEs by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item',

        # File formats to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [String]$OutputFormat = 'passthru',

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report (left out: managedby)
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description'),

        # Object output from Invoke-PermissionAnalyzer
        [PSCustomObject]$Analysis

    )


    <#
    Information about the current culture settings.
    This includes information about the current language settings on the system, such as the keyboard layout, and the
    display format of items such as numbers, currency, and dates.
    #>
    $Culture = $Cache.Value['Culture'].Value
    $Progress = Get-PermissionProgress -Activity 'Format-Permission' -Cache $Cache
    $FormattedResults = @{}
    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat
    $Grouping = Resolve-GroupByParameter -GroupBy $GroupBy -HowToSplit $Permission.SplitBy
    $ShortNameByID = $Cache.Value['ShortNameByID']
    $ExcludeClassFilterContents = $Cache.Value['ExcludeClassFilterContents']
    $IncludeAccountFilterContents = $Cache.Value['IncludeAccountFilterContents']
    $ConvertSplat = @{ AccountProperty = $AccountProperty ; GroupBy = $GroupBy }

    if ($Permission.SplitBy['account']) {

        $i = 0
        $Count = $Permission.AccountPermissions.Count

        $FormattedResults['SplitByAccount'] = ForEach ($Account in $Permission.AccountPermissions) {

            [int]$Percent = $i / $Count * 100
            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-Progress -Status "$Percent% (Account $i of $Count)" -CurrentOperation $Account.Account.ResolvedAccountName -PercentComplete $Percent @Progress
            $Selection = $Account
            $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $Grouping['Script'] -ArgumentList $Selection, $Culture, $ShortNameByID, $IgnoreDomain, $IncludeAccountFilterContents, $ExcludeClassFilterContents
            $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -GroupBy $GroupBy -AccountProperty $AccountProperty -ShortNameById $ShortNameByID -IncludeAccountFilterContents $IncludeAccountFilterContents -ExcludeClassFilterContents $ExcludeClassFilterContents

            $OutputProperties = @{
                Account = $Account.Account
                Path    = $Account.Access.Item.Path
            }

            ForEach ($Format in $Formats) {

                $FormatString = $Format
                if ($Format -eq 'js') {
                    $FormatString = 'json'
                }

                $OutputProperties["$FormatString`Group"] = ConvertTo-PermissionGroup -Permission $PermissionGroupingsWithChosenProperties -Format $Format -HowToSplit $Permission.SplitBy @ConvertSplat
                $OutputProperties[$FormatString] = ConvertTo-PermissionList -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath @($Permission.SourcePermissions.NetworkPaths.Item.Path)[0] -HowToSplit $Permission.SplitBy -Format $Format @ConvertSplat

            }

            [PSCustomObject]$OutputProperties

        }

    }

    if ($Permission.SplitBy['item']) {

        $i = 0
        $Count = $Permission.ItemPermissions.Count

        $FormattedResults['SplitByItem'] = ForEach ($Item in $Permission.ItemPermissions) {

            [int]$Percent = $i / $Count * 100
            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-Progress -Status "$Percent% (Account $i of $Count)" -CurrentOperation $Item.Path -PercentComplete $Percent @Progress

            $Selection = $Item.Access
            $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $Grouping['Script'] -ArgumentList $Selection, $Culture, $IgnoreDomain, $IncludeAccountFilterContents, $ExcludeClassFilterContents
            $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -GroupBy $GroupBy -AccountProperty $AccountProperty -ShortNameById $ShortNameByID -IncludeAccountFilterContents $IncludeAccountFilterContents -ExcludeClassFilterContents $ExcludeClassFilterContents

            $OutputProperties = @{
                Item         = $Item.Item
                TargetPaths  = $Permission.SourcePermissions.Path.FullName
                NetworkPaths = $Permission.SourcePermissions.NetworkPaths.Item
            }

            ForEach ($Format in $Formats) {

                $FormatString = $Format
                if ($Format -eq 'js') {
                    $FormatString = 'json'
                }

                $OutputProperties["$FormatString`Group"] = ConvertTo-PermissionGroup -Permission $PermissionGroupingsWithChosenProperties -Format $Format -HowToSplit $Permission.SplitBy @ConvertSplat
                $OutputProperties[$FormatString] = ConvertTo-PermissionList -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath @($Permission.SourcePermissions.NetworkPaths.Item.Path)[0] -HowToSplit $Permission.SplitBy -Format $Format @ConvertSplat

            }

            [PSCustomObject]$OutputProperties

        }

    }

    if ($Permission.SplitBy['source']) {

        $i = 0
        $Count = $Permission.SourcePermissions.Count

        $FormattedResults['SplitBySource'] = ForEach ($Target in $Permission.SourcePermissions) {

            [int]$Percent = $i / $Count * 100
            $i++ # increment $i after Write-Progress to show progress conservatively rather than optimistically
            Write-Progress -Status "$Percent% (Account $i of $Count)" -CurrentOperation $Target.Path -PercentComplete $Percent @Progress

            [PSCustomObject]@{
                PSTypeName   = 'Permission.TargetPermission'
                Path         = $Target.Path
                NetworkPaths = ForEach ($NetworkPath in $Target.NetworkPaths) {

                    $Prop = $Grouping['Property']

                    if ($Prop -eq 'items') {

                        $Selection = [System.Collections.Generic.List[PSCustomObject]]::new()

                        # Add the network path itself
                        $Selection.Add([PSCustomObject]@{
                                PSTypeName = 'Permission.ItemPermission'
                                Item       = $NetworkPath.Item
                                Access     = $NetworkPath.Access
                            })

                        # Add child items
                        $ChildItems = [PSCustomObject[]]$NetworkPath.$Prop
                        if ($ChildItems) {
                            $Selection.AddRange($ChildItems)
                        }

                    } else {
                        $Selection = $NetworkPath.$Prop
                    }

                    $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $Grouping['Script'] -ArgumentList $Selection, $Culture, $ShortNameByID, $IncludeAccountFilterContents, $ExcludeClassFilterContents
                    $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -GroupBy $GroupBy -AccountProperty $AccountProperty -ShortNameById $ShortNameByID -IncludeAccountFilterContents $IncludeAccountFilterContents -ExcludeClassFilterContents $ExcludeClassFilterContents

                    $OutputProperties = @{
                        PSTypeName = "Permission.Parent$($Culture.TextInfo.ToTitleCase($GroupBy))Permission"
                        Item       = $NetworkPath.Item
                    }

                    ForEach ($Format in $Formats) {

                        $FormatString = $Format
                        if ($Format -eq 'js') {
                            $FormatString = 'json'
                        }

                        $OutputProperties["$FormatString`Group"] = ConvertTo-PermissionGroup -Permission $PermissionGroupingsWithChosenProperties -Format $Format -HowToSplit $Permission.SplitBy @ConvertSplat
                        $OutputProperties[$FormatString] = ConvertTo-PermissionList -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath $NetworkPath.Item.Path -HowToSplit $Permission.SplitBy -NetworkPath $NetworkPath.Item.Path -Analysis $Analysis -Format $Format @ConvertSplat

                    }

                    [PSCustomObject]$OutputProperties

                }

            }

        }

    }

    return $FormattedResults

}
