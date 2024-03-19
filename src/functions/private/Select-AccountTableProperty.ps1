function Select-AccountTableProperty {

    # For the HTML table

    param (
        $InputObject
    )

    ForEach ($Object in $InputObject) {

        # This appears to be what determines the order of columns in the html report
        [PSCustomObject]@{
            Account     = $Object.Account.ResolvedAccountName
            Name        = $Object.Account.Name
            DisplayName = $Object.Account.DisplayName
            Description = $Object.Account.Description
            Department  = $Object.Account.Department
            Title       = $Object.Account.Title
        }

    }

}
