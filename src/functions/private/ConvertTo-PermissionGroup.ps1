function ConvertTo-PermissionGroup {
    [CmdletBinding()]
    param (

        # Permission object from Expand-Permission
        [PSCustomObject[]]$Permission,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [string]$Format,

        # How to group the permissions in the output stream and within each exported file
        [ValidateSet('account', 'item', 'none', 'target')]
        [string]$GroupBy = 'item',

        [string[]]$AccountProperty = @('Account', 'Name', 'DisplayName', 'Description', 'Department', 'Title'),

        [string[]]$ItemProperty = @('Folder', 'Inheritance'),

        [hashtable]$HowToSplit

    )

    $OutputObject = @{}

    if (
        $GroupBy -eq 'none' -or
        $HowToSplit[$GroupBy]
    ) {
        return
    }

    switch ($Format) {

        'csv' {
            $OutputObject['Data'] = $Permission | ConvertTo-Csv
            break
        }

        'html' {

            #Write-LogMsg @LogParams -Text "`$Permission | ConvertTo-Html -Fragment | New-BootstrapTable"
            $Html = $Permission | ConvertTo-Html -Fragment
            $OutputObject['Data'] = $Html
            $OutputObject['Table'] = $Html | New-BootstrapTable
            break

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
                    break
                }

                'item' {
                    $OrderedProperties = $ItemProperty
                    $JavaScriptTable['SearchableColumn'] = 'Folder'
                    $JavaScriptTable['DropdownColumn'] = 'Inheritance'
                    break
                }

            }

            # Wrap input in a array because output must be a JSON array for jquery to work properly.
            $OutputObject['Data'] = ConvertTo-Json -Compress -InputObject @($Permission)
            $OutputObject['Columns'] = Get-ColumnJson -InputObject $Permission -PropNames $OrderedProperties
            $OutputObject['Table'] = ConvertTo-BootstrapJavaScriptTable -InputObject $Permission -PropNames $OrderedProperties -DataFilterControl -PageSize 25 @JavaScriptTable
            break

        }

        'xml' {
            $OutputObject['Data'] = ($Permission | ConvertTo-Xml).InnerXml
            break
        }

        default {}

    }

    return [PSCustomObject]$OutputObject

}
