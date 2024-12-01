function Get-PermissionProgress {

    param (
        [string]$Activity,
        [ref]$Cache
    )

    $Progress = @{
        Activity = $Activity
    }

    $ProgressParentId = $Cache.Value['ProgressParentId'].Value

    if ($null -ne $ProgressParentId) {

        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1

    } else {
        $Progress['Id'] = 0
    }

    return $Progress
}
