function Get-ReportDescription {

    param (
        [int]$RecurseDepth
    )

    switch ($RecurseDepth ) {

        0 {
            'Does not include permissions on subfolders (option was declined)'
        }
        -1 {
            'Includes all subfolders with unique permissions (including ∞ levels of subfolders)'
        }
        default {
            "Includes all subfolders with unique permissions (down to $RecurseDepth levels of subfolders)"
        }

    }

}
