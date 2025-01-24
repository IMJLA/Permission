function Get-ReportFileNameList {

    param (
        [Parameter(Mandatory = $true)]
        $ReportFiles,
        [Parameter(Mandatory = $true)]
        [string]$Subproperty,
        [Parameter(Mandatory = $true)]
        [string]$FileNameProperty,
        [Parameter(Mandatory = $true)]
        [string]$FileNameSubproperty
    )


    ForEach ($File in $ReportFiles) {

        if ($Subproperty -eq '') {
            $Subfile = $File
        } else {
            $Subfile = $File.$Subproperty
        }

        if ($FileNameProperty -eq '') {
            $FileName = $File.$FileNameSubproperty
        } else {
            $FileName = $File.$FileNameProperty.$FileNameSubproperty
        }

        $FileName -replace '\\\\', '' -replace '\\', '_' -replace '\:', ''

    }

}
