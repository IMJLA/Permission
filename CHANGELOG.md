# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.0.573] - 2024-04-08 - add debug pause

## [0.0.572] - 2024-04-08 - bugfix incorrect plural param names

## [0.0.571] - 2024-04-08 - bugfix expand-targetpermissionreference

## [0.0.570] - 2024-04-08 - force module rebuild

## [0.0.569] - 2024-04-08 - update and re-implement select-uniqueprincipal

## [0.0.568] - 2024-04-07 - parameter rename

## [0.0.567] - 2024-04-07 - update select-uniqueprincipal

## [0.0.566] - 2024-04-07 - update summary div header for groupby account

## [0.0.565] - 2024-04-07 - bugfix remove dollar sign that shouldn't be there

## [0.0.564] - 2024-04-07 - implement parentprogressid for split-thread

## [0.0.563] - 2024-04-07 - bugfix multithreaded get-accesscontrollist (still potential for future optimization here)

## [0.0.562] - 2024-04-07 - param rename for clarity of purpose

## [0.0.561] - 2024-04-07 - progress + splat cleanup

## [0.0.560] - 2024-04-07 - bugfix get-accesscontrol list, add progressparentidparam to expand-permission

## [0.0.559] - 2024-04-07 - bugfix summary table header for groupby item

## [0.0.558] - 2024-04-06 - bugfix remove redundant code

## [0.0.557] - 2024-04-06 - bugfix js report should use json data

## [0.0.556] - 2024-04-06 - bugfix missing commas

## [0.0.555] - 2024-04-06 - js = html with js vs json = raw json

## [0.0.554] - 2024-04-06 - bugfix returning twice as many objects as needed

## [0.0.553] - 2024-04-06 - remove unnecessary expansion into flatpermissions when splitby does not contain none

## [0.0.552] - 2024-04-06 - remove unnecessary inefficient switch stmt

## [0.0.551] - 2024-04-06 - add breaks in switch statements

## [0.0.550] - 2024-04-06 - add namespace param support for get-ciminstance

## [0.0.549] - 2024-04-06 - remove debug pauses and sleeps

## [0.0.548] - 2024-04-06 - debug progress bars with start-sleep

## [0.0.547] - 2024-04-06 - bugfix forgotten suffix

## [0.0.546] - 2024-04-06 - debug pause

## [0.0.545] - 2024-04-06 - update file naming

## [0.0.544] - 2024-04-06 - integrate per-networkpath filename logic

## [0.0.543] - 2024-04-06 - integrate per-networkpath filename logic

## [0.0.542] - 2024-04-06 - sort formats in report output

## [0.0.541] - 2024-04-06 - remove debug write-host

## [0.0.540] - 2024-04-06 - abandon stringbuilder, adjust margins and padding

## [0.0.539] - 2024-04-06 - testing without stringbuilder

## [0.0.538] - 2024-04-06 - add debug output with write-host

## [0.0.537] - 2024-04-06 - bugfixes for files not generated

## [0.0.536] - 2024-04-06 - debug pause

## [0.0.535] - 2024-04-06 - why is this an array of objects? casting as str even though I need to find root cause

## [0.0.534] - 2024-04-06 - force cast as string

## [0.0.533] - 2024-04-06 - pause for debug

## [0.0.532] - 2024-04-06 - bugfix incorrect location for returning the final string

## [0.0.531] - 2024-04-06 - fix padding and filter formats with no files generated due to level param

## [0.0.530] - 2024-04-06 - split html list of files into a div of lists per format folder

## [0.0.529] - 2024-04-06 - bugfix missing detail param

## [0.0.528] - 2024-04-06 - bugfix missing detail param

## [0.0.527] - 2024-04-06 - add network path to detail table headers

## [0.0.526] - 2024-04-05 - add network path to header above the detail table

## [0.0.525] - 2024-04-05 - add network path to header above the detail table

## [0.0.524] - 2024-04-05 - add debug pause

## [0.0.523] - 2024-03-31 - bugfix DetailString needs to be array of strings not single string

## [0.0.522] - 2024-03-31 - shrink heading sizes

## [0.0.521] - 2024-03-31 - bugfix detail div header size

## [0.0.520] - 2024-03-31 - bugfix detail div header size

## [0.0.519] - 2024-03-31 - bugfix no tableofcontents when groupby -eq splitby

## [0.0.518] - 2024-03-31 - bugfix no tableofcontents when groupby -eq splitby

## [0.0.517] - 2024-03-31 - bugfix when no grouping is needed

## [0.0.516] - 2024-03-31 - bugfix splitby target groupby item

## [0.0.515] - 2024-03-31 - remove debug pause

## [0.0.514] - 2024-03-31 - bugfix remove extra squiggly braces

## [0.0.513] - 2024-03-31 - pause for debug

## [0.0.512] - 2024-03-31 - bugfix when groupby -eq splitby

## [0.0.511] - 2024-03-31 - update convertto-permissiongroup to better handle groupby none or groupby -eq splitby

## [0.0.510] - 2024-03-31 - var rename

## [0.0.509] - 2024-03-31 - bugfix force hashtable lookup eval before property lookup

## [0.0.508] - 2024-03-31 - implemenent resolve-groupbyparameter

## [0.0.507] - 2024-03-31 - add groupby target to param validation

## [0.0.506] - 2024-03-31 - add param validation support for groupby target

## [0.0.505] - 2024-03-31 - bugfix convertto-permissionlist needs to know how to split

## [0.0.504] - 2024-03-31 - support groupby none or equivalents

## [0.0.503] - 2024-03-31 - bugfix or creating new bug?  TBD

## [0.0.502] - 2024-03-30 - bugfix for folders with no unique perms

## [0.0.501] - 2024-03-30 - implement groupby target

## [0.0.500] - 2024-03-30 - implement groupby target

## [0.0.499] - 2024-03-30 - bugfix by renaming var

## [0.0.498] - 2024-03-30 - enable groupby target with consistent param validation across functs

## [0.0.497] - 2024-03-30 - enable groupby target with consistent param validation across functs

## [0.0.496] - 2024-03-30 - bugfix implementation for when groupby and splitby are the same

## [0.0.495] - 2024-03-30 - implement groupby target

## [0.0.494] - 2024-03-30 - implement groupby target

## [0.0.493] - 2024-03-30 - implement groupby target

## [0.0.492] - 2024-03-30 - bugfix forgot about group members

## [0.0.491] - 2024-03-30 - bugfix footer permission count

## [0.0.490] - 2024-03-30 - bugfix groupby none

## [0.0.489] - 2024-03-30 - bugfix groupby none

## [0.0.488] - 2024-03-30 - bugfix groupby none

## [0.0.487] - 2024-03-30 - move debug pause

## [0.0.486] - 2024-03-30 - add groupby none

## [0.0.485] - 2024-03-30 - bugfix splitting or grouping by none

## [0.0.484] - 2024-03-30 - bugfix handle items with no unique aces

## [0.0.483] - 2024-03-30 - bugfix param should not be plural

## [0.0.482] - 2024-03-30 - bugfix force cast as string

## [0.0.481] - 2024-03-30 - butfix wrong var name

## [0.0.480] - 2024-03-30 - remove debug pause

## [0.0.479] - 2024-03-30 - only output a child item object if there are unique ACEs for the item

## [0.0.478] - 2024-03-30 - only output a child item object if there are unique ACEs for the item

## [0.0.477] - 2024-03-30 - correct detailexport param type

## [0.0.476] - 2024-03-30 - add debug pause

## [0.0.475] - 2024-03-30 - add culture param type

## [0.0.474] - 2024-03-30 - define param types

## [0.0.473] - 2024-03-30 - bugfix incorrect plural var name needed to be singular

## [0.0.472] - 2024-03-30 - add debug pause

## [0.0.471] - 2024-03-30 - add debug pause

## [0.0.470] - 2024-03-30 - add debug pause

## [0.0.469] - 2024-03-30 - move debug pause

## [0.0.468] - 2024-03-30 - add debug output

## [0.0.467] - 2024-03-30 - add debug output

## [0.0.466] - 2024-03-30 - easier to read switch stmt

## [0.0.465] - 2024-03-30 - filter out items with no no aces returned when non-inherited ACEs are excluded (default)

## [0.0.464] - 2024-03-30 - bugfix prop name

## [0.0.463] - 2024-03-30 - bugfix prop name Children is more descriptive but Items is more consistent with Accounts for GroupBy account

## [0.0.462] - 2024-03-30 - implement select-itemtableproperty in the networkpath div

## [0.0.461] - 2024-03-30 - update detailstrings for file names

## [0.0.460] - 2024-03-29 - bugfix permission count in report footer

## [0.0.459] - 2024-03-26 - embiggen the heading I made too small

## [0.0.458] - 2024-03-26 - use smaller headings

## [0.0.457] - 2024-03-26 - make heading smaller

## [0.0.456] - 2024-03-25 - decrease heading levels

## [0.0.455] - 2024-03-25 - bugfix capitalization

## [0.0.454] - 2024-03-25 - bugfix footer unitstoresolve

## [0.0.453] - 2024-03-25 - publish new ver due to conflict/mistake publishing from wrong folder

## [0.0.452] - 2024-03-25 - implement additionalclasses param for new-bootstrapalert

## [0.0.451] - 2024-03-25 - implement additionalclasses param for new-bootstrapalert

## [0.0.450] - 2024-03-25 - bugfix replace item prop and stop casting as string array when I want objects

## [0.0.449] - 2024-03-25 - more efficient switch stmt

## [0.0.448] - 2024-03-25 - update debug pause

## [0.0.447] - 2024-03-25 - bugfix no item prop

## [0.0.446] - 2024-03-25 - update debug pause

## [0.0.445] - 2024-03-25 - bugfix splat

## [0.0.444] - 2024-03-25 - bugfix need to ensure the variable dependencies are set before invoke-command

## [0.0.443] - 2024-03-25 - update debug pause

## [0.0.442] - 2024-03-25 - update debug pause

## [0.0.441] - 2024-03-25 - update debug pause

## [0.0.440] - 2024-03-25 - bugfix on level 10

## [0.0.439] - 2024-03-25 - bugfix filename

## [0.0.438] - 2024-03-25 - bugfix on level 1

## [0.0.437] - 2024-03-25 - bugfix missing filename

## [0.0.436] - 2024-03-25 - bugfix on level 2

## [0.0.435] - 2024-03-25 - bugfix reportfile var not in scope for scriptblocks so arg is required

## [0.0.434] - 2024-03-25 - bugfix move scriptblocks before loop begins

## [0.0.433] - 2024-03-25 - add debugging pause

## [0.0.432] - 2024-03-25 - add debugging pause

## [0.0.431] - 2024-03-25 - add debugging pause

## [0.0.430] - 2024-03-25 - allow js format to use json data with a formatstring that changes only for js format

## [0.0.429] - 2024-03-25 - more multi-format fixin

## [0.0.428] - 2024-03-25 - add detailexports for every format

## [0.0.427] - 2024-03-25 - moved debug to correct location

## [0.0.426] - 2024-03-25 - debug pause

## [0.0.425] - 2024-03-25 - bugfix was resetting detailscripts improperly and needlessly

## [0.0.424] - 2024-03-24 - bugfix pass report as arg

## [0.0.423] - 2024-03-24 - bugfix plural vs singular param names

## [0.0.422] - 2024-03-24 - reduce number of files written.  implement out-permissiondetailreport for redundant code

## [0.0.421] - 2024-03-24 - bugfix nested file name properties

## [0.0.420] - 2024-03-24 - bugfix remove period from end of subproperty

## [0.0.419] - 2024-03-24 - update tmp debug output

## [0.0.418] - 2024-03-24 - bugfix nested props in single string not working

## [0.0.417] - 2024-03-24 - bugfix filenameproperty $split vs $splitby

## [0.0.416] - 2024-03-24 - add tmp debug output

## [0.0.415] - 2024-03-24 - tmp debug output

## [0.0.414] - 2024-03-24 - tmp debug output

## [0.0.413] - 2024-03-24 - bugfix forgot to convert hashtable to obj

## [0.0.412] - 2024-03-24 - add necessary subproperty

## [0.0.411] - 2024-03-24 - remove unnecessary subproperty

## [0.0.410] - 2024-03-24 - temp debug output

## [0.0.409] - 2024-03-24 - temp debug output

## [0.0.408] - 2024-03-24 - temp debug output

## [0.0.407] - 2024-03-24 - bugfix logparams

## [0.0.406] - 2024-03-24 - changes

## [0.0.405] - 2024-03-24 - changes

## [0.0.404] - 2024-03-24 - lets see how far out-permissionreport gets now

## [0.0.403] - 2024-03-24 - bugfix selection property was incorrect

## [0.0.402] - 2024-03-24 - i dunno it was minor

## [0.0.401] - 2024-03-24 - add network paths header and div with subheader and table

## [0.0.400] - 2024-03-23 - remove switch statement and enable code reuse

## [0.0.399] - 2024-03-23 - remove switch statement and enable code reuse

## [0.0.398] - 2024-03-23 - move html code to its own function for readability

## [0.0.397] - 2024-03-23 - force list enumeration

## [0.0.396] - 2024-03-23 - restore account permission reference expansion

## [0.0.395] - 2024-03-23 - remove unnecessary debug output

## [0.0.394] - 2024-03-23 - oops now I finished renaming the param names

## [0.0.393] - 2024-03-23 - force list enumeration

## [0.0.392] - 2024-03-23 - force list enum

## [0.0.391] - 2024-03-23 - debug output

## [0.0.390] - 2024-03-23 - replaced where-object with foreach loop

## [0.0.389] - 2024-03-23 - debug output

## [0.0.388] - 2024-03-23 - shorten var names

## [0.0.387] - 2024-03-23 - improve debug output

## [0.0.386] - 2024-03-23 - debug output fix

## [0.0.385] - 2024-03-23 - move string cast back to calling funct

## [0.0.384] - 2024-03-23 - move string cast to nested funct

## [0.0.383] - 2024-03-23 - force cast as string because comparision of string to hashtablekeycollection just won't work obv

## [0.0.382] - 2024-03-19 - debug output

## [0.0.381] - 2024-03-19 - debug output

## [0.0.380] - 2024-03-19 - debug output

## [0.0.379] - 2024-03-19 - debug output

## [0.0.378] - 2024-03-19 - debug output

## [0.0.377] - 2024-03-19 - bugfix hashtable vs string key

## [0.0.376] - 2024-03-19 - add temp debug output

## [0.0.375] - 2024-03-19 - add temp debug output

## [0.0.374] - 2024-03-19 - temp debug output

## [0.0.373] - 2024-03-19 - troubleshoot

## [0.0.372] - 2024-03-19 - bugfix missing aceguidsbyresolvedid

## [0.0.371] - 2024-03-19 - bugfix id param

## [0.0.370] - 2024-03-19 - troubleshooting

## [0.0.369] - 2024-03-19 - implement targetpath to networkpath to groupby

## [0.0.368] - 2024-03-18 - fix order of table properties (I think)

## [0.0.367] - 2024-03-18 - fix order of properties/columns

## [0.0.366] - 2024-03-18 - add description to default set of account properties when groupby account

## [0.0.365] - 2024-03-18 - add more sorting

## [0.0.364] - 2024-03-18 - standardize terminology on 'Folders' rather than 'Items'.  Planning for future intelligent variable that knows folders vs. files vs. keys

## [0.0.363] - 2024-03-18 - bugfix format json groupby account

## [0.0.362] - 2024-03-18 - update summarytableheader for groupby account

## [0.0.361] - 2024-03-18 - update summarytableheader for groupby account

## [0.0.360] - 2024-03-18 - bugfix headings in report when groupby account

## [0.0.359] - 2024-03-18 - implement groupby in xml format

## [0.0.358] - 2024-03-18 - force ace enumeration

## [0.0.357] - 2024-03-18 - remove unnecessary null checks and debug output

## [0.0.356] - 2024-03-18 - update debug output

## [0.0.355] - 2024-03-18 - add null checking and update debug output

## [0.0.354] - 2024-03-18 - add null checking

## [0.0.353] - 2024-03-18 - update debug output and workflow

## [0.0.352] - 2024-03-18 - add null guid checking

## [0.0.351] - 2024-03-18 - bugfix force itempath enumeration

## [0.0.350] - 2024-03-18 - add temp debug writehost

## [0.0.349] - 2024-03-18 - add temp debug writehost

## [0.0.348] - 2024-03-18 - bugfix force cast as guid array

## [0.0.347] - 2024-03-18 - bugfix force cast as array

## [0.0.346] - 2024-03-18 - bugfix force cast as array

## [0.0.345] - 2024-03-18 - add temporary debug write-hosts

## [0.0.344] - 2024-03-18 - using new var instead of reusing cacheresult

## [0.0.343] - 2024-03-18 - revert to original invoke-expression implementation

## [0.0.342] - 2024-03-18 - troubleshoot add-cacheitem creating collection of fixed size

## [0.0.341] - 2024-03-18 - bugfix addrange force string array even for single string

## [0.0.340] - 2024-03-18 - guess at bugfix

## [0.0.339] - 2024-03-17 - further implement splitby and groupby

## [0.0.338] - 2024-03-17 - bugfix missing Path property

## [0.0.337] - 2024-03-17 - reduce lines of code

## [0.0.336] - 2024-03-17 - added splitby target feature

## [0.0.335] - 2024-03-16 - implement target value for splitby param

## [0.0.334] - 2024-03-16 - strict param typing

## [0.0.333] - 2024-03-16 - ensure resolve-permissiontarget works in the process block of export-permission by updating hashtable rather than returning it

## [0.0.332] - 2024-03-16 - get-targetpermission becomes get-accesscontrollist

## [0.0.331] - 2024-03-16 - expand child values

## [0.0.330] - 2024-03-16 - bugfix children dictionaryvaluecollection vs string coll

## [0.0.329] - 2024-03-16 - bugfix children dictionaryvaluecollection vs string coll

## [0.0.328] - 2024-03-16 - change targetpath to only expect incoming collection rather than hashtable

## [0.0.327] - 2024-03-16 - updates and renames

## [0.0.326] - 2024-03-16 - I don't even know anymore

## [0.0.325] - 2024-03-16 - implement export of expanded permissions (level index 6)

## [0.0.324] - 2024-03-16 - troubleshoot blank htmlfolderpermissions in body

## [0.0.323] - 2024-03-16 - suppressed erroneous converto-json depth warnings

## [0.0.322] - 2024-03-02 - bugfix list of generated files

## [0.0.321] - 2024-03-02 - add fileformat and outputformat params

## [0.0.320] - 2024-03-02 - remove logging of calls that only format data in memory

## [0.0.319] - 2024-03-02 - remove logging of calls to private functs

## [0.0.318] - 2024-03-02 - make tables responsive (horizontal scrolling)

## [0.0.317] - 2024-03-02 - troubleshoot summarytable

## [0.0.316] - 2024-03-02 - troubleshoot summarytable

## [0.0.315] - 2024-03-02 - set pagesize to 50 for json table

## [0.0.314] - 2024-03-02 - set pagesize to 50 for json table

## [0.0.313] - 2024-03-02 - remove report file list sorting

## [0.0.312] - 2024-03-02 - bugfix convertto-permissionlist incorrect prop names

## [0.0.311] - 2024-03-02 - bugfix convertto-permissionlist

## [0.0.310] - 2024-03-02 - text improvement convertto-nameexclusiondiv

## [0.0.309] - 2024-03-02 - out-permissionreport improvements

## [0.0.308] - 2024-03-02 - add sorting to converto-permissionlist and add heading to permissions table when flat permissions are used

## [0.0.307] - 2024-03-02 - add sorting to converto-permissionlist and add heading to permissions table when flat permissions are used

## [0.0.306] - 2024-03-02 - bugfix convertto-permissionlist

## [0.0.305] - 2024-03-02 - bugfix convertto-permissionlist

## [0.0.304] - 2024-03-02 - troubleshooting

## [0.0.303] - 2024-03-02 - implement GroupBy 'none'

## [0.0.302] - 2024-03-02 - rename select-itempermissiontableproperty to select-permissiontableproperty

## [0.0.301] - 2024-03-02 - add groupby param to select-itempermissiotableproperty

## [0.0.300] - 2024-03-02 - attempting to implement flat permission report

## [0.0.299] - 2024-03-02 - attempting to implement flat permission report

## [0.0.298] - 2024-03-02 - bugfix resolve-splitbyparameter when split -eq 'none'

## [0.0.297] - 2024-02-25 - new prog barsfixed the prog bars somehow!

## [0.0.296] - 2024-02-25 - new prog barsfixed the prog bars somehow!

## [0.0.295] - 2024-02-25 - new prog bars did not fix anything, troubleshooting

## [0.0.294] - 2024-02-25 - new prog bars did not fix anything, troubleshooting

## [0.0.293] - 2024-02-25 - bugfix new prog bars

## [0.0.292] - 2024-02-25 - bugfix new prog bars

## [0.0.291] - 2024-02-25 - progress bar updates

## [0.0.290] - 2024-02-25 - depth experiments

## [0.0.289] - 2024-02-25 - depth experiments

## [0.0.288] - 2024-02-25 - comment not-yet-working parts

## [0.0.287] - 2024-02-25 - sort html file list

## [0.0.286] - 2024-02-25 - remove convertto-json depth param due to apparent stall

## [0.0.285] - 2024-02-25 - add convertto-json compression. add depth param at final export to ensure full serialization

## [0.0.284] - 2024-02-25 - reportfilelist bug

## [0.0.283] - 2024-02-25 - bugfix footer for html and json reports (code pasted in wrong scope)

## [0.0.282] - 2024-02-25 - bugfix footer for html and json report

## [0.0.281] - 2024-02-25 - bugfix tried to invent my own param convertto-json

## [0.0.280] - 2024-02-25 - add more formats to export

## [0.0.279] - 2024-02-25 - csv export bugfix

## [0.0.278] - 2024-02-25 - csv export bugfix

## [0.0.277] - 2024-02-25 - bugfix scriptblock invocation

## [0.0.276] - 2024-02-25 - regex bugfix

## [0.0.275] - 2024-02-25 - csv export levels

## [0.0.274] - 2024-02-24 - bugfix convertto-permissionlist

## [0.0.273] - 2024-02-24 - bugfix get-folderpermissiontableheader missed a spot

## [0.0.272] - 2024-02-24 - bugfix get-folderpermissiontableheader

## [0.0.271] - 2024-02-24 - bugfix missing heading and subheading for json div in convertto-permissionlist

## [0.0.270] - 2024-02-24 - bugfix

## [0.0.269] - 2024-02-24 - bugfix scripthtml was in wrong order

## [0.0.268] - 2024-02-24 - bugfix reportfile path

## [0.0.267] - 2024-02-24 - bugfix get-folderpermissiontableheader and converto-permissionlist

## [0.0.266] - 2024-02-24 - troubleshoot convertto-permissiolist

## [0.0.265] - 2024-02-24 - out-permissionreport

## [0.0.264] - 2024-02-24 - add out-permissionreport

## [0.0.263] - 2024-02-24 - bugfix need InnerXml

## [0.0.262] - 2024-02-24 - comment prtgxml does not belong here, will find new home later

## [0.0.261] - 2024-02-24 - bugfix converto-permissionlist xml format

## [0.0.260] - 2024-02-24 - bugfix converto-permissionlist tableid

## [0.0.259] - 2024-02-24 - bugfix converto-permissionlist

## [0.0.258] - 2024-02-24 - troubleshoot converto-permissionlist

## [0.0.257] - 2024-02-24 - bugfix convertto-permissionlist

## [0.0.256] - 2024-02-24 - bugfix convertto-permissionlist

## [0.0.255] - 2024-02-24 - bugfix select-itempermissiontableproperty

## [0.0.254] - 2024-02-24 - troubleshoot build

## [0.0.253] - 2024-02-24 - troubleshoot build

## [0.0.252] - 2024-02-24 - troubleshoot build

## [0.0.251] - 2024-02-24 - troubleshoot build

## [0.0.250] - 2024-02-24 - troubleshoot build

## [0.0.249] - 2024-02-24 - rebuild

## [0.0.248] - 2024-02-24 - rebuild

## [0.0.247] - 2024-02-24 - format-permission and all that it entails

## [0.0.246] - 2024-02-24 - format-permission and all that it entails

## [0.0.245] - 2024-02-24 - format-permission and all that it entails

## [0.0.244] - 2024-02-24 - wtf

## [0.0.243] - 2024-02-24 - format-permission and all that it entails

## [0.0.242] - 2024-02-24 - format-permission and all that it entails

## [0.0.241] - 2024-02-24 - format-permission and all that it entails

## [0.0.240] - 2024-02-19 - remove debug pause

## [0.0.239] - 2024-02-19 - bugfix group-itempermissionreference

## [0.0.238] - 2024-02-19 - debug resolve-ace

## [0.0.237] - 2024-02-19 - bugfix select-foldertablepermissionproperty and fix funct name fka find-resolvedidswithaccess

## [0.0.236] - 2024-02-19 - functs to group and expand perm refs

## [0.0.235] - 2024-02-18 - update debug output

## [0.0.234] - 2024-02-18 - update tests

## [0.0.233] - 2024-02-18 - fix tests

## [0.0.232] - 2024-02-18 - remove win32accountsbysid from resolve-accesscontrollist

## [0.0.231] - 2024-02-18 - remove win32accountsbysid

## [0.0.230] - 2024-02-18 - threadsafe upgrade

## [0.0.229] - 2024-02-18 - enabled multiple key properties in get-cachedciminstance

## [0.0.228] - 2024-02-18 - remove win32accountsbycaption

## [0.0.227] - 2024-02-18 - remove win32accountsbycaption from initialize-cache

## [0.0.226] - 2024-02-18 - bugfix ciminstance is not dict there is no values prop

## [0.0.225] - 2024-02-18 - bugfix for empty CimInstance

## [0.0.224] - 2024-02-18 - update get-cachedciminstance to always maintain cached instances in a dict instead of array

## [0.0.223] - 2024-02-18 - update funct names

## [0.0.222] - 2024-02-18 - fix comment spacing

## [0.0.221] - 2024-02-18 - cleaner splats

## [0.0.220] - 2024-02-18 - add resolve-acl and resolve-ace

## [0.0.219] - 2024-02-18 - removed broken unnecessary sorting...I think it is already sorted

## [0.0.218] - 2024-02-18 - removed broken unnecessary sorting...I think it is already sorted

## [0.0.217] - 2024-02-18 - replace foreach-object with foreach

## [0.0.216] - 2024-02-18 - bugfix incorrect property name

## [0.0.215] - 2024-02-18 - bugfix discrepancy in table name between two functs. improved efficiency at same time

## [0.0.214] - 2024-02-18 - bugfix illegal chars were allowed in table id

## [0.0.213] - 2024-02-18 - resolve-identityreferencedomaindns initial commit

## [0.0.212] - 2024-02-18 - add add-cacheitem

## [0.0.211] - 2024-02-18 - remove redundant sorting

## [0.0.210] - 2024-02-17 - bugfix select-itemtableproperty

## [0.0.209] - 2024-02-17 - single line param as workaround for platyps

## [0.0.208] - 2024-02-17 - add inheritance flag resolution

## [0.0.207] - 2024-02-17 - add inheritance flag resolution

## [0.0.206] - 2024-02-17 - bugfix

## [0.0.205] - 2024-02-17 - rename select-foldertableproperty because it does nothing specific to folders

## [0.0.204] - 2024-02-17 - update to use new object model

## [0.0.203] - 2024-02-17 - replace formattedsecurityprincipals var with principalsbyresolvedid

## [0.0.202] - 2024-02-17 - implement new object model

## [0.0.201] - 2024-02-17 - remove debug sleeps

## [0.0.200] - 2024-02-17 - troubleshoot prog bar

## [0.0.199] - 2024-02-17 - troubleshoot prog bar

## [0.0.198] - 2024-02-17 - too many changes oops

## [0.0.197] - 2024-02-12 - bugfix get-permissionprincipal

## [0.0.196] - 2024-02-11 - mega caching

## [0.0.195] - 2024-02-11 - readability (and maybe efficiency) improvement get-permissionprincipal

## [0.0.194] - 2024-02-11 - bugfix get-folderaccesslist

## [0.0.193] - 2024-02-11 - implement resolve-acl

## [0.0.192] - 2024-02-11 - implement cache of acls keyed by path

## [0.0.191] - 2024-02-11 - bugfix Expand-PermissionPrincipal

## [0.0.190] - 2024-02-11 - bugfix Expand-PermissionPrincipal

## [0.0.189] - 2024-02-11 - implement expand-permissionprincipal

## [0.0.188] - 2024-02-11 - update param name

## [0.0.187] - 2024-02-11 - implement PrincipalsByResolvedID cache from Export-Permission

## [0.0.186] - 2024-02-10 - add currentdomain param to improve efficiency get-permissionprincipal

## [0.0.185] - 2024-02-10 - bugfix get-permissionprincipal

## [0.0.184] - 2024-02-10 - bugfix get-permissionprincipal

## [0.0.183] - 2024-02-10 - add caching to resolve-permissionidentity to avoid using group-object

## [0.0.182] - 2024-02-09 - add folder target caching

## [0.0.181] - 2024-02-09 - add folder target caching

## [0.0.180] - 2024-02-05 - bugfix group-permission

## [0.0.179] - 2024-02-05 - bugfix group-permission

## [0.0.178] - 2024-02-05 - bugfix group-permission

## [0.0.177] - 2024-02-05 - bugfix group-permission

## [0.0.176] - 2024-02-05 - bugfix group-permission

## [0.0.175] - 2024-02-05 - add group-permission

## [0.0.174] - 2024-02-05 - add pstype to output of format-folderpermission to try formatting final output

## [0.0.173] - 2024-02-05 - updated prog bars for consistency

## [0.0.172] - 2024-02-05 - add permission and principal counts to report footer

## [0.0.171] - 2024-02-05 - bugfix write-progress -percentcomplete

## [0.0.170] - 2024-02-05 - fixed initialized-cache progress

## [0.0.169] - 2024-02-05 - added localhost options

## [0.0.168] - 2024-02-05 - added localhost options

## [0.0.167] - 2024-02-05 - bugfix wrong key

## [0.0.166] - 2024-02-05 - add resolve-folder

## [0.0.165] - 2024-02-04 - add info to prog bar

## [0.0.164] - 2024-02-04 - bugfix multithreaded

## [0.0.163] - 2024-02-04 - add info to prog bar

## [0.0.162] - 2024-02-04 - bugfix null string when query param used

## [0.0.161] - 2024-02-04 - bugfix and improve code readability

## [0.0.160] - 2024-02-04 - working on cim caching

## [0.0.159] - 2024-02-04 - add cim query support

## [0.0.158] - 2024-02-04 - add feature to cleanup cim sessions

## [0.0.157] - 2024-02-04 - add debug logging to new cim cache feature

## [0.0.156] - 2024-02-04 - add cim caching

## [0.0.155] - 2024-02-04 - removed start-sleep from prog bar debugging

## [0.0.154] - 2024-02-04 - updated param names

## [0.0.153] - 2024-02-04 - updated param names

## [0.0.152] - 2024-02-04 - rename expand-permissionidenity to get-permissionsecurityprincipal

## [0.0.151] - 2024-02-03 - ps 5.1 workaround

## [0.0.150] - 2024-02-03 - remove duplicate specification of LogMsgCache. ok (but unnecessary) in ps7, breaks ps 5.1

## [0.0.149] - 2024-02-03 - troubleshoot prog bar

## [0.0.148] - 2024-02-03 - troubleshoot prog bar

## [0.0.147] - 2024-02-03 - troubleshoot prog bar

## [0.0.146] - 2024-02-03 - bugfix prog bar

## [0.0.145] - 2024-02-03 - troubleshoot prog bar

## [0.0.144] - 2024-02-03 - troubleshoot prog bar

## [0.0.143] - 2024-02-03 - troubleshoot prog bar

## [0.0.142] - 2024-02-03 - troubleshoot prog bar

## [0.0.141] - 2024-02-03 - troubleshoot prog bar

## [0.0.140] - 2024-02-03 - bugfix prog bar

## [0.0.139] - 2024-02-03 - troubleshoot prog bar

## [0.0.138] - 2024-02-03 - troubleshoot prog bar

## [0.0.137] - 2024-02-03 - troubleshoot prog bar

## [0.0.136] - 2024-02-03 - troubleshoot prog bar

## [0.0.135] - 2024-02-03 - troubleshoot prog bar

## [0.0.134] - 2024-02-03 - bugfix missing param for write-logmsg

## [0.0.133] - 2024-02-03 - bugfix missing params for write-logmsg

## [0.0.132] - 2024-02-03 - troubleshoot prog bar

## [0.0.131] - 2024-02-03 - troubleshoot prog bar

## [0.0.130] - 2024-02-03 - add Resolve-PermissionTarget

## [0.0.129] - 2024-02-03 - troubleshoot prog bar

## [0.0.128] - 2024-02-03 - troubleshoot prog bar

## [0.0.127] - 2024-02-03 - troubleshoot prog bar

## [0.0.126] - 2024-02-03 - bugfix progress bar

## [0.0.125] - 2024-02-03 - bugfix progress bar

## [0.0.124] - 2024-02-03 - bugfix progress bar

## [0.0.123] - 2024-02-03 - update prog bars

## [0.0.122] - 2024-02-03 - update prog bars

## [0.0.121] - 2024-02-03 - bugfix prog bar

## [0.0.120] - 2024-02-03 - bugfix prog bar

## [0.0.119] - 2024-02-03 - bugfix prog bar

## [0.0.118] - 2024-02-03 - bugfix prog bar

## [0.0.117] - 2024-02-03 - bugfix prog bar

## [0.0.116] - 2024-02-03 - troubleshoot prog bars

## [0.0.115] - 2024-02-03 - troubleshoot prog bars

## [0.0.114] - 2024-02-03 - troubleshoot prog bars

## [0.0.113] - 2024-02-03 - troubleshoot prog bars

## [0.0.112] - 2024-02-03 - troubleshoot prog bars

## [0.0.111] - 2024-02-03 - troubleshoot prog bars

## [0.0.110] - 2024-02-03 - troubleshoot prog bars

## [0.0.109] - 2024-02-03 - troubleshoot prog bars

## [0.0.108] - 2024-02-03 - troubleshoot prog bars

## [0.0.107] - 2024-02-03 - bugfix prog bars

## [0.0.106] - 2024-02-03 - bugfix prog bars

## [0.0.105] - 2024-02-03 - improved progress export-rawpermissioncsv

## [0.0.104] - 2024-02-03 - improved progress export-rawpermissioncsv

## [0.0.103] - 2024-02-03 - progress bar improvements

## [0.0.102] - 2024-02-02 - fill prog bar gap

## [0.0.101] - 2024-02-02 - fill another prog bar gap

## [0.0.100] - 2024-02-02 - test prog bars

## [0.0.99] - 2024-02-02 - fill gap in prog bars

## [0.0.98] - 2024-02-02 - nested prog bars and efficiency improvement

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

