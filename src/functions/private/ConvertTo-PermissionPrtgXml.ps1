function ConvertTo-PermissionPrtgXml {

    param (
        [PSCustomObject]$Analysis
    )

    $IssuesDetected = $false

    # Group by item rather than by ACE
    # TODO: Do this for some of the other issue types
    $ItemsWithCreatorOwner = $Analysis.ACEsWithCreatorOwner.Path | Sort-Object -Unique

    # Count occurrences of each issue
    $CountItemsWithBrokenInheritance = $Analysis.ItemsWithBrokenInheritance.Count
    $CountACEsWithNonCompliantAccounts = $Analysis.ACEsWithNonCompliantAccounts.Count
    $CountACEsWithUsers = $Analysis.ACEsWithUsers.Count
    $CountACEsWithUnresolvedSIDs = $Analysis.ACEsWithUnresolvedSIDs.Count
    $CountItemsWithCreatorOwner = $ItemsWithCreatorOwner.Count

    # Use the counts to determine whether any issues occurred
    if (
        (
            $CountItemsWithBrokenInheritance +
            $CountACEsWithNonCompliantAccounts +
            $CountACEsWithUsers +
            $CountACEsWithUnresolvedSIDs +
            $CountItemsWithCreatorOwner
        ) -gt 0
    ) {
        $IssuesDetected = $true
    }

    $Channels = [System.Collections.Generic.List[String]]::new()

    # Build our XML output formatted for PRTG.
    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'Folders with inheritance disabled'
        Value      = $CountItemsWithBrokenInheritance
        CustomUnit = 'folders'
    }
    $null = $Channels.Add((Format-PrtgXmlResult @ChannelParams))

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for groups breaking naming convention'
        Value      = $CountACEsWithNonCompliantAccounts
        CustomUnit = 'ACEs'
    }
    $null = $Channels.Add((Format-PrtgXmlResult @ChannelParams))

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for users instead of groups'
        Value      = $CountACEsWithUsers
        CustomUnit = 'ACEs'
    }
    $null = $Channels.Add((Format-PrtgXmlResult @ChannelParams))

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = 'ACEs for unresolvable SIDs'
        Value      = $CountACEsWithUnresolvedSIDs
        CustomUnit = 'ACEs'
    }
    $null = $Channels.Add((Format-PrtgXmlResult @ChannelParams))

    $ChannelParams = @{
        MaxError   = 0.5
        Channel    = "Folders with 'CREATOR OWNER' access"
        Value      = $CountItemsWithCreatorOwner
        CustomUnit = 'folders'
    }
    $null = $Channels.Add((Format-PrtgXmlResult @ChannelParams))

    Format-PrtgXmlSensorOutput -PrtgXmlResult $Channels -IssueDetected:$IssuesDetected

}
