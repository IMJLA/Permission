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

        [string]$ShortestPath

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

    $Culture = Get-Culture

    Write-LogMsg @LogParams -Text "`$PermissionGroupingsWithChosenProperties = Select-ItemTableProperty -InputObject `$Selection -Culture '$Culture'"
    $PermissionGroupingsWithChosenProperties = Select-ItemTableProperty -InputObject $Selection -Culture $Culture

    $PermissionsWithChosenProperties = [hashtable]::Synchronized(@{})

    Write-LogMsg @LogParams -Text "Select-ItemPermissionTableProperty -InputObject `$Selection -IgnoreDomain '@('$($IgnoreDomain -join "','")')'"
    Select-ItemPermissionTableProperty -InputObject $Selection -IgnoreDomain $IgnoreDomain -OutputHash $PermissionsWithChosenProperties

    ForEach ($Format in $Formats) {

        $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -Culture $Culture

        $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties -PermissionGrouping $PermissionGroupingsWithChosenProperties -ShortestPath $ShortestPath

    }

    [PSCustomObject]$OutputProperties

}
