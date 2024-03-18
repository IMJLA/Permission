function Select-AccountTableProperty {

    # For the HTML table

    param (
        $InputObject
    )

    ForEach ($Object in $InputObject) {

        [PSCustomObject]@{
            Account     = $Object.Account.ResolvedAccountName
            DisplayName = $Object.Account.DisplayName
            Name        = $Object.Account.Name
            Department  = $Object.Account.Department
            Title       = $Object.Account.Title
        }

    }

}
