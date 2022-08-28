function Update-CaptionCapitalization {
    param (
        [string]$ThisHostName,
        [hashtable]$Win32AccountsByCaption
    )
    $Win32AccountsByCaption.Keys |
    ForEach-Object {
        $Object = $Win32AccountsByCaption[$_]
        #$Win32AccountsByCaption.Remove($_)
        $NewKey = $_ -replace "^$ThisHostname\\$ThisHostname\\", "$ThisHostname\$ThisHostname\"
        $NewKey = $_ -replace "^$ThisHostname\\", "$ThisHostname\"
        Write-Host "Old Key: $_"
        Write-Host "New Key: $NewKey"
        #$Win32AccountsByCaption[$NewKey] = $Object
    }
}
