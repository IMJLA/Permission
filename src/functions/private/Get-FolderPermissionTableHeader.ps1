function Get-FolderPermissionTableHeader {
    [OutputType([System.String])]
    param (
        $Group,
        [string]$GroupID,
        [string]$ShortestFolderPath
    )
    $Parent = $GroupID | Split-Path -Parent
    $Leaf = $Parent | Split-Path -Leaf -ErrorAction SilentlyContinue
    if ($Leaf) {
        $ParentLeaf = $Leaf
    } else {
        $ParentLeaf = $Parent
    }
    if ('' -ne $ParentLeaf) {
        if ($Group.Item.AreAccessRulesProtected) {
            return "Inheritance is disabled on this folder. Accounts with access to the parent ($ParentLeaf) and its subfolders cannot access this folder unless they are listed here:"
        } else {
            if ($Group.Item.Path -eq $ShortestFolderPath) {
                return "Inherited permissions from the parent ($ParentLeaf) are included. This folder can only be accessed by the accounts listed here:"
            } else {
                return "Inheritance is enabled on this folder. Accounts with access to the parent ($ParentLeaf) and its subfolders can access this folder. So can the accounts listed here:"
            }
        }
    } else {
        return 'This is the top-level folder. It can only be accessed by the accounts listed here:'
    }
}
