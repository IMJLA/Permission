function ConvertTo-FileList {

    param (
        [string[]]$Format,

        # Path to the folder to save the logs and reports generated by this script
        $OutputDir,

        $Culture = (Get-Culture)
    )

    ForEach ($ThisFormat in $Format) {

        # String translations indexed by value in the $Detail parameter
        # TODO: Move to i18n
        $DetailStrings = @(
            'Target paths',
            'Resolved target paths (server names and DFS targets resolved)'
            'Item paths (resolved target paths expanded into their children)',
            'Access lists',
            'Access rules (resolved identity references and inheritance flags)',
            'Accounts with access',
            'Expanded access rules (expanded with account info)', # #ToDo: Expand DirectoryEntry objects in the DirectoryEntry and Members properties
            'Formatted permissions',
            'Best Practice issues',
            'Custom sensor output for Paessler PRTG Network Monitor'
            'Permission report'
        )

        switch ($ThisFormat) {

            'csv' {

                ForEach ($Level in $Detail) {

                    # Get shorter versions of the detail strings to use in file names
                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                    # Convert the shorter strings to Title Case
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                    # Remove spaces from the shorter strings
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                    # Build the file path
                    "$OutputDir\$Level`_$SpacelessDetail.$ThisFormat"

                }

            }

            'html' {

                ForEach ($Level in $Detail) {

                    # Get shorter versions of the detail strings to use in file names
                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                    # Convert the shorter strings to Title Case
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                    # Remove spaces from the shorter strings
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                    # Build the file path
                    "$OutputDir\$Level`_$SpacelessDetail.htm"

                }

            }

            'json' {

                ForEach ($Level in $Detail) {

                    # Get shorter versions of the detail strings to use in file names
                    $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                    # Convert the shorter strings to Title Case
                    $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                    # Remove spaces from the shorter strings
                    $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                    # Build the file path
                    "$OutputDir\$Level`_$SpacelessDetail`_$ThisFormat.htm"

                }

            }

            'prtgxml' {

                $Level = 9

                # Get shorter versions of the detail strings to use in file names
                $ShortDetail = $DetailStrings[$Level] -replace '\([^\)]*\)', ''

                # Convert the shorter strings to Title Case
                $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

                # Remove spaces from the shorter strings
                $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

                # Build the file path
                "$OutputDir\$Level`_$SpacelessDetail`_$ThisFormat.xml"

            }

            default {}

        }

    }
}
