param(
    [Parameter(Mandatory=$true)]
    [string]$TargetDirectory, 
    [boolean]$UpdateSolution=$true,
    [string]$VSSolutionVersion="15.0.26014.0",
    [boolean]$DeleteOriginalProjectFile=$true

)

function UpdateSolutionTooling() {

    $solutionsToConvert = Get-ChildItem -Recurse -Filter *.sln -Path $TargetDirectory
    if ($solutionsToConvert.Length -eq 0) {
        Write-Host "No solutions found to update"
        exit 1
    }
    #Edge case, but this will process more than one solution if more than one exists
    foreach ($solutionToConvert in $solutionsToConvert) {
        $solutionFolder = [System.IO.Path]::GetDirectoryName($solutionToConvert.FullName)
        Push-Location $solutionFolder

        (Get-Content ($solutionToConvert.FullName)) | Foreach-Object {$_ -replace '^VisualStudioVersion.*$', ("VisualStudioVersion = " + $VSSolutionVersion)} | Set-Content  ($solutionToConvert.FullName)

        Pop-Location
    }
}

function ProcessOriginalProjectFile($projectToConvert){

    if($DeleteOriginalProjectFile){
        Remove-Item $projectToConvert.FullName
    }
    else{
        Copy-Item $projectToConvert.FullName  "$projectDirectory\$projectToConvert.old"
        Remove-Item $projectToConvert.FullName  
    }

}

function CreateFinalProjectXml($projectToConvert){
    [xml] $projectXml = New-Object System.XML.XMLDocument
    $projectNode = $projectXml.CreateElement('Project','')
    $projectNode.SetAttribute("Sdk","Microsoft.NET.Sdk")
    $projectNode.SetAttribute("ToolsVersion","15.0")

    $propertyGroupNode = $projectXml.CreateElement('PropertyGroup','')
    $targetFrameworkNode = $projectXml.CreateElement('TargetFramework','')
    $propertyGroupNode.AppendChild($targetFrameworkNode)
    $projectNode.AppendChild($propertyGroupNode)

    $projectXml.AppendChild($projectNode)
    $projectXml.Save($projectToConvert.FullName)

}

function SetTargetFramework($project, $oldProjectXml) {
    $targetFrameworkVersion = $oldProjectXml.Project.PropertyGroup.TargetFrameworkVersion | Select-Object -First 1


    switch($targetFrameworkVersion) {
        "v4.5.1" {
            $project.Project.PropertyGroup.TargetFramework = "net451"
            return
        }
        "v4.5.2" {
            $project.Project.PropertyGroup.TargetFramework = "net452"
            return
        }
        "v4.6.1" {
            $project.Project.PropertyGroup.TargetFramework = "net461"
            return
        }
        "v4.6.2" {
            $project.Project.PropertyGroup.TargetFramework = "net462"
            return
        }

    }

    Write-Warning "Unknown target framework version $targetFrameworkVersion"
}

function ProcessPackageReferences($project, $projectDirectory) {

    $packagesConfigPath = Join-Path $projectDirectory "packages.config"
    if (Test-Path $packagesConfigPath) {

        $packagesConfig = [xml](Get-Content $packagesConfigPath -Encoding UTF8)
        
        if($packagesConfig -ne $null -and $packagesConfig.packages.HasChildNodes){
            $itemGroup = $project.CreateElement("ItemGroup")
            $project.Project.AppendChild($itemGroup) | Out-Null

            foreach ($packageReference in $packagesConfig.packages.package) {
                $packageReferenceElement = $project.CreateElement("PackageReference")
                $packageReferenceElement.SetAttribute("Include", $packageReference.id) | Out-Null
                $packageReferenceElement.SetAttribute("Version", $packageReference.version) | Out-Null
                $itemGroup.AppendChild($packageReferenceElement) | Out-Null
            }
        }
        
        Remove-Item $packagesConfigPath
    }

}

function ProcessProjectReferences($project, $oldProjectXml) {
    $projectReferences = $oldProjectXml.Project.ItemGroup.ProjectReference | Where-Object { $_.Include -ne $null}
    
    if($projectReferences -ne $null -and $projectReferences.HasChildNodes){
        $itemGroup = $project.CreateElement("ItemGroup")
        $project.Project.AppendChild($itemGroup) | Out-Null
        
        foreach ($projectReference in $projectReferences){
            $projectReferenceElement = $project.CreateElement("ProjectReference")
            $projectReferenceElement.SetAttribute("Include", $projectReference.Include)
            $itemGroup.AppendChild($projectReferenceElement) | Out-Null
        }
    }
}

function ProcessAssemblyReferences($project, $oldProjectXml) {
    $assemblyReferences = $oldProjectXml.Project.ItemGroup.Reference | Where-Object {
        ($_.HintPath -ne $null -and $_.HintPath -notlike "packages*") -or ($_.HintPath -eq $null)
    }

    if($assemblyReferences.Count -gt 0){
        $itemGroup = $project.CreateElement("ItemGroup")
        $project.Project.AppendChild($itemGroup) | Out-Null

        foreach ($assemblyReference in $assemblyReferences) {
            if ($assemblyReference.Include -eq $null) {
                continue
            }
            
            $assemblyReferenceElement = $project.CreateElement("Reference")
            $assemblyReferenceElement.SetAttribute("Include", $assemblyReference.Include)
            if ($assemblyReference.HintPath -ne $null) {
                $hintPathElement = $project.CreateElement("HintPath")
                $hintPathElement.InnerText = $assemblyReference.HintPath
                $assemblyReferenceElement.AppendChild($hintPathElement) | Out-Null
            }

            $itemGroup.AppendChild($assemblyReferenceElement) | Out-Null
        }
    }
}

function ProcessFileReferences($project, $oldProjectXml) {

    #Type Compile
    $projectFilesCompile = $oldProjectXml.Project.ItemGroup.Compile | Where-Object { $_.Include -ne $null}
    BuildFileReferences $project $projectFilesCompile "Compile"

    #Type Embedded Resource
    $projectFilesEmbeddedResource = $oldProjectXml.Project.ItemGroup.EmbeddedResource | Where-Object { $_.Include -ne $null}
    BuildFileReferences $project $projectFilesEmbeddedResource "EmbeddedResource"

    #Type Content
    $projectFilesContent = $oldProjectXml.Project.ItemGroup.Content | Where-Object { $_.Include -ne $null}
    BuildFileReferences $project $projectFilesContent "Content"

    #Type None
    $projectFilesNone = $oldProjectXml.Project.ItemGroup.None | Where-Object { $_.Include -ne $null}
    BuildFileReferences $project $projectFilesNone "None"

}

function BuildFileReferences($project, $projectFiles, $typeName) {
    if($projectFiles.Count -gt 0){
        $itemGroup = $project.CreateElement("ItemGroup") 
        $project.Project.AppendChild($itemGroup) | Out-Null
        
        foreach ($projectFile in $projectFiles) {
            if($projectFile.Include -ne "packages.config" -and $projectFile.Include -ne "Properties\AssemblyInfo.cs") {
                $projectFilesElement = $project.CreateElement($typeName)
                $projectFilesElement.SetAttribute("Include", $projectFile.Include)
                if($projectNone.Link -ne $null) {
                    $projectFileElementLink = $project.CreateElement("Link") 
                    $projectFileElementLink.InnerText = $projectFile.FirstChild.InnerText
                    $projectFilesElement.AppendChild($projectFileElementLink) | Out-Null
                }
                $itemGroup.AppendChild($projectFilesElement) | Out-Null
            }
        }
    }

}

function CleanupLegacyFiles($projectDirectory) {
    $assemblyInfoPath = Join-Path (Join-Path $projectDirectory "Properties") "AssemblyInfo.cs"
    if (Test-Path $assemblyInfoPath) {
        Remove-Item $assemblyInfoPath
    }

    #More here
}

#MAIN

if (!(Test-Path $TargetDirectory)) {
    Write-Host "Target directory $TargetDirectory does not exist."
    exit 1
}

if($UpdateSolution){
    UpdateSolutionTooling
}

$projectsToConvert = Get-ChildItem -Recurse -Filter *.csproj -Path $TargetDirectory
if ($projectsToConvert.Length -eq 0) {
    Write-Host "No projects found in target directory $TargetDirectory"
    exit 1
}

foreach ($convertedProject in $projectsToConvert) {

    $oldProjectXml = [xml](Get-Content $convertedProject.FullName -Encoding UTF8)
    $projectDirectory = [System.IO.Path]::GetDirectoryName($convertedProject.FullName)
    Push-Location $projectDirectory

    ProcessOriginalProjectFile $convertedProject

    CreateFinalProjectXml $convertedProject

    $finalproject = [xml](Get-Content $convertedProject -Encoding UTF8)
    
    SetTargetframework $finalproject $oldProjectXml

    ProcessPackageReferences $finalproject $projectDirectory

    ProcessProjectReferences $finalproject $oldProjectXml

    ProcessAssemblyReferences $finalproject $oldProjectXml

    ProcessFileReferences $finalproject $oldProjectXml

    CleanupLegacyFiles $projectDirectory

    $finalproject.Save((Resolve-Path $convertedProject.FullName))
    Pop-Location
}