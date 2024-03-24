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

    $Formats = Resolve-FormatParameter -FileFormat $FileFormat -OutputFormat $OutputFormat

    If ($Permission.SplitBy['none']) {

        switch ($GroupBy) {

            'account' {

                ForEach ($Target in $Permission.TargetPermissions) {

                    [PSCustomObject]@{
                        Path   = $Target.Path
                        Access = ForEach ($NetworkPath in $Target.NetworkPaths) {

                            $Selection = $NetworkPath.Accounts

                            $OutputProperties = @{
                                passthru = $Selection
                            }

                            $PermissionGroupingsWithChosenProperties = Select-AccountTableProperty -InputObject $Selection -Culture $Culture
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

            'item' {

                $Selection = $Permission.ItemPermissions

                $OutputProperties = @{
                    passthru = $Selection
                }

                $PermissionGroupingsWithChosenProperties = Select-ItemTableProperty -InputObject $Selection -Culture $Culture
                $PermissionsWithChosenProperties = Select-PermissionTableProperty -InputObject $Selection -IgnoreDomain $IgnoreDomain -GroupBy $GroupBy

                ForEach ($Format in $Formats) {

                    $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -Culture $Culture -GroupBy $GroupBy
                    $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $Selection -ShortestPath $ShortestPath -GroupBy $GroupBy

                }

                [PSCustomObject]$OutputProperties

            }

            'none' {
                $Selection = $Permission.FlatPermissions
            }

            'target' {
                $Selection = $Permission.TargetPermissions
            }

        }

    }

}
