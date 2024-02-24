function Select-ItemPermissionTableProperty {

    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain
    )

    ForEach ($Object in $InputObject) {

        ForEach ($ACE in $InputObject.Access) {

            # Each ACE contains the original IdentityReference representing the group the Object is a member of
            $GroupString = ($ACE.Access.IdentityReferenceResolved | Sort-Object -Unique) -join ' ; '

            # ToDo: param to allow setting [self] instead of the objects own name for this property
            #if ($GroupString -eq $Object.Account.ResolvedAccountName) {
            #    $GroupString = '[self]'
            #} else {
            ForEach ($IgnoreThisDomain in $IgnoreDomain) {
                $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
            }
            #}

            [pscustomobject]@{
                'Account'              = $ACE.Account.ResolvedAccountName
                'Access'               = ($ACE.Access.Access | Sort-Object -Unique) -join ' ; '
                'Due to Membership In' = $GroupString
                'Source of Access'     = ($ACE.Access.SourceOfAccess | Sort-Object -Unique) -join ' ; '
                'Name'                 = $ACE.Account.Name
                'Department'           = $ACE.Account.Department
                'Title'                = $ACE.Account.Title
            }

        }

    }

}
