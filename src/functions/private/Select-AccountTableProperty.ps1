function Select-AccountTableProperty {

    # For the HTML table

    param (

        $InputObject,

        [cultureinfo]$Culture = (Get-Culture), #Unused but exists here for parameter consistency with Select-AccountTableProperty

        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}),

        # Properties of each Account to display on the report (left out: managedby)
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    ForEach ($Object in $InputObject) {

        $AccountName = $ShortNameByID[$Object.Account.ResolvedAccountName]

        if ($AccountName) {

            $Props = [ordered]@{
                Account     = $AccountName
                Name        = $Object.Account.Name
                DisplayName = $Object.Account.DisplayName
                Description = $Object.Account.Description
            }

            ForEach ($PropName in $AccountProperty) {
                $Props[$PropName] = $Object.Account.$PropName
            }

            [PSCustomObject]$Props

        }

    }

}
