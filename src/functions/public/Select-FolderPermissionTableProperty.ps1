function Select-FolderPermissionTableProperty {

    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain
    )

    ForEach ($Object in $InputObject) {

        # Each ACE contains the original IdentityReference representing the group the Object is a member of
        $GroupString = ($Object.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

        # ToDo: param to allow setting [self] instead of the objects own name for this property
        #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
        #    $GroupString = '[self]'
        #} else {
        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
        }
        #}

        [pscustomobject]@{
            'Account'              = $Object.Account.ResolvedAccountName
            'Access'               = ($Object.Access.Access | Sort-Object -Unique) -join ' ; '
            'Due to Membership In' = $GroupString
            'Source of Access'     = ($Object.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
            'Name'                 = $Object.Account.Name
            'Department'           = $Object.Account.Department
            'Title'                = $Object.Account.Title
        }

    }

}
