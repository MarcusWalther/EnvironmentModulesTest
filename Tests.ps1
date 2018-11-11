if($null -eq (Get-Module -Name "Pester")) {
    Import-Module Pester
}

. "$env:ENVIRONMENT_MODULE_ROOT\Samples\StartSampleEnvironment.ps1" -AdditionalModulePaths @("$PSScriptRoot\Modules") -TempDirectory "$PSScriptRoot\Tmp" -ConfigDirectory "$PSScriptRoot\Config"

Describe 'TestLoading' {

    BeforeEach {
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Main module was loaded' {
        $loadedModules = Get-Module | Select-Object -Expand Name
        'EnvironmentModules' | Should -BeIn $loadedModules
    }

    It 'Default Modules were created' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "NotepadPlusPlus"
        $availableModules.Length | Should -Be 1
    }

    It 'Abstract Default Module was not created' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "Abstract"
        $availableModules | Should -Be $null
    }    

    It 'Meta Default Module was not created' {
        $availableModules = Get-EnvironmentModule -ListAvailable | Select-Object -Expand FullName
        'Project' | Should -Not -BeIn $availableModules
    }    
    
    It 'Module should not exist twice' {
        $availableModules = Get-EnvironmentModule -ListAvailable -ModuleFullName "NotepadPlusPlus-x64"
        $availableModules.Length | Should -Be 1
    }    

    It 'Meta-Module is unloaded directly' {
        Import-EnvironmentModule 'NotepadPlusPlus'
        $metaModule = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "NotepadPlusPlus"
        $metaModule | Should -BeNullOrEmpty
    }

    It 'Module is loaded correctly' {
        Import-EnvironmentModule 'NotepadPlusPlus'
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "NotepadPlusPlus-x64"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Dependency was loaded correctly' {
        Import-EnvironmentModule 'NotepadPlusPlus'
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Aspell-2_1-x86"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Module can be removed with dependencies' {
        Import-EnvironmentModule 'NotepadPlusPlus'
        Remove-EnvironmentModule 'NotepadPlusPlus-x64'
        $module = Get-EnvironmentModule
        $module | Should -BeNullOrEmpty   
    }   

    It 'Project Module can be removed with dependencies' {
        Import-EnvironmentModule 'Project-ProgramA'
        Remove-EnvironmentModule 'Project-ProgramA'
        $module = Get-EnvironmentModule
        $module | Should -BeNullOrEmpty   
    }     
}

Describe 'TestLoading_CustomPath_Directory' {

    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $PSScriptRoot "Modules\Project-ProgramB"
        Add-EnvironmentModuleSearchPath "Project-ProgramB" "Directory" $customDirectory
        Import-EnvironmentModule "Project-ProgramB"
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }    

    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -Not -BeNullOrEmpty
    }  
}

Describe 'TestLoading_CustomPath_Environment' {

    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $PSScriptRoot "Modules\Project-ProgramB"
        $env:TESTLADOING_PATH = "$customDirectory"
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "Environment" -Key "TESTLADOING_PATH"
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "Environment" -Key "UNDEFINED_VARIABLE"
        Import-EnvironmentModule "Project-ProgramB"
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }       

    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'SearchPath correctly returned' {
        $searchPaths = Get-EnvironmentModuleSearchPath "Project-ProgramB"
        $searchPaths.Count | Should -Be 2
        $searchPaths[0].Key | Should -Be "TESTLADOING_PATH"
    } 

    It 'Remove Search Path works correctly' {
        Remove-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Key "UNDEFINED_VARIABLE"
        $searchPaths = Get-EnvironmentModuleSearchPath "Project-ProgramB"
        $searchPaths.Count | Should -Be 1
    }     
}

Describe 'TestLoading_Environment_Subpath' {
    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $PSScriptRoot "Modules\Project-ProgramC"
        $env:PROJECT_PROGRAM_C_ROOT = "$customDirectory"
        Import-EnvironmentModule "Project-ProgramC"        
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    } 

    It 'Module is loaded correctly with sub-path' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramC"
        $module | Should -Not -BeNullOrEmpty
    }    
}

Describe 'TestLoading_InvalidCustomPath' {
    BeforeEach {
        Clear-EnvironmentModuleSearchPaths -Force
        $customDirectory = Join-Path $PSScriptRoot "Modules\Project-ProgramB_"
        Add-EnvironmentModuleSearchPath -ModuleFullName "Project-ProgramB" -Type "Directory" -Key $customDirectory
        Import-EnvironmentModule "Project-ProgramB"     
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }     

    It 'Module should not be loaded because of invalid root path' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramB"
        $module | Should -BeNullOrEmpty
    }    
}

Describe 'TestLoading_AbstractModule' {
    BeforeEach {  
        Import-EnvironmentModule "Project-ProgramA"          
    }
    AfterEach {
        Clear-EnvironmentModules -Force
    }      

    It 'Modules was not loaded' { 
        Clear-EnvironmentModules -Force
        try {
            Import-EnvironmentModule 'Abstract-Project'
        }
        catch {
        }         
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "Abstract-Project" 
        $module | Should -BeNullOrEmpty 
    }
    
    It 'Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Project-ProgramA"
        $module | Should -Not -BeNullOrEmpty
    }

    It 'Abstract Module is loaded correctly' {
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -eq "Abstract-Project"
        $module | Should -Not -BeNullOrEmpty
    }   

    It 'Abstract Module Functions are available' {
        $result = Get-ProjectRoot  # Call function of abstract module
        $result | Should -BeExactly "C:\Temp"
    }       
}

Describe 'TestCopy' {
    BeforeEach {          
    }    
    AfterEach {
        Clear-EnvironmentModules -Force
    }  

    It 'Modules was correctly copied and deleted afterwards' {   
        $module = Get-EnvironmentModule -ListAvailable "Project-ProgramA"
        $module | Should -Not -BeNullOrEmpty 
        Copy-EnvironmentModule Project-ProgramA "Project-ProgramACopy" (Resolve-Path (Join-Path $PSScriptRoot 'Modules'))
        $newModule = Get-EnvironmentModule -ListAvailable "Project-ProgramACopy"
        $newModule | Should -Not -BeNullOrEmpty

        $files = Get-ChildItem "$($newModule.ModuleBase)" | Select-Object -ExpandProperty "Name"
        $files | Should -Contain "ProjectRelevantFile.txt"
        
        Remove-EnvironmentModule -Delete -Force "Project-ProgramACopy"

        $newModule = Get-EnvironmentModule -ListAvailable "Project-ProgramACopy"
        $newModule | Should -BeNullOrEmpty
    }
}

Describe 'TestSwitch' {
    BeforeEach {         
        Import-EnvironmentModule 'Project-ProgramA' 
    }    
    AfterEach {
        Clear-EnvironmentModules -Force
    }     

    It 'Modules were loaded correctly' {   
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "NotepadPlusPlus-x86" 
        $module | Should -Not -BeNullOrEmpty 

        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "Cmd*" 
        $module | Should -Not -BeNullOrEmpty 
    }

    It 'Switch module works' {
        Switch-EnvironmentModule 'NotepadPlusPlus-x86' 'NotepadPlusPlus-x64'
        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "NotepadPlusPlus-x86" 
        $module | Should -BeNullOrEmpty 

        $module = Get-EnvironmentModule | Where-Object -Property "FullName" -like "NotepadPlusPlus-x64" 
        $module | Should -Not -BeNullOrEmpty         
    }

    It 'Meta function works' {
        $result = Start-Cmd 42
        $result | Should -BeExactly 42
    }
}

Describe 'TestGet' {
    BeforeEach {         
        Import-EnvironmentModule 'Project-ProgramA' 
    }    
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Correct style version is returned' {
        $module = Get-EnvironmentModule -ModuleFullName "Project-ProgramA" 
        ($module.StyleVersion) | Should -Be 2
    }
}

Describe 'TestCircularDependencies' {
    BeforeEach {         
        Import-EnvironmentModule 'DependencyBase' 
    }    
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Module was not loaded' {
        try {
            $modules = Get-EnvironmentModule -ModuleFullName "Dependency*"      
        }
        catch {
        }

        $modules | Should -BeNullOrEmpty
    }
}

Describe 'TestAlias' {
    BeforeEach {         
        Import-EnvironmentModule 'NotepadPlusPlus' 
    }    
    AfterEach {
        Clear-EnvironmentModules -Force
    }

    It 'Alias npp is loaded correctly' {
        $aliasInfos = Get-EnvironmentModuleAlias -ModuleFullName "NotepadPlusPlus*" 
        $aliasInfos.Length | Should -Be 1
        $aliasInfos[0].Name | Should -Be "npp"
    }
}

Describe 'TestFunctionStack' {
    BeforeEach {         
        Import-EnvironmentModule 'Project-ProgramA' 
    }    
    AfterEach {
        Clear-EnvironmentModules -Force
    }    

    It 'Function Stack has correct structure' {
        $knownFunctions = Get-EnvironmentModuleFunction -FunctionName "Start-Cmd"
        $knownFunctions | Should -HaveCount 2

        $knownFunctions[0].ModuleFullName | Should -Be "Cmd"
        $knownFunctions[1].ModuleFullName | Should -Be "Project-ProgramA"
    }

    It 'Function Stack invoke does work correctly' {
        $result = Invoke-EnvironmentModuleFunction "Start-Cmd" "Project-ProgramA" -ArgumentList "42"
        $result | Should -Be 42

        $result = Start-Cmd "42"
        $result | Should -Be 42     
        
        $result = Invoke-EnvironmentModuleFunction "Start-Cmd" "Cmd" -ArgumentList '/C "echo 45"'
        $result | Should -Be 45 
    }

    It 'Function Stack cleaned correctly' {
        Remove-EnvironmentModule 'Project-ProgramA'
        $knownFunctions = Get-EnvironmentModuleFunction -FunctionName "Start-Cmd"
        $knownFunctions | Should -HaveCount 0
    }
}