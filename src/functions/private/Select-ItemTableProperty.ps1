function Select-ItemTableProperty {

    # This may appear unused but that is because the name of the function to call is generated dynamically e.g. Select-___TableProperty
    # For the HTML table

    param (
        $InputObject,
        [cultureinfo]$Culture = (Get-Culture),
        [Hashtable]$ShortNameByID = [Hashtable]::Synchronized(@{}), #Unused but exists here for parameter consistency with Select-AccountTableProperty and Select-PermissionTableProperty
        [switch]$SkipFilterCheck
    )

    ForEach ($Object in $InputObject) {

        if (-not $SkipFilterCheck) {

            if ($null -ne $Object.Account) {

                $ResolvedAccountName = $Object.Account.ResolvedAccountName
                $Item = $Object.Access.Item

            } else {

                # seems to vary based on splitby target vs account but I don't know why
                $ResolvedAccountName = $Object.Access.Account.ResolvedAccountName
                $Item = $Object.Item

            }

            $AccountNames = $ShortNameByID[$ResolvedAccountName]
            if (-not $AccountNames) { continue }
            $GroupString = $ShortNameByID[$Object.Access.Access.IdentityReferenceResolved]
            if (-not $GroupString) { continue }

        }

        [PSCustomObject]@{
            Folder      = $Item.Path
            Inheritance = $Culture.TextInfo.ToTitleCase(-not $Item.AreAccessRulesProtected)
        }

    }

}
