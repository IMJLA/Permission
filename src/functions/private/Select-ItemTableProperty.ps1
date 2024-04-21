function Select-ItemTableProperty {

    # For the HTML table

    param (
        $InputObject,
        [cultureinfo]$Culture = (Get-Culture),
        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}), #Unused but exists here for parameter consistency with Select-AccountTableProperty and Select-PermissionTableProperty
        [switch]$SkipFilterCheck
    )

    ForEach ($Object in $InputObject) {

        if (-not $SkipFilterCheck) {

            $AccountNames = $ShortNameByID[$Object.Access.Account.ResolvedAccountName]
            if (-not $AccountNames) { continue }
            $GroupString = $ShortNameByID[$Object.Access.Access.IdentityReferenceResolved]
            if (-not $GroupString) { continue }

        }

        [PSCustomObject]@{
            Folder      = $Object.Item.Path
            Inheritance = $Culture.TextInfo.ToTitleCase(-not $Object.Item.AreAccessRulesProtected)
        }

    }

}
