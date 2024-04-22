function Select-AccountTableProperty {

    # For the HTML table

    param (
        $InputObject,
        [cultureinfo]$Culture = (Get-Culture), #Unused but exists here for parameter consistency with Select-AccountTableProperty
        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{})
    )

    ForEach ($Object in $InputObject) {

        $AccountName = $ShortNameByID[$Object.Account.ResolvedAccountName]

        if ($AccountName) {

            #$GroupString = $ShortNameByID[$Object.Access.Access.IdentityReferenceResolved]

            #if ($GroupString) {

            # This appears to be what determines the order of columns in the html report
            [PSCustomObject]@{
                Account     = $AccountName
                Name        = $Object.Account.Name
                DisplayName = $Object.Account.DisplayName
                Description = $Object.Account.Description
                Department  = $Object.Account.Department
                Title       = $Object.Account.Title
            }

            #}

        }

    }

}
