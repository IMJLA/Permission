function Get-FolderPermissionTableHeader {
    [OutputType([System.String])]
    param (
        $ThisFolder,
        [string]$ShortestFolderPath
    )
    $Leaf = $ThisFolder.Item.Path | Split-Path -Parent | Split-Path -Leaf -ErrorAction SilentlyContinue
    if ($Leaf) {
        $ParentLeaf = $Leaf
    } else {
        $ParentLeaf = $ThisFolder.Item.Path | Split-Path -Parent
    }
    if ('' -ne $ParentLeaf) {
        if ($InputObject.Item.AreAccessRulesProtected) {
            return "Inheritance is disabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) cannot access this folder unless they are listed below:"
        } else {
            if ($ThisFolder.Item.Path -eq $ShortestFolderPath) {
                return "Inherited permissions from the parent folder ($ParentLeaf) are included. This folder can only be accessed by the accounts listed below:"
            } else {
                return "Inheritance is enabled on this folder. Accounts with access to the parent folder and subfolders ($ParentLeaf) can access this folder. So can any accounts listed below:"
            }
        }
    } else {
        return "This is the top-level folder. It can only be accessed by the accounts listed below:"
    }
}
