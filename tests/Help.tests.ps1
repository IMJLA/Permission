# Taken with love from @juneb_get_help (https://raw.githubusercontent.com/juneb/PesterTDD/master/Module.Help.Tests.ps1)

BeforeDiscovery {

    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'dist'
    $outputModVerDir = Join-Path -Path $outputDir -ChildPath $manifest.ModuleVersion
    $outputModDir = Join-Path -Path $outputModVerDir -ChildPath $env:BHProjectName
    $outputModVerManifest = Join-Path -Path $outputModDir -ChildPath "$($env:BHProjectName).psd1"

    # Get module commands
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
    $params = @{
        Module      = (Get-Module $env:BHProjectName)
        CommandType = [System.Management.Automation.CommandTypes[]]'Cmdlet, Function' # Not alias
    }
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $params.CommandType[0] += 'Workflow'
    }
    $commands = Get-Command @params

    Update-Help -Module $env:BHProjectName
    ## When testing help, remember that help is cached at the beginning of each session.
    ## To test, restart session.
}

Describe "help for <_.Name>" -ForEach $commands {

    BeforeDiscovery {
        function FilterOutCommonParams {
            param ($Params)
            $commonParams = @(
                'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable',
                'OutBuffer', 'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction',
                'WarningVariable', 'Confirm', 'Whatif'
            )
            $params | Where-Object { $_.Name -notin $commonParams } | Sort-Object -Property Name -Unique
        }
        # Get command help, parameters, and links
        $command = $_
        $commandHelp = Get-Help $command.Name -ErrorAction SilentlyContinue
        $commandParameters = FilterOutCommonParams -Params $command.ParameterSets.Parameters
        $commandParameterNames = $commandParameters.Name
        $helpLinks = $commandHelp.relatedLinks.navigationLink.uri
    }

    BeforeAll {
        function FilterOutCommonParams {
            param ($Params)
            $commonParams = @(
                'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable',
                'OutBuffer', 'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction',
                'WarningVariable', 'Confirm', 'Whatif'
            )
            $params | Where-Object { $_.Name -notin $commonParams } | Sort-Object -Property Name -Unique
        }
        # These vars are needed in both discovery and test phases so we need to duplicate them here
        $command = $_
        $commandName = $_.Name
        $commandHelp = Get-Help $command.Name -ErrorAction SilentlyContinue
        $commandParameters = FilterOutCommonParams -Params $command.ParameterSets.Parameters
        $commandParameterNames = $commandParameters.Name
        $helpParameters = FilterOutCommonParams -Params $commandHelp.Parameters.Parameter
        $helpParameterNames = $helpParameters.Name
    }

    # If help is not found, synopsis in auto-generated help is the syntax diagram
    It 'is not auto-generated' {
        $commandHelp.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
    }

    # Should be a description for every function
    It "has a description" {
        $commandHelp.Description | Should -Not -BeNullOrEmpty
    }

    # Should be at least one example
    It "has example code" {
        ($commandHelp.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
    }

    # Should be at least one example description
    It "has example help" {
        ($commandHelp.Examples.Example.Remarks | Select-Object -First 1).Text | Should -Not -BeNullOrEmpty
    }

    It "has a valid link URL '<_>'" -ForEach $helpLinks {
        (Invoke-WebRequest -Uri $_ -UseBasicParsing).StatusCode | Should -Be '200'
    }

    Context "- Help for parameter '<_.Name>'" -Foreach $commandParameters {

        BeforeAll {
            $parameter = $_
            $parameterName = $parameter.Name
            $parameterHelp = $commandHelp.parameters.parameter | Where-Object Name -eq $parameterName
            $parameterHelpType = if ($parameterHelp.ParameterValue) { $parameterHelp.ParameterValue.Trim() }
        }

        # Should be a description for every parameter
        It "has a description" {
            $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
        }

        # Required value in Help should match IsMandatory property of parameter
        It "has the correct [mandatory] value" {
            $codeMandatory = $_.IsMandatory.toString()
            $parameterHelp.Required | Should -Be $codeMandatory
        }

        # Parameter type in help should match code
        It "has the correct parameter type" {
            $parameterHelpType | Should -Be $parameter.ParameterType.Name
        }

    }

    Context "- Parameter '<_>' from the help" -Foreach $helpParameterNames {

        # Shouldn't find extra parameters in help.
        It "exists in the code: <_>" {
            $_ -in $parameterNames | Should -Be $true
        }
    }
}
