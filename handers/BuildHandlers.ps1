
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase
$PublicFunctions = $null
$PrivateFunctions = $null
$AllFunctions = $null

# Dot source public/private functions
$PublicFunctions = @(Get-ChildItem -Path "$ScriptPath\public" -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path "$ScriptPath\private" -Filter *.ps1 -Recurse -ErrorAction SilentlyContinue)

$AllFunctions = $PublicFunctions + $PrivateFunctions
foreach ($Function in $AllFunctions) {
    try 
    {
        . $Function.FullName
    } 
    catch 
    {
        throw ('Unable to dot source {0}' -f $Function.FullName)
    }
}

function Get-ScriptEnvironment([string]$PathToEnvironment)
{
    try
    {
        [object]$_envFile = Get-Content -Path $PathToEnvironment
        [string]$_conversion = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_envFile))

        $_conversion = $_conversion.Substring(4) # char fetch by sizing

        return $_conversion
    }
    catch
    {
        return "Environment string empty"
    }
}

function Update-ScriptEnvironment([string]$PathToEnvironment, [string]$EnvironmentContext)
{
    try
    {
        [object]$_envFile = Get-Item "master.env"
    
        $_envFile | Clear-Content -Force
    
        [string]$_base64String = $EnvironmentContext
    
        [string]$_conversion = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($_base64String))
    
        $_conversion | Out-File -FilePath $_envFile
    }
    catch
    {
        return $Error[0].Exception.Message
    }
}