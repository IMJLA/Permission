function ConvertTo-PermissionGroup {

    param (

        # Permission object from Expand-Permission
        [PSCustomObject[]]$Permission,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$Format,

        <#
        Level of detail to export to file
            0   Item paths                                                                                  $TargetPath
            1   Resolved item paths (server names resolved, DFS targets resolved)                           $ACLsByPath.Keys after Resolve-PermissionTarget but before Expand-PermissionTarget
            2   Expanded resolved item paths (parent paths expanded into children)                          $ACLsByPath.Keys after Expand-PermissionTarget
            3   Access control entries                                                                      $ACLsByPath.Values after Get-FolderAcl
            4   Resolved access control entries                                                             $ACEsByGUID.Values
                                                                                                            $PrincipalsByResolvedID.Values
            5   Expanded resolved access control entries (expanded with info from ADSI security principals) $Permissions
            6   XML custom sensor output for Paessler PRTG Network Monitor
        #>
        [int[]]$Detail = @(0..6),

        [string]$GroupBy,

        [string[]]$AccountProperty = @('Account', 'Name', 'DisplayName', 'Description', 'Department', 'Title'),

        [string[]]$ItemProperty = @('Folder', 'Inheritance')

    )

    $OutputObject = @{}

    switch ($Format) {

        'csv' {
            $OutputObject['Data'] = $Permission | ConvertTo-Csv
        }

        'html' {

            #Write-LogMsg @LogParams -Text "`$Permission | ConvertTo-Html -Fragment | New-BootstrapTable"
            $Html = $Permission | ConvertTo-Html -Fragment
            $OutputObject['Data'] = $Html
            $OutputObject['Table'] = $Html | New-BootstrapTable

        }

        'json' {

            #TODO: Change table id to "Groupings" instead of Folders to allow for Grouping by Account
            $JavaScriptTable = @{
                ID = 'Folders'
            }

            switch ($GroupBy) {

                'account' {
                    $OrderedProperties = $AccountProperty
                    $JavaScriptTable['SearchableColumn'] = $OrderedProperties
                }

                'item' {
                    $OrderedProperties = $ItemProperty
                    $JavaScriptTable['SearchableColumn'] = 'Folder'
                    $JavaScriptTable['DropdownColumn'] = 'Inheritance'
                }

                'none' {}
                'target' {}

            }

            # Wrap input in a array because output must be a JSON array for jquery to work properly.
            $OutputObject['Data'] = ConvertTo-Json -Compress -InputObject @($Permission)
            $OutputObject['Columns'] = Get-ColumnJson -InputObject $Permission -PropNames $OrderedProperties

            #Write-LogMsg @LogParams -Text "ConvertTo-BootstrapJavaScriptTable -Id 'Folders' -InputObject `$Permission -DataFilterControl -SearchableColumn 'Folder' -DropdownColumn 'Inheritance'"
            $OutputObject['Table'] = ConvertTo-BootstrapJavaScriptTable -InputObject $Permission -PropNames $OrderedProperties -DataFilterControl -PageSize 25 @JavaScriptTable

        }

        'xml' {
            $OutputObject['Data'] = ($Permission | ConvertTo-Xml).InnerXml
        }

        default {}

    }

    return [PSCustomObject]$OutputObject

}
