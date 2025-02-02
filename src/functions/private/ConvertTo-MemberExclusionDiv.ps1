function ConvertTo-MemberExclusionDiv {

    param (

        <#
        Do not get group members (only report the groups themselves)

        Note: By default, the -ExcludeClass parameter will exclude groups from the report.
        If using -NoGroupMembers, you most likely want to modify the value of -ExcludeClass.
        Remove the 'group' class from ExcludeClass in order to see groups on the report.
        #>
        [switch]$NoMembers,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    if ($NoMembers) {

        $Content = 'Group members were excluded from the report.<br />Only accounts directly from the ACLs are included in the report.'

    } else {

        $Content = 'No accounts were excluded based on group membership.<br />Members of groups from the ACLs are included in the report.'

    }

    Write-LogMsg -Cache $Cache -ExpansionMap $Cache.Value['LogEmptyMap'].Value -Text "New-BootstrapDivWithHeading -HeadingText 'Group Members' -Content '$Content'"
    return New-BootstrapDivWithHeading -HeadingText 'Group Members' -Content $Content -HeadingLevel 6

}
