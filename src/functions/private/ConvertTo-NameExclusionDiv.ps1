function ConvertTo-NameExclusionDiv {

    param (

        # Regular expressions matching names of security principals to exclude from the HTML report
        [string[]]$ExcludeAccount

    )

    if ($ExcludeAccount) {

        $ListGroup = $ExcludeAccount |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts matching these regular expressions were excluded from the report.$ListGroup"

    } else {

        $Content = 'No accounts were excluded based on name.'

    }

    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Name' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Name' -Content $Content

}
