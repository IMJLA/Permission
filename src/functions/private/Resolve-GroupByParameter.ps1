function Resolve-GroupByParameter {
    param (

        # How to group the permissions in the output stream and within each exported file
        [ValidateSet('account', 'item', 'none', 'target')]
        [String]$GroupBy = 'item',

        [Hashtable]$HowToSplit

    )

    if (
        $GroupBy -eq 'none' -or
        $HowToSplit[$GroupBy]
    ) {

        return @{
            Property = 'Access'
            Script   = [scriptblock]::create("Select-PermissionTableProperty -InputObject `$args[0] -ShortNameById `$args[2]")
        }

    } else {

        return @{
            Property = "$GroupBy`s"
            Script   = [scriptblock]::create("Select-$GroupBy`TableProperty -InputObject `$args[0] -Culture `$args[1] -ShortNameById `$args[2]")
        }

    }

}
