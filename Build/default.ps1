properties {
    $BaseDirectory = Resolve-Path ..     
    $BuildDirectory = "$BaseDirectory\Build"
    $SrcDirectory = "$BaseDirectory\Source"
    $Nuget = "$BaseDirectory\Tools\NuGet.exe"
	$SlnFile = "$SrcDirectory\Chill.sln"
	$pluginSource = "$BaseDirectory\Source\Plugins"
	$7zip = "$BaseDirectory\Tools\7z.exe"
	$PackageDirectory = "$BaseDirectory\Package"
	$MsBuildLoggerPath = ""
	$Branch = ""
}

task default -depends Clean, RestoreNuget, GetVersionNumber, ApplyAssemblyVersioning, ApplyPackageVersioning, Compile, RunTests, BuildZip, BuildPackage, PublishToMyget

task Clean {	
		
		Get-ChildItem $PackageDirectory -Filter *.nupkg -Recurse | ForEach { Remove-Item $_.FullName }
		Get-ChildItem $PackageDirectory -Filter *.zip -Recurse | ForEach { Remove-Item $_.FullName }
		Get-ChildItem $PackageDirectory -Filter *.dll -Recurse | ForEach { Remove-Item $_.FullName }
		Get-ChildItem $PackageDirectory -Filter *.xml -Recurse | ForEach { Remove-Item $_.FullName }
		Get-ChildItem $PackageDirectory -Filter *.pdb -Recurse | ForEach { Remove-Item $_.FullName }
}

task GetVersionNumber{
	$gitversion_path = FindTool("GitVersion.CommandLine.*\tools\GitVersion.exe")
        Write-Output "Running GitVersion on folder $BaseDirectory, $gitversion_path";
        
		$json = Invoke-Expression "$gitversion_path"
		Write-Output $json -join "`n";
                
        if ($LASTEXITCODE -eq 0) {
            $version = (ConvertFrom-Json ($json -join "`n"));

            
            $script:AssemblyVersion = $version.ClassicVersion;
            $script:InformationalVersion = $version.InformationalVersion;
            $script:NuGetVersion = $version.NugetVersionV2
			
			Write-Output "using AssemblyVersion: $AssemblyVersion, NugetVersion: $NuGetVersion"
        }
        else {
            Write-Output $json -join "`n";
        }
}

task ApplyAssemblyVersioning {
 	
	Get-ChildItem -Path $SrcDirectory -Filter "AssemblyInfo.cs" -Recurse -Force |
	foreach-object {  

		Set-ItemProperty -Path $_.FullName -Name IsReadOnly -Value $false
		Write-Output " updating assemblyInfo for $_.FullName to: $script:AssemblyVersion "
		
        $content = Get-Content $_.FullName
        
        if ($script:AssemblyVersion) {
    		Write-Output "Updating " $_.FullName "with version" $script:AssemblyVersion
    	    $content = $content -replace 'AssemblyVersion\("(.+)"\)', ('AssemblyVersion("' + $script:AssemblyVersion + '")')
            $content = $content -replace 'AssemblyFileVersion\("(.+)"\)', ('AssemblyFileVersion("' +$script:AssemblyVersion + '")')
        }
		
        if ($script:InfoVersion) {
    		Write-Output "Updating " $_.FullName "with information version" $script:InformationalVersion
            $content = $content -replace 'AssemblyInformationalVersion\("(.+)"\)', ('AssemblyInformationalVersion("' + $script:InformationalVersion + '")')
        }
        
	    Set-Content -Path $_.FullName $content
	}    
}

task ApplyPackageVersioning {

Get-ChildItem -Path $BaseDirectory -Filter ".nuspec" -Recurse -Force |
	foreach-object {  
		$fullName = $_.FullName
		Write-Output "Applying versioning to: $fullName. $script:NuGetVersion" 
	    Set-ItemProperty -Path $fullName -Name IsReadOnly -Value $false
		
	    $content = Get-Content $fullName
	    $content = $content -replace '<version>.*</version>', ('<version>' + "$script:NuGetVersion" + '</version>')
	    Set-Content -Path $fullName $content
	}
}
task RestoreNuget{
	& $Nuget restore $SlnFile
	& $Nuget install GitVersion.CommandLine
}

task Compile {
   
	    exec { msbuild /v:m /p:Platform="Any CPU" $SlnFile /p:Configuration=Release /t:Rebuild}
   
}

task RunTests {
	RunTest -category "core" -test_project "chill.net45.tests"
	RunTest -category "examples" -test_project "Chill.Examples.Tests"
	RunTest -category "core" -test_project "chill.net40.tests"
}

task BuildZip {

}

function RunTest {
	param(
		[string] $category,
		[string] $test_project
	)
	$testrunner_path	= FindTool("*\tools\xunit.console.exe")

	write-output "test runner: $testrunner_path"
	$arguments = "$SrcDirectory\$category\$test_project\bin\release\$test_project.dll"
		write-output $testrunner_path $arguments.Split(' ')
		& $testrunner_path $arguments.Split(' ')
}

task BuildPackage {

 remove-item $PackageDirectory\Chill\Lib\portable-net4+sl5+MonoAndroid1+MonoTouch1\System*

  & $Nuget pack "$PackageDirectory\Chill\.nuspec" -o "$PackageDirectory\Chill" 
  New-Item -ItemType Directory -Force -Path "$PackageDirectory\Chill.Autofac"
  & $Nuget pack "$pluginSource\Chill.Autofac\.nuspec" -o "$PackageDirectory\Chill.Autofac" 
  
  New-Item -ItemType Directory -Force -Path "$PackageDirectory\Chill.AutofacNSubstitute"
  & $Nuget pack "$pluginSource\Chill.AutofacNSubstitute\.nuspec" -o "$PackageDirectory\Chill.AutofacNSubstitute" 

  New-Item -ItemType Directory -Force -Path "$PackageDirectory\Chill.AutofacFakeItEasy"
  & $Nuget pack "$pluginSource\Chill.AutofacFakeItEasy\.nuspec" -o "$PackageDirectory\Chill.AutofacFakeItEasy" 

  New-Item -ItemType Directory -Force -Path "$PackageDirectory\Chill.Unity"
  & $Nuget pack "$pluginSource\Chill.Unity\.nuspec" -o "$PackageDirectory\Chill.Unity" 
  
    New-Item -ItemType Directory -Force -Path "$PackageDirectory\Chill.UnityNSubstitute"
  & $Nuget pack "$pluginSource\Chill.UnityNSubstitute\.nuspec" -o "$PackageDirectory\Chill.UnityNSubstitute" 

}

task PublishToMyget -precondition { return ($Branch -eq "master" -or $Branch -eq "<default>" -or $Branch -eq "develop") -and ($ApiKey -ne "") } {
}

function FindTool {
	param(
		[string] $name
	)

	$result = Get-ChildItem "$BaseDirectory\Source\packages\$name" | Select-Object -First 1

	return $result.FullName
}

