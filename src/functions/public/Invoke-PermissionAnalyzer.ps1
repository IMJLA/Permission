function Invoke-PermissionAnalyzer {

    param (

        # Each key is a path, each value is an ACL object.
        [hashtable]$AclByPath,

        # Each key is a string representing the path of an item allowed to have permissions inheritance disabled.  Values are irrelevant.
        [hashtable]$AllowDisabledInheritance,

        # Each key is an NTAccount caption, each value is an account object.
        [hashtable]$PrincipalByID,

        <#
        Valid accounts that are allowed to appear in ACEs

        Specify as a ScriptBlock meant for the FilterScript parameter of Where-Object

        By default, this is a ScriptBlock that always evaluates to $true so it doesn't evaluate any account convention compliance

        In the ScriptBlock, any account properties are available for evaluation:

        e.g. {$_.DomainNetbios -eq 'CONTOSO'} # Accounts used in ACEs should be in the CONTOSO domain
        e.g. {$_.Name -eq 'Group23'} # Accounts used in ACEs should be named Group23
        e.g. {$_.ResolvedAccountName -like 'CONTOSO\Group1*' -or $_.ResolvedAccountName -eq 'CONTOSO\Group23'}

        The format of the ResolvedAccountName property is CONTOSO\Group1
        where
            CONTOSO is the NetBIOS name of the domain (the computer name for local accounts)
            and
            Group1 is the samAccountName of the account
        #>
        [scriptblock]$AccountConvention = { $true }

    )

    <#
    Issue:
        Items with permissions inheritance disabled
    Explanation: Disabling inheritance adds complexity to management of permissions, leading to unexpected behavior.
        Example:    1st ticket - Grant access to folder1 and all of its contents
                    2nd ticket - Unable to access folder1\subfolder1 (oops, nobody knew subfolder1 had inheritance disabled)
    Recommended: Enable inheritance. To achieve the desired behavior, consider these alternatives in order of preference:
        1. Modify ACE inheritance and propagation flags (instead of ACL inheritance).
        2. Move folders up higher in the folder structure if they require access not achievable with inheritance and propagation flags.
        Example:    Ticket - Grant access to folder1 but none of its subfolders
                    Not Recommended - Disabling inheritance of all ACEs on all subfolders of folder1
                    Recommended - The ACE on folder1 which grants access should have the flags set to TODO VERIFY CORRECT CONFIG, BELOW ALL SETTINGS ARE LISTED INSTEAD:
                      Propagation flags:
                        0 (None) No inheritance flags are set.
                        1 (NoPropagateInherit) ACE is not propagated to child objects.
                        2 (InheritOnly) ACE is propagated only to child objects. This includes both container and leaf child objects.
                      Inheritance flags:
                        0 (None) ACE is inherited by child container objects.
                        1 (ContainerInherit) ACE is inherited by child container objects.
                        2 (ObjectInherit) ACE is inherited by child leaf objects.

                        This ensures the new access will not propagate to any subfolders of folder 1, without disrupting ACL inheritance.
    #>
    $ItemsWithBrokenInheritance = $AclByPath.Keys |
    Where-Object -FilterScript {
        $AclByPath[$_].AreAccessRulesProtected #-and
        -not $AllowDisabledInheritance[$_]
    }

    # Groups that were used in ACEs but do not match the specified naming convention
    # Invert the naming convention scriptblock (because we actually want to identify groups that do NOT follow the convention)
    $ViolatesAccountConvention = [scriptblock]::Create("!($AccountConvention)")
    $NonCompliantAccounts = $PrincipalByID.Values |
    Where-Object -FilterScript { $_.SchemaClassName -eq 'Group' } |
    Where-Object -FilterScript $ViolatesAccountConvention
    if ($NonCompliantAccounts) {
        $AceGUIDsWithNonCompliantAccounts = $AceGuidByID[$NonCompliantAccounts]
    }
    if ($AceGUIDsWithNonCompliantAccounts) {
        $ACEsWithNonCompliantAccounts = $AceByGUID[$AceGUIDsWithNonCompliantAccounts]
    }

    $ACEsWithUsers = [System.Collections.Generic.List[PSCustomObject]]::new()
    $ACEsWithUnresolvedSIDs = [System.Collections.Generic.List[PSCustomObject]]::new()
    $ACEsWithCreatorOwner = [System.Collections.Generic.List[PSCustomObject]]::new()

    ForEach ($ACE in $AceByGUID.Values) {

        # ACEs for users (recommend replacing with group-based access on any folder that is not a home folder)
        if (
            $PrincipalByID[$ACE.IdentityReferenceResolved].SchemaClassName -eq 'User' -and
            $_.IdentityReferenceSID -ne 'S-1-5-18' -and # The 'NT AUTHORITY\SYSTEM' account is part of default Windows file permissions and is out of scope
            $_.SourceOfAccess -ne 'Ownership' # Currently Ownership is out of scope.  Should it be?
        ) {
            $ACEsWithUsers.Add($ACE)
        }

        # ACEs for unresolvable SIDs (recommend removing these ACEs)
        if ( $_.IdentityReferenceResolved -like "*$($_.IdentityReferenceSID)*" ) {
            $ACEsWithUnresolvedSIDs.Add($ACE)
        }

        # CREATOR OWNER access (recommend replacing with group-based access, or with explicit user access for a home folder.)
        if ( $_.IdentityReferenceResolved -match 'CREATOR OWNER' ) {
            $ACEsWithCreatorOwner.Add($ACE)
        }

    }

    return [PSCustomObject]@{
        ACEsWithCreatorOwner         = $ACEsWithCreatorOwner
        ACEsWithNonCompliantAccounts = $ACEsWithNonCompliantAccounts
        ACEsWithUsers                = $ACEsWithUsers
        ACEsWithUnresolvedSIDs       = $ACEsWithUnresolvedSIDs
        ItemsWithBrokenInheritance   = $ItemsWithBrokenInheritance
        NonCompliantAccounts         = $NonCompliantAccounts
    }

}
