# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.0.97] - 2024-02-02 - nested prog bars and efficiency improvement

## [0.0.96] - 2024-02-02 - bugfix progress bar gap

## [0.0.95] - 2024-02-02 - fixed progress in expand-folder

## [0.0.94] - 2024-02-02 - slow down expand-folder for viewing progress

## [0.0.93] - 2024-02-02 - butfix thishostname vs todayshostname param expandfolder

## [0.0.92] - 2024-02-02 - add identityreferencecache param to expand-permissionidentity

## [0.0.91] - 2024-02-02 - add debugoutputstream param to expand-identityreference

## [0.0.90] - 2024-02-02 - undo troubleshoot expand-permissionidentity (confirmed bug is in expand-identityreference)

## [0.0.89] - 2024-02-02 - troubleshoot expand-permissionidentity

## [0.0.88] - 2024-02-02 - bugfix export-resolvedpermissioncsv literalpath

## [0.0.87] - 2024-02-02 - bugfix Type vs DebugOutputStream as param for Write-LogMsg calls

## [0.0.86] - 2024-02-02 - added functionality from controller script export-permission.ps1

## [0.0.85] - 2024-02-02 - added functionality from controller script export-permission.ps1

## [0.0.84] - 2024-02-02 - added functionality from controller script export-permission.ps1

## [0.0.83] - 2024-02-02 - added functionality from controller script export-permission.ps1

## [0.0.82] - 2024-02-02 - added functionality from controller script export-permission.ps1

## [0.0.81] - 2024-01-31 - bugfix get-folderaccesslist

## [0.0.80] - 2024-01-31 - bugfix get-folderaccesslist

## [0.0.79] - 2024-01-31 - bug get-folderace in get-folderaccesslist

## [0.0.78] - 2024-01-31 - bug get-folderace in get-folderaccesslist

## [0.0.77] - 2024-01-31 - troubleshooting bug in get-folderace

## [0.0.76] - 2024-01-28 - reduce calls to external executables

## [0.0.75] - 2024-01-28 - add progress to single threaded Get-FolderAccessList mode

## [0.0.74] - 2024-01-28 - bugfix Get-FolderAccessList progress percentage

## [0.0.73] - 2024-01-27 - shortened param names

## [0.0.72] - 2024-01-21 - https://github.com/IMJLA/Export-Permission/issues/61

## [0.0.71] - 2024-01-21 - enhancement-performance remove usage of select-object -first

## [0.0.70] - 2024-01-21 - housekeeping Get-FolderPermissionsBlock

## [0.0.69] - 2024-01-20 - bugfix case sensitive Get-FolderPermissionsBlock

## [0.0.68] - 2024-01-20 - housekeeping removed test.ps1

## [0.0.67] - 2024-01-20 - add -AsArray to ConvertTo-Json to bugfix single results (must be js array to appear as row in table)

## [0.0.66] - 2024-01-20 - bugfix owner feature in get-folderaccesslist

## [0.0.65] - 2024-01-20 - integrate Get-OwnerAce in get-folderaccesslist

## [0.0.64] - 2024-01-20 - integrate Get-OwnerAce in get-folderaccesslist

## [0.0.63] - 2024-01-15 - bugfix for object filtering in Get-FolderPermissionsBlock

## [0.0.62] - 2024-01-15 - bugfix for object filtering in Get-FolderPermissionsBlock

## [0.0.61] - 2024-01-14 - minor verbiage update in html report by export-folderpermissionhtml

## [0.0.60] - 2024-01-14 - bug fix in classexclusions dictionary construction in get-folderpermissionsblock

## [0.0.59] - 2024-01-14 - bugfix dictionary index was incorrect Get-FolderPermissionBlock ln26

## [0.0.58] - 2024-01-14 - implemented ExcludeAccountClass param and deprecated ExcludeEmptyGroups switch

## [0.0.57] - 2024-01-13 - bugfix in export-folderpermissionhtml with default report file name (should no longer include json in name by default)

## [0.0.56] - 2024-01-13 - bugfix with list of report files after modifying defualt behavior last version

## [0.0.55] - 2024-01-13 - testing cicd pipeline

## [0.0.54] - 2024-01-13 - testing cicd pipeline

## [0.0.53] - 2024-01-13 - breaking change; Export-FolderPermissionHtml will no longer save a file with the JavaScript-less Html by default, unless the new -NoJavaScript switch parameter is used

## [0.0.52] - 2024-01-13 - breaking change; default behavior of Export-FolderPermissionHtml will no longer generate javascript-less html file by default but this behavior is available with a new -NoJavaScript switch parameter

## [0.0.51] - 2022-09-18 - Added feature to specify json column order get-foldercolumnjson

## [0.0.50] - 2022-09-18 - bugfix to keep columns in desired order in get-folderpermissionblock

## [0.0.49] - 2022-09-18 - javascript bugfixes again

## [0.0.48] - 2022-09-18 - javascript bugfixes

## [0.0.47] - 2022-09-18 - Added script generation for folders table

## [0.0.46] - 2022-09-18 - bugfix should not have pound sign when setting table id

## [0.0.45] - 2022-09-17 - troubleshooting

## [0.0.44] - 2022-09-17 - Added debug output

## [0.0.43] - 2022-09-17 - troubleshoot cast scripthtml as string

## [0.0.42] - 2022-09-17 - Implemented Json conversion

## [0.0.41] - 2022-09-17 - updated export-folderpermissionhtml to use json template with included javascript

## [0.0.40] - 2022-09-11 - added feature, now saving json version of report (still incomplete)

## [0.0.39] - 2022-09-11 - bugfix select-foldertableproperty oopsies

## [0.0.38] - 2022-09-11 - updates

## [0.0.37] - 2022-09-05 - bugfix in get-htmlreportfooter (another one)

## [0.0.36] - 2022-09-05 - bugfix in get-htmlreportfooter

## [0.0.35] - 2022-09-05 - Added ReportInstanceId param to Get-HtmlReportFooter

## [0.0.34] - 2022-09-05 - fixed typo in get-htmlreportfooter

## [0.0.33] - 2022-09-05 - disabled multithreading in expand-folder when there is only a single folder to expand

## [0.0.32] - 2022-09-05 - implemented expand-folder with multithreading

## [0.0.31] - 2022-09-05 - Implemented Export-Permission enhancement issue 14

## [0.0.30] - 2022-09-04 - bugfix in get-folderaccesslist wrong param name for split-thread

## [0.0.29] - 2022-09-04 - updated default threadcount for get-folderaccesslist

## [0.0.28] - 2022-09-04 - export-permission issue 45

## [0.0.27] - 2022-09-04 - export-permission issue 45

## [0.0.26] - 2022-08-31 - bugfix Get-FolderPermissionsBlock -IgnoreDomain

## [0.0.25] - 2022-08-31 - bugfix Get-FolderPermissionsBlock -IgnoreDomain

## [0.0.24] - 2022-08-27 - Added Count property to the output of Select-UniqueAccountPermission

## [0.0.23] - 2022-08-21 - Minor changes to Get-FolderAccessList

## [0.0.22] - 2022-08-20 - Added Select-UniqueAccountPermission

## [0.0.21] - 2022-08-19 - bugfix, needed quotes around Get-FolderAce for Split-Thread

## [0.0.20] - 2022-08-19 - Added parameters for improved Write-LogMsg support

## [0.0.19] - 2022-08-14 - Updated Get-FolderPermissionBlock

## [0.0.18] - 2022-08-05 - bugfix in get-folderpermissionsblock

## [0.0.17] - 2022-08-05 - More accurate folder table header for parent folder

## [0.0.16] - 2022-08-01 - Parameter cleanup in Get-FolderPermissionsBlock

## [0.0.15] - 2022-08-01 - Parameter cleanup in Get-FolderPermissionsBlock

## [0.0.14] - 2022-07-30 - Fixed build errors from last time

## [0.0.13] - 2022-07-30 - No changes just refreshing to make sure

## [0.0.12] - 2022-07-27 - Updated origin URL for github repo, testing new build

## [0.0.11] - 2022-07-27 - Test after renaming GitHub repo to match module name

## [0.0.10] - 2022-07-26 - First published build to psgallery

## [0.0.9] - 2022-07-26 - Another psakefile bugfix

## [0.0.8] - 2022-07-26 - bugfix for psakefile

## [0.0.7] - 2022-07-26 - bugfix for psakefile

## [0.0.6] - 2022-07-26 - Updated source .psm1 file to clean it up

## [0.0.5] - 2022-07-26 - Test build

## [0.0.4] - 2022-07-26 - Test build

## [0.0.3] - 2022-07-26 - 2nd build

## [0.0.1] Unreleased

