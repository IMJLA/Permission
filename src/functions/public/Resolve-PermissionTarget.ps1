function Resolve-PermissionTarget {

    # Resolve each target path to all of its associated UNC paths (including all DFS folder targets)

    param (

        # Path to the NTFS folder whose permissions to export
        [System.IO.DirectoryInfo[]]$TargetPath,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Parents = $Cache.Value['ParentByTargetPath']

    ForEach ($ThisTargetPath in $TargetPath) {

        Write-LogMsg -Text "Resolve-Folder -TargetPath '$ThisTargetPath' -Cache `$Cache" -Cache $Cache
        $Parents.Value[$ThisTargetPath] = Resolve-Folder -TargetPath $ThisTargetPath -Cache $Cache

    }

}
