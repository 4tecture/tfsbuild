# Enable -Verbose option
[CmdletBinding()]
param ( [string]$majorVersion = $env:MajorVersion,
        [string]$minorVersion = $env:MinorVersion,
        [string]$buildVersion = "$((Get-Date).ToString("yy"))$((Get-Date).DayOfYear.ToString("000"))"
)

# Read version from current build number
$VersionRegex = "\d+\.\d+\.\d+\.\d+"
$VersionData = [regex]::matches($Env:BUILD_BUILDNUMBER,$VersionRegex)[0]
$buildNumberTokens = $VersionData[0].ToString().Split('.')    

# set major version if needed
if($buildNumberTokens[0] -eq "0"){
    $buildNumberTokens[0] = $env:MajorVersion
}
    
# get the current sprint and use sprint number as build number
$urlIteration = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/work/teamsettings/iterations?`$timeframe=current&api-version=v2.0-preview"
Write-Host "URL: $urlIteration"
$currentIterationResponse = Invoke-RestMethod -Uri $urlIteration -Headers @{
    Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
}

Write-Host "Iteration Name: $($currentIterationResponse.Value.name)"
$iterationNumber = [regex]::matches($currentIterationResponse.Value.name,"\d+")[0].ToString()
Write-Host "Iteration Number: $($iterationNumber)"

if($buildNumberTokens[1] -eq "0"){
    $buildNumberTokens[1] = $iterationNumber
    Write-Host "##vso[task.setvariable variable=MinorVersion;]$iterationNumber"
}

# set the build version
if($buildNumberTokens[2] -eq "0"){
    $buildNumberTokens[2] = $buildVersion
}

# set revision number to build id (unique id)
if($buildNumberTokens[3] -eq "0"){
    #$buildNumberTokens[3] = (([int]$lastBuildNumber.Split('.')[3])+1)
    $buildNumberTokens[3] = $env:BUILD_BUILDID
}

# update the build number to the above values
$buildNumberAssemblyVersion = [string]::Format("{0}.{1}.{2}.{3}",$buildNumberTokens[0],$buildNumberTokens[1], $buildNumberTokens[2], $buildNumberTokens[3])
$NewBuildNumber = $Env:BUILD_BUILDNUMBER -replace $VersionRegex, $buildNumberAssemblyVersion 

Write-Host "New Build Number: $($NewBuildNumber)"
Write-Host "##vso[build.updatebuildnumber]$($NewBuildNumber)"