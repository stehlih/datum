using module datum

Remove-Module -Name datum

Describe 'Environment variable resolution in ResolutionPrecedence paths' {
    BeforeAll {
        $here = $PSScriptRoot
        Import-Module -Name datum -Force

        $env:DatumTestBaseline = 'TestBaseline'

        $datumPath = Join-Path -Path $here -ChildPath 'assets\EnvVarResolutionTestData\Datum.yml'
        if (-not (Test-Path $datumPath))
        {
            throw "Cannot find Datum.yml at: $datumPath (here = $here)"
        }

        $datum = New-DatumStructure -DefinitionFile $datumPath
        $allNodes = @($datum.AllNodes.psobject.Properties | ForEach-Object {
                $node = $datum.AllNodes.($_.Name)
                (@{} + $node)
            })
    }

    AfterAll {
        Remove-Item -Path Env:\DatumTestBaseline -ErrorAction SilentlyContinue
    }

    Context 'ResolutionPrecedence entries with environment variables' {

        It 'Should resolve a property from a baseline referenced via an environment variable' {
            $myNode = $allNodes.Where({ $_.NodeName -eq 'TestNode01' })
            $result = Resolve-Datum -PropertyPath 'TestSetting' -Variable $myNode -DatumTree $datum
            $result | Should -Be 'BaselineValue'
        }

        It 'Should not throw a DriveNotFoundException when using $env: in ResolutionPrecedence' {
            $myNode = $allNodes.Where({ $_.NodeName -eq 'TestNode01' })
            { Resolve-Datum -PropertyPath 'TestSetting' -Variable $myNode -DatumTree $datum } | Should -Not -Throw
        }

        It 'Should resolve a property from a mid-path environment variable reference' {
            $env:DatumTestRole = 'WebServer'
            try
            {
                $myNode = $allNodes.Where({ $_.NodeName -eq 'TestNode01' })
                $result = Resolve-Datum -PropertyPath 'RoleSetting' -Variable $myNode -DatumTree $datum
                $result | Should -Be 'WebServerConfigValue'
            }
            finally
            {
                Remove-Item -Path Env:\DatumTestRole -ErrorAction SilentlyContinue
            }
        }
    }
}
