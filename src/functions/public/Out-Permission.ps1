function Out-Permission {

    param (

        # Type of output returned to the output stream
        [ValidateSet('passthru', 'none', 'csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$OutputFormat = 'passthru',

        [hashtable]$FormattedPermission

    )

    <#
    switch ($OutputFormat) {
        'PassThru' {
            $TypeData = @{
                TypeName                  = 'Permission.PassThruPermission'
                DefaultDisplayPropertySet = 'Folder', 'Account', 'Access'
                ErrorAction               = 'SilentlyContinue'
            }
            Update-TypeData @TypeData
            return $FolderPermissions
        }
        'GroupByFolder' {
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
        'PrtgXml' {
            # Output the XML so the script can be directly used as a PRTG sensor
            # Caution: This use may be a problem for a PRTG probe because of how long the script can run on large folders/domains
            # Recommendation: Specify the appropriate parameters to run this as a PRTG push sensor instead
            return $XMLOutput
        }
        'GroupByAccount' {
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

    # Output the result to the pipeline
    ForEach ($Key in $FormattedPermission.Keys) {
        ForEach ($NetworkPath in $FormattedPermission[$Key].NetworkPaths) {
            [PSCustomObject]@{
                Parent   = $NetworkPath.Item
                Children = ForEach ($Permission in $NetworkPath.$OutputFormat) {
                    [PSCustomObject]@{
                        Item   = $Permission.Grouping
                        Access = $Permission.$OutputFormat
                    }
                }
                TypeName = 'Permission.ParentPermission'
            }
        }
    }

}
