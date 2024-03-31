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
        [string]$GroupBy = 'item',

        # File formats to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru',

        [string]$ShortestPath,

        [cultureinfo]$Culture = (Get-Culture)

    )

    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    if (
        $GroupBy -eq 'none' -or
        $Permission.SplitBy[$GroupBy]
    ) {

        $SelectionProp = 'Access'
        $GroupingScript = [scriptblock]::create("Select-PermissionTableProperty -InputObject `$args[0] -Culture `$args[1]")

    } else {

        $SelectionProp = "$GroupBy`s"
        $GroupingScript = [scriptblock]::create("Select-$GroupBy`TableProperty -InputObject `$args[0] -Culture `$args[1]")

    }

    $FormattedResults = @{}

    if ($Permission.SplitBy['account']) {

        $FormattedResults['SplitByAccount'] = ForEach ($Account in $Permission.AccountPermissions) {

            $Selection = $Account

            $OutputProperties = @{
                Account      = $Account.Account
                Path         = $Permission.TargetPermissions.Path.FullName
                NetworkPaths = $Permission.TargetPermissions.NetworkPaths.Item
                passthru     = $Selection
            }

            $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $GroupingScript -ArgumentList $Selection, $Culture
            $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -IgnoreDomain $IgnoreDomain -GroupBy $GroupBy

            ForEach ($Format in $Formats) {

                $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -Culture $Culture -GroupBy $GroupBy
                $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath $ShortestPath -GroupBy $GroupBy

            }

            [PSCustomObject]$OutputProperties

        }

    }

    if ($Permission.SplitBy['item']) {

        $FormattedResults['SplitByItem'] = ForEach ($Item in $Permission.ItemPermissions) {

            $Selection = $Item.Access

            $OutputProperties = @{
                Item         = $Item.Item
                TargetPaths  = $Permission.TargetPermissions.Path.FullName
                NetworkPaths = $Permission.TargetPermissions.NetworkPaths.Item
                passthru     = $Selection
            }

            $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $GroupingScript -ArgumentList $Selection, $Culture
            $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -IgnoreDomain $IgnoreDomain -GroupBy $GroupBy

            ForEach ($Format in $Formats) {

                $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -Culture $Culture -GroupBy $GroupBy
                $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath $ShortestPath -GroupBy $GroupBy

            }

            [PSCustomObject]$OutputProperties

        }

    }

    if ($Permission.SplitBy['none']) {

    }

    if ($Permission.SplitBy['target']) {

        $FormattedResults['SplitByTarget'] = ForEach ($Target in $Permission.TargetPermissions) {

            [PSCustomObject]@{
                Path         = $Target.Path
                NetworkPaths = ForEach ($NetworkPath in $Target.NetworkPaths) {

                    $Selection = $NetworkPath.$SelectionProp

                    $OutputProperties = @{
                        Item     = $NetworkPath.Item
                        passthru = $Selection
                    }

                    $PermissionGroupingsWithChosenProperties = Invoke-Command -ScriptBlock $GroupingScript -ArgumentList $Selection, $Culture
                    $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -IgnoreDomain $IgnoreDomain -GroupBy $GroupBy

                    ForEach ($Format in $Formats) {

                        $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -Culture $Culture -GroupBy $GroupBy
                        $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath $ShortestPath -GroupBy $GroupBy

                    }

                    [PSCustomObject]$OutputProperties

                }

            }

        }

    }

    return $FormattedResults

}
