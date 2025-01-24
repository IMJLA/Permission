function ConvertTo-FileListDiv {

    param (
        [Hashtable]$FileList
    )

    ForEach ($Format in ($FileList.Keys | Sort-Object)) {

        $Files = $FileList[$Format]

        if ($Files) {

            New-BootstrapAlert -Text $Format -Class Dark -Padding ' p-2 mb-0 mt-2'

            $Files |
            Sort-Object |
            Split-Path -Leaf |
            ConvertTo-HtmlList |
            ConvertTo-BootstrapListGroup

        }

    }

}
