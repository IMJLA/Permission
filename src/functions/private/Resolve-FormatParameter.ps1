function Resolve-FormatParameter {
    param (

        # File formats to export
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string[]]$FileFormat = @('csv', 'html', 'js', 'json', 'prtgxml', 'xml'),

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [String]$OutputFormat = 'passthru'

    )

    $AllFormats = @{}

    ForEach ($Format in $FileFormat) {
        $AllFormats[$Format] = $null
    }

    if ($OutputFormat -ne 'passthru' -and $OutputFormat -ne 'none') {
        $AllFormats[$OutputFormat] = $null
    }

    # Sort the results in descending order to ensure json comes before js.
    # This is because the js report uses the json formatted data
    # So, in Format-Permission, the objects in the output hashtable are formatted with json properties rather than js properties even for the js report format
    # However, ConvertTo-PermissionGroup/List are exclusive to js but not json reports so they output nothing for json
    # Having json run first means that the "nothing" results will then be overwritten by the valid json results
    $Sorted = [string[]]$AllFormats.Keys | Sort-Object -Descending

    return $Sorted

}
