function ConvertTo-NameExclusionDiv {

    param (

        # Regular expressions matching names of security principals to exclude from the HTML report
        [string[]]$ExcludeAccount,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    if ($ExcludeAccount) {

        $ListGroup = $ExcludeAccount |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts whose names match these regular expressions were excluded from the report.$ListGroup"

    } else {

        $Content = 'No accounts were excluded based on name.'

    }

    Write-LogMsg -Cache $Cache -ExpansionMap $Cache.Value['LogEmptyMap'].Value -Text "New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Name' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Name' -Content $Content -HeadingLevel 6

}
