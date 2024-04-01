function Out-PermissionDetailReport {

    param (
        [int[]]$Detail,
        [hashtable]$ReportObject,
        [scriptblock[]]$DetailExport,
        [string]$Format,
        [string]$OutputDir,
        [cultureinfo]$Culture,
        [string[]]$DetailString,
        [string]$FileName,
        [string]$FormatToReturn = 'js',
        [int]$LevelToReturn = 10
    )

    switch ($Format) {
        'csv' { $Suffix = '.csv' ; break }
        'html' { $Suffix = "_$FileName.htm" ; break }
        'js' { $Suffix = "_$Format`_$FileName.htm" ; break }
        'json' { $Suffix = "_$Format`_$FileName.json" ; break }
        'prtgxml' { $Suffix = '.xml' ; break }
        'xml' { $Suffix = '.xml' ; break }
    }

    ForEach ($Level in $Detail) {

        # Get shorter versions of the detail strings to use in file names
        $ShortDetail = $DetailString[$Level] -replace '\([^\)]*\)', ''

        # Convert the shorter strings to Title Case
        $TitleCaseDetail = $Culture.TextInfo.ToTitleCase($ShortDetail)

        # Remove spaces from the shorter strings
        $SpacelessDetail = $TitleCaseDetail -replace '\s', ''

        # Build the file path
        $ThisReportFile = "$OutputDir\$Level`_$SpacelessDetail$Suffix"

        # Generate the report
        $Report = $ReportObject[$Level]

        # Save the report
        $null = Invoke-Command -ScriptBlock $DetailExport[$Level] -ArgumentList $Report, $ThisReportFile

        # Output the name of the report file to the Information stream
        Write-Information $ThisReportFile

        # Return the report file path of the highest level for the Interactive switch of Export-Permission
        if ($Level -eq $LevelToReturn -and $Format -eq $FormatToReturn) {
            $ThisReportFile
        }

    }

}
