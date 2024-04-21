function Select-ItemTableProperty {

    # For the HTML table

    param (
        $InputObject,
        [cultureinfo]$Culture = (Get-Culture),
        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}) #Unused but exists here for parameter consistency with Select-AccountTableProperty and Select-PermissionTableProperty
    )

    ForEach ($Object in $InputObject) {

        $AccountNames = $ShortNameByID[$Object.Access.Account.ResolvedAccountName]

        if ($AccountNames) {

            $GroupString = $ShortNameByID[$Object.Access.Access.IdentityReferenceResolved]

            if ($GroupString) {

                [PSCustomObject]@{
                    Folder      = $Object.Item.Path
                    Inheritance = $Culture.TextInfo.ToTitleCase(-not $Object.Item.AreAccessRulesProtected)
                }

            }

        }

    }

}
