function Invoke-PermissionCommand {

    param (

        [String]$Command,

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Steps = [System.Collections.Specialized.OrderedDictionary]::New()
    $Steps.Add(
        'Get the NTAccount caption of the user running the script, with the correct capitalization',
        { HOSTNAME.EXE }
    )
    $Steps.Add(
        'Get the hostname of the computer running the script',
        { Get-CurrentWhoAmI -LogBuffer $LogBuffer -ThisHostName $ThisHostname }
    )

    $StepCount = $Steps.Count
    Write-LogMsg -Cache $Cache -ExpansionMap $Cache['LogEmptyMap'].Value -Type Verbose -Text $Command
    $ScriptBlock = $Steps[$Command]
    Write-LogMsg -Cache $Cache -ExpansionMap $Cache['LogEmptyMap'].Value -Type Debug -Text $ScriptBlock
    Invoke-Command -ScriptBlock $ScriptBlock

}
