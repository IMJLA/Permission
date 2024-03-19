function Select-AccountTableProperty {

    # For the HTML table

    param (
        $InputObject
    )

    ForEach ($Object in $InputObject) {

        [PSCustomObject]@{
            Account     = $Object.Account.ResolvedAccountName
            Department  = $Object.Account.Department
            Description = $Object.Account.Description
            DisplayName = $Object.Account.DisplayName
            Name        = $Object.Account.Name
            Title       = $Object.Account.Title
        }

    }

}
