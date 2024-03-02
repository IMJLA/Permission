function Get-HtmlBody {

    param (
        $TableOfContents,
        $HtmlFolderPermissions,
        $ReportFooter,
        $HtmlFileList,
        $HtmlExclusions
    )

    $StringBuilder = [System.Text.StringBuilder]::new()

    if ($TableOfContents) {
        $null = $StringBuilder.Append((New-HtmlHeading "Folders with Permissions in This Report" -Level 3))
        $null = $StringBuilder.Append($TableOfContents)
        $null = $StringBuilder.Append((New-HtmlHeading "Accounts Included in Those Permissions" -Level 3))
    } else {
        $null = $StringBuilder.Append((New-HtmlHeading "Permissions" -Level 3))
    }

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
