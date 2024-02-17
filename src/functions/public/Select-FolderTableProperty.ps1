function Select-ItemTableProperty {
    # For the HTML table
    param (
        $InputObject,
        $Culture = (Get-Culture)
    )
    [PSCustomObject]@{
        Path        = $InputObject.Item.Path
        Inheritance = $Culture.TextInfo.ToTitleCase(-not $InputObject.Item.AreAccessRulesProtected)
    }
}
