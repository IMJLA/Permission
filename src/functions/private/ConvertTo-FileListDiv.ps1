function ConvertTo-FileListDiv {

    param (
        [Hashtable]$FileList
    )

    $sb = [System.Text.StringBuilder]::new()
    $sb.AppendLine('<ul id="FileList">')

    ForEach ($Format in ($FileList.Keys | Sort-Object)) {

        $Files = $FileList[$Format]

        if ($Files) {

            $sb.AppendLine("<li><span class=`"caret`">$Format</span>")

            $List = $Files |
            Sort-Object |
            Split-Path -Leaf |
            ConvertTo-HtmlList -Class 'nested active'

            $sb.AppendLine($List)
            $sb.AppendLine('</li>')


        }

    }

    $sb.AppendLine('</ul>')
    $string = $sb.ToString()
    New-BootstrapDiv -Text $string

}
