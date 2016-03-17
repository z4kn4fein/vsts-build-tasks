Param(
    [string][Parameter(Mandatory = $true)]
    $Path,
    [string][Parameter(Mandatory = $true)]
    $AssemblyVersion,
    [string][Parameter(Mandatory = $true)]
    $AssemblyFileVersion,
    [string][Parameter(Mandatory = $true)]
    $AssemblyInformationalVersion
)

# Import the Task.Common dll that has all the cmdlets we need for Build
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"

function Update-AssemblyInfo
{
    Param(
        [string]$assemblyVersion,
        [string]$assemblyFileVersion,
        [string]$assemblyInformationalVersion
    )

    $assemblyVersionPattern = 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $assemblyfileVersionPattern = 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $assemblyInformationalVersionPattern = 'AssemblyInformationalVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'

    $assemblyVersionReplacement = 'AssemblyVersion("' + $assemblyVersion + '")'
    $assemblyFileVersionReplacement = 'AssemblyFileVersion("' + $assemblyFileVersion + '")'
    $assemblyInformationalVersionReplacement = 'AssemblyInformationalVersion("' + $assemblyInformationalVersion + '")'
 

    foreach($assemblyFile in $input) {
        $fileName = $assemblyFile.FullName
        Write-Host "Patching AssemblyInfo in $fileName"

        (Get-Content $fileName) | ForEach-Object  { 
           % {$_ -replace $assemblyVersionPattern, $assemblyVersionReplacement } |
           % {$_ -replace $assemblyfileVersionPattern, $assemblyFileVersionReplacement } |
           % {$_ -replace $assemblyInformationalVersionPattern, $assemblyInformationalVersionReplacement }
        } | Out-File $fileName -Encoding UTF8 -Force
    }
}

function Update-AllAssemblyInfoFiles
{
   Param (
        [string]$assemblyVersion,
        [string]$assemblyFileVersion,
        [string]$assemblyInformationalVersion,
        [string]$path
   )

   Write-Host (Get-LocalizedString -Key "Searching {0} for AssemblyInfo files" -ArgumentList $path)
   Get-Childitem "$($env:BUILD_REPOSITORY_LOCALPATH)$path" -Recurse | Update-AssemblyInfo $assemblyVersion $assemblyFileVersion $assemblyInformationalVersion
}

Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"

Write-Verbose "Parameter values:"
foreach($key in $PSBoundParameters.Keys) {
    Write-Verbose ($key + ' = ' + $PSBoundParameters[$key])
}

# Extract the versions from the parameters.
function Find-Version
{
    [OutputType([string])]
    Param (
        [string]$Version,
        [string]$Description
    )

    $VersionData = [regex]::matches($Version, "\d+\.\d+\.\d+\.\d+")
    switch($VersionData.Count)
    {
        0
        {
            Write-Error (Get-LocalizedString -Key "Could not find version number data in {0} '{1}'." -ArgumentList $Description, $Version )
            exit 1
        }
        1 {}
        default
        {
            Write-Warning (Get-LocalizedString -Key "Found more than instance of version data in {0} '{1}'." -ArgumentList $Description, $Version)
            Write-Warning (Get-LocalizedString -Key "Will assume first instance is version.")
        }
    }

    Write-Verbose (Get-LocalizedString -Key "Found {0} '{1}'." -ArgumentList $Description, $VersionData[0])

    return $VersionData[0]
}

$AssemblyVersion = Find-Version $AssemblyVersion "AssemblyVersion"
$AssemblyFileVersion = Find-Version $AssemblyFileVersion "AssemblyFileVersion"
$AssemblyInformationalVersion = Find-Version $AssemblyInformationalVersion "AssemblyInformationalVersion"

Update-AllAssemblyInfoFiles $AssemblyVersion $AssemblyFileVersion $AssemblyInformationalVersion $Path

Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
