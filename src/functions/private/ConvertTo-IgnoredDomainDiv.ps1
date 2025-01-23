function ConvertTo-IgnoredDomainDiv {

    param (

        <#
        Domain(s) to ignore (they will be removed from the username)

        Can be used:
        to ensure accounts only appear once on the report when they have matching SamAccountNames in multiple domains.
        when the domain is often the same and doesn't need to be displayed
        #>
        [string[]]$IgnoreDomain,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    if ($IgnoreDomain) {

        $ListGroup = $IgnoreDomain |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts from these domains are listed in the report without their domain.$ListGroup"

    } else {

        $Content = 'No domains were ignored.  All accounts have their domain listed.'

    }

    Write-LogMsg -Cache $Cache -ExpansionMap $Cache.Value['LogEmptyMap'].Value -Text "New-BootstrapDivWithHeading -HeadingText 'Domains Ignored by Name' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Domains Ignored by Name' -Content $Content -HeadingLevel 6

}
