function Out-PermissionDetailReport {

    param (
        $Detail,
        $ReportObject,
        $DetailExport,
        $Format,
        $OutputDir,
        $Culture,
        $DetailString,
        $FileName,
        $FormatToReturn = 'json'
    )

    switch ($Format) {
        'csv' { $Suffix = '.csv' }
        'html' { $Suffix = "_$FileName.htm" }
        'js' { $Suffix = "_$Format`_$FileName.htm" }
        'json' { $Suffix = "_$Format`_$FileName.json" }
        'prtgxml' { $Suffix = '.xml' }
        'xml' { $Suffix = '.xml' }
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
        $null = Invoke-Command -ScriptBlock $DetailExport[$Level] -ArgumentList $Report

        # Output the name of the report file to the Information stream
        Write-Information $ThisReportFile

        # Return the report file path of the highest level for the Interactive switch of Export-Permission
        if ($Level -eq 10 -and $Format -eq $FormatToReturn) {
            $ThisReportFile
        }

    }

}
