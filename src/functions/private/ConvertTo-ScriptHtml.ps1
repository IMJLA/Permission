function ConvertTo-ScriptHtml {

    param (
        $Permission,
        $PermissionGrouping
    )

    $ScriptHtmlBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Group in $Permission) {
        $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId "#$($Group.Table)" -ColumnJson $Group.Columns -DataJson $Group.Data))
    }

    $null = $ScriptHtmlBuilder.AppendLine((ConvertTo-BootstrapTableScript -TableId '#Folders' -ColumnJson $PermissionGrouping.Columns -DataJson $PermissionGrouping.Data))
    return $ScriptHtmlBuilder.ToString()

}
