function Get-ReportDescription {

    param (
        [int]$RecurseDepth
    )

    switch ($RecurseDepth ) {

        0 {
            'Does not include permissions on subfolders (option was declined)'; break
        }
        -1 {
            'Includes all subfolders with unique permissions (including ∞ levels of subfolders)'; break
        }
        default {
            "Includes all subfolders with unique permissions (down to $RecurseDepth levels of subfolders)"; break
        }

    }

}
