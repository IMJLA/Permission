function ConvertTo-FileListDiv {

    param (
        [hashtable]$FileList
    )

    #$StringBuilder = [System.Text.StringBuilder]::new()

    ForEach ($Format in $FileList.Keys) {

        $Files = $FileList[$Format]

        if ($Files) {

            #$Alert = New-BootstrapAlert -Text $Format -Class Dark -Padding ' pb-0 pt-2'
            #$StringBuilder.Append($Alert)
            New-BootstrapAlert -Text $Format -Class Dark -Padding ' pb-0 pt-2'

            #$HtmlList = $Files |
            $Files |
            Sort-Object |
            Split-Path -Leaf |
            ConvertTo-HtmlList |
            ConvertTo-BootstrapListGroup

            #$StringBuilder.Append($HtmlList)

        }

    }

    #$Div = $StringBuilder.ToString()
    #Write-Host "Type is $($Div.GetType().FullName) and Count is $($Div.Count)" -ForegroundColor Cyan
    #return $Div

}
