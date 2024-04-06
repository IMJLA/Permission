function ConvertTo-FileListDiv {

    param (
        [hashtable]$FileList
    )

    ForEach ($Format in $FileList.Keys) {

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
