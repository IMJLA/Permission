function ConvertTo-ScriptHtml {

    param (
        $Permission,
        $PermissionGrouping,
        [string]$GroupBy,
        [string]$Split
    )

    $ScriptHtmlBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Group in $Permission) {
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId "#$($Group.Table)" -ColumnJson $Group.Columns -DataJson $Group.Data))
    }

    if ($GroupBy -ne 'none' -and $GroupBy -ne $Split) {
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId '#Folders' -ColumnJson $PermissionGrouping.Columns -DataJson $PermissionGrouping.Data))

    }

    return $ScriptHtmlBuilder.ToString()

}
