function ConvertTo-FileListDiv {

    param ([hashtable]$FileList)

    $StringBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Format in $FileList.Keys) {

        $Alert = New-BootstrapAlert -Text $Format -Class Dark
        $StringBuilder.Append($Alert)

        $HtmlList = $FileList[$Format] |
        Sort-Object |
        Split-Path -Leaf |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $StringBuilder.Append($HtmlList)
        $StringBuilder.ToString()

    }

}
