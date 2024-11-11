function New-PermissionCache {

    $Boolean = [type]'String'
    $String = [type]'String'
    $GuidList = [type]'System.Collections.Generic.List[Guid]'
    $StringArray = [type]'String[]'
    $StringList = [type]'System.Collections.Generic.List[String]'
    $Object = [type]'Object'
    $PSCustomObject = [type]'PSCustomObject'
    $DirectoryInfo = [type]'System.IO.DirectoryInfo'
    $PSReference = [type]'ref'

    <#
    $CimCache
        Key is a String
        Value is a dict
            Key is a String
            Value varies (CimSession or dict)
#>
    return [hashtable]::Synchronized(@{
            AceByGUID                    = New-PermissionCacheRef -Key $String -Value $Object #hashtable Initialize a cache of access control entries keyed by GUID generated in Resolve-ACE.
            AceGuidByID                  = New-PermissionCacheRef -Key $String -Value $GuidList #hashtable Initialize a cache of access control entry GUIDs keyed by their resolved NTAccount captions.
            AceGuidByPath                = New-PermissionCacheRef -Key $String -Value $GuidList #hashtable Initialize a cache of access control entry GUIDs keyed by their paths.
            AclByPath                    = New-PermissionCacheRef -Key $String -Value $PSCustomObject #hashtable Initialize a cache of access control lists keyed by their paths.
            CimCache                     = New-PermissionCacheRef -Key $String -Value $PSReference #hashtable Initialize a cache of CIM sessions, instances, and query results.
            DirectoryEntryByPath         = New-PermissionCacheRef -Key $String -Value $Object #DirectoryEntryCache Initialize a cache of ADSI directory entry keyed by their Path to minimize ADSI queries.
            DomainBySID                  = New-PermissionCacheRef -Key $String -Value $Object #DomainsBySID Initialize a cache of directory domains keyed by domain SID to minimize CIM and ADSI queries.
            DomainByNetbios              = New-PermissionCacheRef -Key $String -Value $Object #DomainsByNetbios Initialize a cache of directory domains keyed by domain NetBIOS to minimize CIM and ADSI queries.
            DomainByFqdn                 = New-PermissionCacheRef -Key $String -Value $Object #DomainsByFqdn Initialize a cache of directory domains keyed by domain DNS FQDN to minimize CIM and ADSI queries.
            ExcludeAccountFilterContents = New-PermissionCacheRef -Key $String -Value $Boolean #hashtable Initialize a cache of accounts filtered by the ExcludeAccount parameter.
            ExcludeClassFilterContents   = New-PermissionCacheRef -Key $String -Value $Boolean #hashtable Initialize a cache of accounts filtered by the ExcludeClass parameter.
            IdByShortName                = New-PermissionCacheRef -Key $String -Value $StringList #hashtable Initialize a cache of resolved NTAccount captions keyed by their short names (results of the IgnoreDomain parameter).
            IncludeAccountFilterContents = New-PermissionCacheRef -Key $String -Value $Boolean #hashtable Initialize a cache of accounts filtered by the IncludeAccount parameter.
            LogBuffer                    = New-PermissionCacheRef -Key $String -Value $Object # Initialize a cache of log messages in memory to minimize random disk access.
            ParentByTargetPath           = New-PermissionCacheRef -Key $DirectoryInfo -Value $StringArray #ParentByTargetPath hashtable Initialize a cache of resolved parent item paths keyed by their unresolved target paths.
            PrincipalByID                = New-PermissionCacheRef -Key $String -Value $PSCustomObject #hashtable Initialize a cache of ADSI security principals keyed by their resolved NTAccount caption.
            ShortNameByID                = New-PermissionCacheRef -Key $String -Value $String  #hashtable Initialize a cache of short names (results of the IgnoreDomain parameter) keyed by their resolved NTAccount captions.
        })

}
