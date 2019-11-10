class ReportHandler
{

    # Properties
    [string]$ReportShortName
    [string]$ReportOutputType
    [string]$ReportOutputLocation
    [int]$RetryLimit = 2
    [int]$ReportStatus = 0
    [object]$RootObject
    [string]$RootDirectory
    [array]$SubDirectories
    
    [string]ConstructReportFile([string]$ReportShortName, [string]$ReportOutputType, [string]$ReportOutputLocation, [object]$RootObject)
    {
        $this.RootObject = $null
        $fullReportOutputPath = $null
        # Construct a new unique identifier
        $guid = New-Guid
        # Limit the unique identifier to (5) characters
        $guid = $guid.ToString().Substring(0,5)
        # Format the date as YearMonthDay
        $formattedDateTime = (Get-Date -Format "yyyyMMdd")
        $formattedReport = "{0}_{1}_{2}_{3}"
        if (Test-Path $ReportOutputLocation)
        {
            $_formattedReportName = $null
            if ($ReportOutputType -eq ".csv")
            {
                $_formattedReportName = ($formattedReport -f ($formattedDateTime, $guid, $ReportShortName, $ReportOutputType))
                $fullReportOutputPath = Join-Path -Path $ReportOutputLocation -ChildPath $_formattedReportName
                $this.RootObject = $RootObject
                $this.RootObject | Export-Csv -Path $fullReportOutputPath -NoTypeInformation -NoClobber
                
                return $_formattedReportName
            }
            elseif ($ReportOutputType -eq ".rpt")
            {
                $fullReportOutputPath = Join-Path -Path $ReportOutputLocation -ChildPath ($formattedReport -f ($formattedDateTime, $guid, $ReportShortName, $ReportOutputType))
                $this.RootObject = $RootObject
                $this.RootObject | Out-File -LiteralPath $fullReportOutputPath -Force
                
                return $_formattedReportName
            }
            else 
            {
                return "The file type provided is not supported as a report file type. Please select from the database reference."    
            }
        }
        else
        {
            return $Error[0].Exception.Message
        }
    }

    [void]SetupDropLocations([string]$RootDirectory, [object]$SubDirectories)
    {
        # if the path exists then process the setup
        if(Test-Path -Path $RootDirectory)
        {
            $this.RootDirectory = $RootDirectory
            
            # foreach sub directory see if the full path is valid and append
            foreach ($directory in $SubDirectories)
            {
                $_fullPathConstruct = Join-Path $this.RootDirectory -ChildPath $directory

                if (Test-Path $_fullPathConstruct)
                {
                    $this.SubDirectories += $directory
                }
                else
                {
                    continue
                }

                $_fullPathConstruct = $null
            }
        }
        else 
        {
            # Otherwise, throw an error
            throw "Invalid path provided : $($Error[0].Exception.Message)"    
        }
    }

    # Fetch the droplocation for the specified report
    [string]GetDropLocation([string]$ReportShortName)
    {
        $_reportContextName = $ReportShortName
        
        try
        {
            $_fetchDropLocation = $this.SubDirectories | Where-Object {$_ -like "*$($_reportContextName)*"}
            $_fullDropLocation = Join-Path $this.RootDirectory "$($_fetchDropLocation)\"
            
            return $_fullDropLocation
        }
        catch
        {
            throw $Error[0].Exception.Message
        }
    }

}