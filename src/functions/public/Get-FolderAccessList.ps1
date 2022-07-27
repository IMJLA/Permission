function Get-FolderAccessList {
    <#
        .SYNOPSIS
        Get the access control entries for a folder and its subfolders
        .DESCRIPTION
        Wrapper for the Get-FolderAce function from the PsNtfs module
        .INPUTS
        [PSObject] InputObject parameter
        .OUTPUTS
        [PSObject]
        .EXAMPLE
        ----------  EXAMPLE 1  ----------
        This is a demo example with no parameters. It may not even be valid.

        Get-FolderAccessList
    #>
    [OutputType([PSObject[]])]
    [CmdletBinding()]
    param (

        # Comment-based help for $InputObject
        [Parameter(ValueFromPipeline)]
        [PSObject[]]$InputObject

    )
    begin {

    }
    process {
        ForEach ($ThisObject in $InputObject) {
            Write-Output $ThisObject
        }
    }
    end {

    }
}

