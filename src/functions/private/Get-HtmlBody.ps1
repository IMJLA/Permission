function Get-HtmlBody {

    param (
        $TableOfContents,
        $HtmlFolderPermissions,
        $ReportFooter,
        $HtmlFileList,
        $HtmlExclusions,
        $SummaryDivHeader,
        $DetailDivHeader
    )

    $StringBuilder = [System.Text.StringBuilder]::new()

    if ($TableOfContents) {
        $null = $StringBuilder.Append((New-HtmlHeading $SummaryDivHeader -Level 3))
        $null = $StringBuilder.Append($TableOfContents)
    }

    $null = $StringBuilder.Append((New-HtmlHeading $DetailDivHeader -Level 3))

    ForEach ($Perm in $HtmlFolderPermissions) {
        $null = $StringBuilder.Append($Perm)
    }

    if ($HtmlExclusions) {
        $null = $StringBuilder.Append((New-HtmlHeading "Exclusions from This Report" -Level 3))
        $null = $StringBuilder.Append($HtmlExclusions)
    }

    $null = $StringBuilder.Append((New-HtmlHeading "Files Generated" -Level 3))
    $null = $StringBuilder.Append($HtmlFileList)
    $null = $StringBuilder.Append($ReportFooter)

    return $StringBuilder.ToString()

}
