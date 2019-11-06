class ConfigurationHandler
{

    # Properties
    [string]$DirectoryPath
    [string]$FileName
    [string]$ScriptVersion
    [int]$RetryLimit = 2
    [bool]$ConfigurationLocked = $false
    [object]$RootObject
    [bool]$IsRemoteConfiguration = $false
    
    # Constructor - Literally a constructor function
    [void]BuildObject([String]$DirectoryPath,[String]$FileName)
    { 
           $fullPath = Join-Path $DirectoryPath -ChildPath $FileName
            
            if(Test-Path -Path $fullPath)
            {
                $this.DirectoryPath = $DirectoryPath
                $this.FileName = $FileName 
                
                try
                {
                    $_seekObject = Get-Content -Path $fullPath -Force -Verbose | ConvertFrom-Json -Verbose # todo: take in other extentions
                    
                    Start-Sleep -Milliseconds 300
    
                    $this.RootObject = $_seekObject
                }
                catch
                {
                    throw $Error[0].Exception.Message
                }
            }
            else 
            {
                throw $Error[0].Exception.Message
            }
    }

     # Constructor - Script Version local
     [string]Version()
     { 
        try 
        {
            $returnString = $this.RootObject.ScriptVersion.ToString()
            return $returnString
        }
        catch {
            return "Error trying to return the script version"
        }
     }

}
