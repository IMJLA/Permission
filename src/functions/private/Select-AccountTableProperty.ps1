function Select-AccountTableProperty {

    # For the HTML table

    param (
        $InputObject,
        [string[]]$IgnoreDomain
    )

    ForEach ($Object in $InputObject) {

        $AccountName = $Object.Account.ResolvedAccountName

        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $AccountName = $AccountName.Replace("$IgnoreThisDomain\", '', 5)
        }

        # This appears to be what determines the order of columns in the html report
        [PSCustomObject]@{
            Account     = $AccountName
            Name        = $Object.Account.Name
            DisplayName = $Object.Account.DisplayName
            Description = $Object.Account.Description
            Department  = $Object.Account.Department
            Title       = $Object.Account.Title
        }

    }

}
