function Get-FolderColumnJson {
    # For the JSON that will be used by JavaScript to generate the table
    param (
        $InputObject,
        [string[]]$PropNames
    )

    if (-not $PSBoundParameters.ContainsKey('PropNames')) {
        $PropNames = (@($InputObject)[0] | Get-Member -MemberType noteproperty).Name
    }

    $Columns = ForEach ($Prop in $PropNames) {
        $Props = @{
            'field' = $Prop -replace '\s', ''
            'title' = $Prop
        }
        if ($Prop -eq 'Inheritance') {
            $Props['width'] = '1'
        }
        [PSCustomObject]$Props
    }

    $Columns |
    ConvertTo-Json
}
