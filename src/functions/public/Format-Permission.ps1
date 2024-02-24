function Format-Permission {

    param (

        # Permission object from Expand-Permission
        [PSCustomObject]$Permission,

        # How to group the permissions in the output stream and within each exported file
        [ValidateSet('none', 'item', 'account')]
        [string]$GroupBy = 'item',

        # File formats to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru'

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

    Write-LogMsg @LogParams -Text "`$PermissionsWithChosenProperties = Select-ItemPermissionTableProperty -InputObject `$Selection -IgnoreDomain '@('$($IgnoreDomain -join "','")')'"
    $PermissionsWithChosenProperties = Select-ItemPermissionTableProperty -InputObject $Selection -IgnoreDomain $IgnoreDomain |
    Sort-Object -Property Account

    ForEach ($Format in $Formats) {

        $OutputProperties["$Format`Group"] = ConvertTo-PermissionGroup -Format $Format -Permission $PermissionGroupingsWithChosenProperties -Culture $Culture

        $OutputProperties[$Format] = ConvertTo-PermissionList -Format $Format -Permission $PermissionsWithChosenProperties

    }

    [PSCustomObject]$OutputProperties

}
