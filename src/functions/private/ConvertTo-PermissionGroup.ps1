function ConvertTo-PermissionGroup {
    [CmdletBinding()]
    param (

        # Permission object from Expand-Permission
        [PSCustomObject[]]$Permission,

        # Type of output returned to the output stream
        [ValidateSet('csv', 'html', 'js', 'json', 'prtgxml', 'xml')]
        [String]$Format,

        <#
        How to group the permissions in the output stream and within each exported file. Interacts with the SplitBy parameter:

        | SplitBy | GroupBy | Behavior |
        |---------|---------|----------|
        | none    | none    | 1 file with all permissions in a flat list |
        | none    | account | 1 file with all permissions grouped by account |
        | none    | item    | 1 file with all permissions grouped by item |
        | account | none    | 1 file per account; in each file, sort ACEs by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group ACEs by item and sort by item path |
        | item    | none    | 1 file per item; in each file, sort ACEs by account name |
        | item    | account | 1 file per item; in each file, group ACEs by account and sort by account name |
        | item    | item    | (same as -SplitBy item -GroupBy none) |
        | source  | none    | 1 file per source path; in each file, sort ACEs by source path |
        | source  | account | 1 file per source path; in each file, group ACEs by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group ACEs by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item',

        # Properties of each Account to display on the report (left out: managedby)
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description'),

        [string[]]$ItemProperty = @('Folder', 'Inheritance'),

        [Hashtable]$HowToSplit

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

            $Html = $Permission | ConvertTo-Html -Fragment
            $OutputObject['Data'] = $Html
            $OutputObject['Table'] = $Html | New-BootstrapTable
            break

        }

        'js' {

            #TODO: Change table id to "Groupings" instead of Folders to allow for Grouping by Account
            $JavaScriptTable = @{
                ID = 'Folders'
            }

            switch ($GroupBy) {

                'account' {
                    [string[]]$OrderedProperties = @('Account', 'Name') + $AccountProperty
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
