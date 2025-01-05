function Select-AccountTableProperty {

    # This may appear unused but that is because the name of the function to call is generated dynamically e.g. Select-___TableProperty
    # For the HTML table

    param (

        $InputObject,

        #Unused but exists here for parameter consistency with Select-AccountTableProperty
        [cultureinfo]$Culture = (Get-Culture),

        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}),

        # Properties of each Account to display on the report (left out: managedby)
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    ForEach ($Object in $InputObject) {

        $AccountName = $ShortNameByID[$Object.Account.ResolvedAccountName]

        if ($AccountName) {

            $Props = [ordered]@{
                Account = $AccountName
                Name    = $Object.Account.Name
            }

            ForEach ($PropName in $AccountProperty) {
                $Props[$PropName] = $Object.Account.$PropName
            }

            [PSCustomObject]$Props

        }

    }

}
