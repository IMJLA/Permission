function Out-Permission {

    param (

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru',

        <#
        How to group the permissions in the output stream and within each exported file. Interacts with the SplitBy parameter:

        | SplitBy | GroupBy | Behavior |
        |---------|---------|----------|
        | none    | none    | 1 file with all permissions in a flat list |
        | none    | account | 1 file with all permissions grouped by account |
        | none    | item    | 1 file with all permissions grouped by item |
        | none    | source    | 1 file with all permissions grouped by source path |
        | account | none    | 1 file per account; in each file, sort permissions by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group permissions by item and sort by item path |
        | account | source  | 1 file per account; in each file, group permissions by source path and sort by item path |
        | source  | none    | 1 file per source path; in each file, sort permissions by item path |
        | source  | account | 1 file per source path; in each file, group permissions by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group permissions by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item',

        [hashtable]$FormattedPermission

    )

    ForEach ($Split in 'source', 'item', 'account') {
        $ThisFormat = $FormattedPermission["SplitBy$Split"]
        if ($ThisFormat) {
            $ThisFormat
        }
    }

    <#
    switch ($GroupBy) {
        'None' {
            $TypeData = @{
                TypeName                  = 'Permission.PassThruPermission'
                DefaultDisplayPropertySet = 'Folder', 'Account', 'Access'
                ErrorAction               = 'SilentlyContinue'
            }
            Update-TypeData @TypeData
            return $FolderPermissions
        }
        'Item' {
            Update-TypeData -MemberName Folder -Value { $This.Name } -TypeName 'Permission.FolderPermission' -MemberType ScriptProperty -ErrorAction SilentlyContinue
            Update-TypeData -MemberName Access -TypeName 'Permission.FolderPermission' -MemberType ScriptProperty -ErrorAction SilentlyContinue -Value {
                $Access = ForEach ($Permission in $This.Access) {
                    [pscustomobject]@{
                        Account = $Permission.Account
                        Access  = $Permission.Access
                    }
                }
                $Access
            }
            Update-TypeData -DefaultDisplayPropertySet ('Path', 'Access') -TypeName 'Permission.FolderPermission' -ErrorAction SilentlyContinue
            return $GroupedPermissions
        }
        'Account' {
            Update-TypeData -MemberName Account -Value { $This.Name } -TypeName 'Permission.AccountPermission' -MemberType ScriptProperty -ErrorAction SilentlyContinue
            Update-TypeData -MemberName Access -TypeName 'Permission.AccountPermission' -MemberType ScriptProperty -ErrorAction SilentlyContinue -Value {
                $Access = ForEach ($Permission in $This.Group) {
                    [pscustomobject]@{
                        Folder = $Permission.Folder
                        Access = $Permission.Access
                    }
                }
                $Access
            }
            Update-TypeData -DefaultDisplayPropertySet ('Account', 'Access') -TypeName 'Permission.AccountPermission' -ErrorAction SilentlyContinue

            #Group-Permission -InputObject $FolderPermissions -Property Account |
            #Sort-Object -Property Name
            return
        }
        Default { return }
    }
    #>
    <#
    # Output the result to the pipeline
    ForEach ($Key in $FormattedPermission.Keys) {

        ForEach ($Target in $FormattedPermission[$Key]) {

            ForEach ($NetworkPath in $Target.NetworkPaths) {

                [PSCustomObject]@{
                    PSTypeName = 'Permission.ParentItemPermission'
                    Item       = $NetworkPath.Item
                    Items      = ForEach ($Permission in $NetworkPath.$OutputFormat) {

                        [PSCustomObject]@{
                            Path       = $Permission.Grouping
                            Access     = $Permission.$OutputFormat
                            PSTypeName = 'Permission.Item'
                        }

                    }

                }

            }

        }

    }

    #>
    <#
    if ($OutputFormat -eq 'PrtgXml') {
        # Output the XML so the script can be directly used as a PRTG sensor
        # Caution: This use may be a problem for a PRTG probe because of how long the script can run on large folders/domains
        # Recommendation: Specify the appropriate parameters to run this as a PRTG push sensor instead
        return $XMLOutput
    }
    #>

}
