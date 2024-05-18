function Out-Permission {

    param (

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru',

        <#
        How to group the permissions in the output stream and within each exported file

            SplitBy	GroupBy
            none	none	$FlatPermissions all in 1 file
            none	account	$AccountPermissions all in 1 file
            none	item	$ItemPermissions all in 1 file

            account	none	1 file per item in $AccountPermissions.  In each file, $_.Access | sort path
            account	account	(same as -SplitBy account -GroupBy none)
            account	item	1 file per item in $AccountPermissions.  In each file, $_.Access | group item | sort name

            item	none	1 file per item in $ItemPermissions.  In each file, $_.Access | sort account
            item	account	1 file per item in $ItemPermissions.  In each file, $_.Access | group account | sort name
            item	item	(same as -SplitBy item -GroupBy none)

            target	none	1 file per $TargetPath.  In each file, sort ACEs by item path then account name
            target	account	1 file per $TargetPath.  In each file, group ACEs by account and sort by account name
            target	item	1 file per $TargetPath.  In each file, group ACEs by item and sort by item path
            target  target  (same as -SplitBy target -GroupBy none)
        #>
        [ValidateSet('account', 'item', 'none', 'target')]
        [string]$GroupBy = 'item',

        [hashtable]$FormattedPermission

    )
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

    #if ($Key -eq 'SplitByTarget' -and $GroupBy -eq 'item') {

    # Output the result to the pipeline
    ForEach ($Key in $FormattedPermission.Keys) {

        ForEach ($Target in $FormattedPermission[$Key]) {

            ForEach ($NetworkPath in $Target.NetworkPaths) {

                [PSCustomObject]@{
                    Parent     = $NetworkPath.Item
                    Children   = ForEach ($Permission in $NetworkPath.$OutputFormat) {

                        [PSCustomObject]@{
                            Item       = $Permission.Grouping
                            Access     = $Permission.$OutputFormat
                            PSTypeName = 'Permission.Item'
                        }

                    }

                    PSTypeName = 'Permission.Parent'

                }

            }

        }

    }

    #}


    if ($OutputFormat -eq 'PrtgXml') {
        # Output the XML so the script can be directly used as a PRTG sensor
        # Caution: This use may be a problem for a PRTG probe because of how long the script can run on large folders/domains
        # Recommendation: Specify the appropriate parameters to run this as a PRTG push sensor instead
        return $XMLOutput
    }

}
