function Select-FolderPermissionTableProperty {
    # For the HTML table
    param (
        $InputObject,
        $IgnoreDomain
    )
    ForEach ($Object in $InputObject) {
        $GroupString = ($Object.Group.IdentityReference | Sort-Object -Unique) -join ' ; '
        # ToDo: param to allow setting [self] instead of the objects own name for this property
        #if ($GroupString -eq $Object.Name) {
        #    $GroupString = '[self]'
        #} else {
        ForEach ($IgnoreThisDomain in $IgnoreDomain) {
            $GroupString = $GroupString -replace "$IgnoreThisDomain\\", ''
        }
        #}
        [pscustomobject]@{
            'Account'              = $Object.Name
            'Access'               = ($Object.Group | Sort-Object -Property IdentityReference -Unique).Access -join ' ; '
            'Due to Membership In' = $GroupString
            'Source of Access'     = ($Object.Group.AccessControlEntry.ACESource | Sort-Object -Unique) -join ' ; '
            'Name'                 = @($Object.Group.Name)[0]
            'Department'           = @($Object.Group.Department)[0]
            'Title'                = @($Object.Group.Title)[0]
        }
    }

}
