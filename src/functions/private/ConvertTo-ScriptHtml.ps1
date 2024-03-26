function ConvertTo-ScriptHtml {

    param (
        $Permission,
        $PermissionGrouping,
        [string]$GroupBy
    )

    $ScriptHtmlBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Group in $Permission) {
        if (-not $Group.Columns) {
            pause
        }
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId "#$($Group.Table)" -ColumnJson $Group.Columns -DataJson $Group.Data))
    }

    if ($GroupBy -ne 'none') {
        if (-not $PermissionGrouping.Columns) {
            pause
        }
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId '#Folders' -ColumnJson $PermissionGrouping.Columns -DataJson $PermissionGrouping.Data))

    }

    return $ScriptHtmlBuilder.ToString()

}
