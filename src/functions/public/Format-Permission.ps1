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
    $SelectionProp = "$GroupBy`s"
    $GroupingScript = [scriptblock]::create("Select-$GroupBy`TableProperty -InputObject `$args[0] -Culture `$args[1]")

    ForEach ($Target in $Permission.TargetPermissions) {

        [PSCustomObject]@{
            Path   = $Target.Path
            Access = ForEach ($NetworkPath in $Target.NetworkPaths) {

                $Selection = $NetworkPath.$SelectionProp

                $OutputProperties = @{
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
