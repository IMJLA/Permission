function Get-HtmlBody {

    param (
        $NetworkPathDiv,
        $TableOfContents,
        $HtmlFolderPermissions,
        $ReportFooter,
        $HtmlFileList,
        $HtmlExclusions,
        $SummaryDivHeader,
        $DetailDivHeader
    )

    $StringBuilder = [System.Text.StringBuilder]::new()
    $null = $StringBuilder.Append((New-HtmlHeading 'Network Paths' -Level 5))
    $null = $StringBuilder.Append($NetworkPathDiv)

    if ($TableOfContents) {
        $null = $StringBuilder.Append((New-HtmlHeading $SummaryDivHeader -Level 6))
        $null = $StringBuilder.Append($TableOfContents)
    }

    $null = $StringBuilder.Append((New-HtmlHeading $DetailDivHeader -Level 5))

    ForEach ($Perm in $HtmlFolderPermissions) {
        $null = $StringBuilder.Append($Perm)
    }

    if ($HtmlExclusions) {
        $null = $StringBuilder.Append((New-HtmlHeading "Exclusions from This Report" -Level 5))
        $null = $StringBuilder.Append($HtmlExclusions)
    }

    $null = $StringBuilder.Append((New-HtmlHeading "Files Generated" -Level 5))
    $null = $StringBuilder.Append($HtmlFileList)
    $null = $StringBuilder.Append($ReportFooter)

    return $StringBuilder.ToString()

}
