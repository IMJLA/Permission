function ConvertTo-FileListDiv {

    param ([hashtable]$FileList)

    $StringBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Format in $FileList.Keys) {

        $Files = $FileList[$Format]

        if ($Files) {

            $Alert = New-BootstrapAlert -Text $Format -Class Dark -Padding ' pb-0 pt-2'
            $StringBuilder.Append($Alert)

            $HtmlList = $Files |
            Sort-Object |
            Split-Path -Leaf |
            ConvertTo-HtmlList |
            ConvertTo-BootstrapListGroup

            $StringBuilder.Append($HtmlList)
            $StringBuilder.ToString()

        }

    }

}
