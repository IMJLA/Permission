function Format-FolderPermission {

    <#
     Format the objects

     * SchemaClassName
     * Name,Dept,Title (TODO: Param to work with any specified props)
     * InheritanceFlags
     * Access Rights
    #>

    Param (

        # Expects ACEs grouped using Group-Object
        $UserPermission,

        # Ignore these FileSystemRights
        [string[]]$FileSystemRightsToIgnore = @('Synchronize'),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # ID of the parent progress bar under which to show progres
        [int]$ProgressParentId

    )

    $Progress = @{
        Activity = 'Format-FolderPermission'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $Progress['ParentId'] = $ProgressParentId
        $Progress['Id'] = $ProgressParentId + 1
    } else {
        $Progress['Id'] = 0
    }
    Write-Progress @Progress -Status '0% (step 1 of 1)' -CurrentOperation 'Initializing' -PercentComplete 0
    Start-Sleep -Seconds 5
    $i = 0
    $IntervalCounter = 0

    $Count = ($UserPermission | Measure-Object).Count
    [int]$ProgressInterval = [math]::max(($Count / 100), 1)

    ForEach ($ThisUser in $UserPermission) {

        $IntervalCounter++

        if ($IntervalCounter -eq $ProgressInterval) {

            [int]$PercentComplete = $i / $Count * 100
            Write-Progress @Progress -Status "$PercentComplete% (item $($i+1) of $Count)" -CurrentOperation "Formatting user permission group $($ThisUser.Name)" -PercentComplete $PercentComplete
            $IntervalCounter = 0

        }

        $i++

        if ($ThisUser.Group.DirectoryEntry.Properties) {

            if (

                (
                    $ThisUser.Group.DirectoryEntry |
                    ForEach-Object {
                        if ($null -ne $_) {
                            $_.GetType().FullName 2>$null
                        }
                    }
                ) -contains 'System.Management.Automation.PSCustomObject'

            ) {

                $Names = $ThisUser.Group.DirectoryEntry.Properties.Name
                $Depts = $ThisUser.Group.DirectoryEntry.Properties.Department
                $Titles = $ThisUser.Group.DirectoryEntry.Properties.Title

            } else {

                $Names = $ThisUser.Group.DirectoryEntry |
                ForEach-Object {
                    if ($_.Properties) {
                        $_.Properties['name']
                    }
                }

                $Depts = $ThisUser.Group.DirectoryEntry |
                ForEach-Object {
                    if ($_.Properties) {
                        $_.Properties['department']
                    }
                }

                $Titles = $ThisUser.Group.DirectoryEntry |
                ForEach-Object {
                    if ($_.Properties) {
                        $_.Properties['title']
                    }
                }

                if ($ThisUser.Group.DirectoryEntry.Properties['objectclass'] -contains 'group' -or
                    "$($ThisUser.Group.DirectoryEntry.Properties['groupType'])" -ne ''
                ) {
                    $SchemaClassName = 'group'
                } else {
                    $SchemaClassName = 'user'
                }

            }

            $Name = @($Names)[0]
            $Dept = @($Depts)[0]
            $Title = @($Titles)[0]

        } else {

            $Name = @($ThisUser.Group.name)[0]
            $Dept = @($ThisUser.Group.department)[0]
            $Title = @($ThisUser.Group.title)[0]

            if ($ThisUser.Group.Properties) {

                if (
                    $ThisUser.Group.Properties['objectclass'] -contains 'group' -or
                    "$($ThisUser.Group.Properties['groupType'])" -ne ''
                ) {
                    $SchemaClassName = 'group'
                } else {
                    $SchemaClassName = 'user'
                }

            } else {

                if ($ThisUser.Group.DirectoryEntry.SchemaClassName) {
                    $SchemaClassName = @($ThisUser.Group.DirectoryEntry.SchemaClassName)[0]
                } else {
                    $SchemaClassName = @($ThisUser.Group.SchemaClassName)[0]
                }

            }

        }

        if ("$Name" -eq '') {
            $Name = $ThisUser.Name
        }

        ForEach ($ThisACE in $ThisUser.Group) {

            switch ($ThisACE.ACEInheritanceFlags) {
                'ContainerInherit, ObjectInherit' { $Scope = 'this folder, subfolders, and files' }
                'ContainerInherit' { $Scope = 'this folder and subfolders' }
                'ObjectInherit' { $Scope = 'this folder and files, but not subfolders' }
                default { $Scope = 'this folder but not subfolders' }
            }

            if ($null -eq $ThisUser.Group.IdentityReference) {
                $IdentityReference = $null
            } else {
                $IdentityReference = $ThisACE.ACEIdentityReferenceResolved
            }

            $FileSystemRights = $ThisACE.ACEFileSystemRights
            ForEach ($Ignore in $FileSystemRightsToIgnore) {
                $FileSystemRights = $FileSystemRights -replace ", $Ignore\Z", '' -replace "$Ignore,", ''
            }

            [pscustomobject]@{
                Folder                   = $ThisACE.ACESourceAccessList.Path
                FolderInheritanceEnabled = !($ThisACE.ACESourceAccessList.AreAccessRulesProtected)
                Access                   = "$($ThisACE.ACEAccessControlType) $FileSystemRights $Scope"
                Account                  = $ThisUser.Name
                Name                     = $Name
                Department               = $Dept
                Title                    = $Title
                IdentityReference        = $IdentityReference
                AccessControlEntry       = $ThisACE
                SchemaClassName          = $SchemaClassName
            }

        }

    }

    Write-Progress @Progress -Completed
    Start-Sleep -Seconds 5

}
