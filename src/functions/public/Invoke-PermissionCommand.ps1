function Invoke-PermissionCommand {

    param (

        [String]$Command

    )

    $Steps = [System.Collections.Specialized.OrderedDictionary]::New()
    $Steps.Add(
        'Get the NTAccount caption of the user running the script, with the correct capitalization',
        { HOSTNAME.EXE }
    )
    $Steps.Add(
        'Get the hostname of the computer running the script',
        { Get-CurrentWhoAmI -LogMsgCache $LogMsgCache -ThisHostName $ThisHostname }
    )

    $LogParams = @{
        LogMsgCache  = $LogMsgCache
        ThisHostname = $ThisHostname
        #Type         = $DebugOutputStream
        WhoAmI       = $WhoAmI
    }

    $StepCount = $Steps.Count
    Write-LogMsg @LogParams -Type Verbose -Text $Command
    $ScriptBlock = $Steps[$Command]
    Write-LogMsg @LogParams -Type Debug -Text $ScriptBlock
    Invoke-Command -ScriptBlock $ScriptBlock

}
