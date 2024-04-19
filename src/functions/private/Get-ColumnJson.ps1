function Get-ColumnJson {

    # For the JSON that will be used by JavaScript to generate the table
    param (
        $InputObject,
        [string[]]$PropNames,
        [Hashtable]$ColumnDefinition = @{
            'Inheritance' = @{
                'width' = '1'
            }
        }
    )

    if (-not $PSBoundParameters.ContainsKey('PropNames')) {
        $PropNames = (@($InputObject)[0] | Get-Member -MemberType noteproperty).Name
    }

    $Columns = ForEach ($Prop in $PropNames) {

        $Props = $ColumnDefinition[$Prop]

        if ($Props) {

            $Props['field'] = $Prop -replace '\s', ''
            $Props['title'] = $Prop

        } else {

            $Props = @{
                'field' = $Prop -replace '\s', ''
                'title' = $Prop
            }

        }

        [PSCustomObject]$Props
    }

    $Columns |
    ConvertTo-Json -Compress

}
