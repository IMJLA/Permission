function Select-ItemTableProperty {

    # For the HTML table

    param (
        $InputObject,
        [cultureinfo]$Culture = (Get-Culture),
        [string[]]$IgnoreDomain #Unused but exists here for parameter consistency with Select-AccountTableProperty and Select-PermissionTableProperty
    )

    ForEach ($Object in $InputObject) {

        [PSCustomObject]@{
            Folder      = $Object.Item.Path
            Inheritance = $Culture.TextInfo.ToTitleCase(-not $Object.Item.AreAccessRulesProtected)
        }

    }

}
