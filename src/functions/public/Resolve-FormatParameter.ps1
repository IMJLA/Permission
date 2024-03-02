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
