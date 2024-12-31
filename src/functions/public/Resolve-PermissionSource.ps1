function Resolve-PermissionSource {

    # Resolve each source path to all of its associated UNC paths (including all DFS folder targets)

    param (

        # Path to the NTFS folder whose permissions to export
        [System.IO.DirectoryInfo[]]$SourcePath,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Parents = $Cache.Value['ParentBySourcePath']

    ForEach ($ThisSourcePath in $SourcePath) {

        Write-LogMsg -Text "Resolve-Folder -SourcePath '$ThisSourcePath' -Cache `$Cache" -Cache $Cache
        $Parents.Value[$ThisSourcePath] = Resolve-Folder -SourcePath $ThisSourcePath -Cache $Cache

    }

}
