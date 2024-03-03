function ConvertTo-IgnoredDomainDiv {

    param (

        <#
        Domain(s) to ignore (they will be removed from the username)

        Can be used:
        to ensure accounts only appear once on the report when they have matching SamAccountNames in multiple domains.
        when the domain is often the same and doesn't need to be displayed
        #>
        [string[]]$IgnoreDomain

    )

    if ($IgnoreDomain) {

        $ListGroup = $IgnoreDomain |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts from these domains are listed in the report without their domain.$ListGroup"

    } else {

        $Content = 'No domains were ignored.  All accounts have their domain listed.'

    }

    Write-LogMsg @LogParams -Text "New-BootstrapDivWithHeading -HeadingText 'Domains Ignored by Name' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Domains Ignored by Name' -Content $Content

}
