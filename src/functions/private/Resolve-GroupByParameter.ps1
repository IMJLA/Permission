function Resolve-GroupByParameter {
    param (

        <#
        How to group the permissions in the output stream and within each exported file. Interacts with the SplitBy parameter:

        | SplitBy | GroupBy | Behavior |
        |---------|---------|----------|
        | none    | none    | 1 file with all permissions in a flat list |
        | none    | account | 1 file with all permissions grouped by account |
        | none    | item    | 1 file with all permissions grouped by item |
        | account | none    | 1 file per account; in each file, sort ACEs by item path |
        | account | account | (same as -SplitBy account -GroupBy none) |
        | account | item    | 1 file per account; in each file, group ACEs by item and sort by item path |
        | item    | none    | 1 file per item; in each file, sort ACEs by account name |
        | item    | account | 1 file per item; in each file, group ACEs by account and sort by account name |
        | item    | item    | (same as -SplitBy item -GroupBy none) |
        | source  | none    | 1 file per source path; in each file, sort ACEs by source path |
        | source  | account | 1 file per source path; in each file, group ACEs by account and sort by account name |
        | source  | item    | 1 file per source path; in each file, group ACEs by item and sort by item path |
        | source  | source  | (same as -SplitBy source -GroupBy none) |
        #>
        [ValidateSet('account', 'item', 'none', 'source')]
        [string]$GroupBy = 'item',

        [Hashtable]$HowToSplit

    )

    if (
        $GroupBy -eq 'none' -or
        $HowToSplit[$GroupBy]
    ) {

        return @{
            Property = 'Access'
            Script   = [scriptblock]::create("Select-PermissionTableProperty -InputObject `$args[0] -ShortNameById `$args[2] -IncludeAccountFilterContents `$args[3] -ExcludeClassFilterContents `$args[4] -GroupBy `$args[5] -AccountProperty `$args[6]")
        }

    } else {

        return @{
            Property = "$GroupBy`s"
            Script   = [scriptblock]::create("Select-$GroupBy`TableProperty -InputObject `$args[0] -Culture `$args[1] -ShortNameById `$args[2]")
        }

    }

}
