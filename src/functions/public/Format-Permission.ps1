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
        [ValidateSet('account', 'item', 'none', 'target')]
        [String]$GroupBy = 'item',

        # File formats to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [String]$OutputFormat = 'passthru',

        [cultureinfo]$Culture = (Get-Culture),

        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}),

        [Hashtable]$ExcludeClassFilterContents = @{},

        [Hashtable]$IncludeFilterContents = [Hashtable]::Synchronized(@{})

    )

    $FormattedResults = @{}
    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat
    $Grouping = Resolve-GroupByParameter -GroupBy $GroupBy -HowToSplit $Permission.SplitBy

    if ($Permission.SplitBy['account']) {

        $FormattedResults['SplitByAccount'] = ForEach ($Account in $Permission.AccountPermissions) {

            $Selection = $Account
            $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $Grouping['Script'] -ArgumentList $Selection, $Culture, $IgnoreDomain, $IncludeFilterContents, $ExcludeClassFilterContents
            $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -GroupBy $GroupBy -ShortNameById $ShortNameByID -IncludeFilterContents $IncludeFilterContents -ExcludeClassFilterContents $ExcludeClassFilterContents

            $OutputProperties = @{
                Account      = $Account.Account
                Path         = $Permission.TargetPermissions.Path.FullName
                NetworkPaths = $Permission.TargetPermissions.NetworkPaths.Item
                #passthru     = [PSCustomObject]@{
                #    'Data' = ForEach ($Value in $PermissionsWithChosenProperties.Values) { $Value }
                #}
            }

            ForEach ($Format in $Formats) {

                $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -GroupBy $GroupBy
                $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath @($Permission.TargetPermissions.NetworkPaths.Item.Path)[0] -GroupBy $GroupBy -HowToSplit $Permission.SplitBy

            }

            [PSCustomObject]$OutputProperties

        }

    }

    if ($Permission.SplitBy['item']) {

        $FormattedResults['SplitByItem'] = ForEach ($Item in $Permission.ItemPermissions) {

            $Selection = $Item.Access
            $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $Grouping['Script'] -ArgumentList $Selection, $Culture, $IgnoreDomain, $IncludeFilterContents, $ExcludeClassFilterContents
            $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -GroupBy $GroupBy -ShortNameById $ShortNameByID -IncludeFilterContents $IncludeFilterContents -ExcludeClassFilterContents $ExcludeClassFilterContents

            $OutputProperties = @{
                Item         = $Item.Item
                TargetPaths  = $Permission.TargetPermissions.Path.FullName
                NetworkPaths = $Permission.TargetPermissions.NetworkPaths.Item
                #passthru     = [PSCustomObject]@{
                #    'Data' = ForEach ($Value in $PermissionsWithChosenProperties.Values) { $Value }
                #}
            }

            ForEach ($Format in $Formats) {

                $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -GroupBy $GroupBy
                $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath @($Permission.TargetPermissions.NetworkPaths.Item.Path)[0] -GroupBy $GroupBy -HowToSplit $Permission.SplitBy

            }

            [PSCustomObject]$OutputProperties

        }

    }

    if ($Permission.SplitBy['target']) {

        $FormattedResults['SplitByTarget'] = ForEach ($Target in $Permission.TargetPermissions) {

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
                        $Selection.AddRange([PSCustomObject[]]$NetworkPath.$Prop)

                    } else {
                        $Selection = $NetworkPath.$Prop
                    }

                    $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $Grouping['Script'] -ArgumentList $Selection, $Culture, $ShortNameByID, $IncludeFilterContents, $ExcludeClassFilterContents
                    $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -GroupBy $GroupBy -ShortNameById $ShortNameByID -IncludeFilterContents $IncludeFilterContents -ExcludeClassFilterContents $ExcludeClassFilterContents

                    $OutputProperties = @{
                        PSTypeName = "Permission.Parent$($Culture.TextInfo.ToTitleCase($GroupBy))Permission"
                        Item       = $NetworkPath.Item
                    }

                    ForEach ($Format in $Formats) {

                        $FormatString = $Format
                        if ($Format -eq 'js') {
                            $FormatString = 'json'
                        }

                        $OutputProperties["$FormatString`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -GroupBy $GroupBy -HowToSplit $Permission.SplitBy
                        $OutputProperties[$FormatString] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath $NetworkPath.Item.Path -GroupBy $GroupBy -HowToSplit $Permission.SplitBy -NetworkPath $NetworkPath.Item.Path -Analysis $Analysis

                    }

                    [PSCustomObject]$OutputProperties

                }

            }

        }

    }

    return $FormattedResults

}
