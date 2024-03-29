function Select-ItemTableProperty {

    # For the HTML table

    param (
        $InputObject,
        $Culture = (Get-Culture)
    )

    ForEach ($Object in $InputObject) {

        [PSCustomObject]@{
            Folder      = $Object.Item.Path
            Inheritance = $Culture.TextInfo.ToTitleCase(-not $Object.Item.AreAccessRulesProtected)
        }

    }

}
