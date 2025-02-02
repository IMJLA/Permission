function ConvertTo-ClassExclusionDiv {

    param (

        <#
        Accounts whose objectClass property is in this list are excluded from the HTML report

        Note on the 'group' class:
        By default, a group with members is replaced in the report by its members unless the -NoGroupMembers switch is used.
        Any remaining groups are empty and not useful to see in the middle of a list of users/job titles/departments/etc).
        So the 'group' class is excluded here by default.
        #>
        [string[]]$ExcludeClass,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    if ($ExcludeClass) {

        $ListGroup = $ExcludeClass |
        ConvertTo-HtmlList |
        ConvertTo-BootstrapListGroup

        $Content = "Accounts whose objectClass property is in this list were excluded from the report.$ListGroup"

    } else {

        $Content = 'No accounts were excluded based on objectClass.'

    }

    Write-LogMsg -Cache $Cache -ExpansionMap $Cache.Value['LogEmptyMap'].Value -Text "New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Class' -Content `$Content"
    return New-BootstrapDivWithHeading -HeadingText 'Accounts Excluded by Class' -Content $Content -HeadingLevel 6

}
