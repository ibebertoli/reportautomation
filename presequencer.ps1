<#
    .[SYNOPSIS]
        Pre-sequence routine script
    
    .[DEFINITION]
        Builds all objects, environmental variables, and threaded pre-routine sequences from database and local configuration files
    
    .[CHANGEHISTORY]
        Date             :             11-6-2019
        Developer        :             Brett Willever [ brett.willever@mckesson ]
        Revision Details :             Rendered definitions.json successfully
    
    .[PARAMETERS]
        No current parameters within this sequence script

#>

try 
{

# Dot source all handlers in one call
.   ".\handlers\BuildHandlers.ps1"

# Construct the environment from base64 environmental string
$Environment = Get-ScriptEnvironment "master.env"

# Get local configuration file
$LocalConfiguration = [ConfigurationHandler]::new()
$LocalConfiguration.BuildObject(".\config\", 
                                "$($Environment).json")

# Initialize database handler
# Arguments ::new(HostName, DatabaseName)
$DatabaseHandler = [DatabaseHandler]::new($LocalConfiguration.RootObject.Database.Server, 
                                          $LocalConfiguration.RootObject.Database.Database)

# Schemed definitions for events and iLogger
$DefinitionSchema = Get-Content ".\config\definitions.json" -Force -Raw | ConvertFrom-Json -Verbose

# Notify database that events and ilogger has been initilized
# Arguments : ILogger(LogLevel, LogSeverity, LogMessage)
$DatabaseHandler.ILogger($DefinitionSchema.ILoggerSchema.Levels.Info, 
                         $DefinitionSchema.ILoggerSchema.Severity.Normal, 
                        ($DefinitionSchema.ILoggerSchema.Definitions.Initialization -f $LocalConfiguration.RootObject.Database.Database))
}

catch {
    throw $Error[0].Exception.Message
}

# Start VersionDiscrepancyCheck event
# Arguments : Events(EventModule, EventAction, EventType, EventText)
$DatabaseHandler.Events($DefinitionSchema.EventSchema.Modules.ReportAutomation, 
                        $DefinitionSchema.EventSchema.Action.Routine,
                        $DefinitionSchema.EventSchema.Types.Insert,
                       ($DefinitionSchema.EventSchema.Definitions.InsertRecord -f "VersionDiscrepancyCheck"))

# Initialize remote configuration
# Arguments : GetConfig(ApplicationID)
$RemoteConfiguration = $DatabaseHandler.GetConfig($LocalConfiguration.RootObject.ApplicationID)

# Sort object by ValueName
# update this chaos... 
$_remoteVersion  = $RemoteConfiguration | Where-Object { $_.ValueName -eq "Version" }
$_rootDirectory  = $RemoteConfiguration | Where-Object { $_.ValueName -eq "RootDirectory"}

# See if the versions match
if ($LocalConfiguration.Version() -eq $_remoteVersion.Value)
{
    $masterVersion = $LocalConfiguration.Version()
}
else
{
    # if they do NOT match, set the master version to the local configuration
    $masterVersion = $LocalConfiguration.Version()

    # Log to database that the versions are out-of-sync and defaulting to local configuration
    $DatabaseHandler.ILogger($DefinitionSchema.ILoggerSchema.Levels.Info, 
                             $DefinitionSchema.ILoggerSchema.Severity.Warning, 
                            ($DefinitionSchema.ILoggerSchema.Definitions.Warning -f ("VersionDiscrepancyCheck", "There were version discrepancies between local and remote - (Local : $masterVersion ; Remote : $($_remoteVersion.Value). Defaulting to the LocalConfiguration : ($masterVersion)")))
}

# Fetch the list of active reports for this routine session
$ReportHandler = [ReportHandler]::new()
$ReportCatalog = $DatabaseHandler.ListReports()

# Construct full drop location strings
$ReportHandler.SetupDropLocations($_rootDirectory.Value,
                                  $DefinitionSchema.ReportSchema.SubDirectories)

foreach ($report in $ReportCatalog)
{
    try 
    {    # [string]$ReportShortName, [string]$ReportOutputType, [string]$ReportOutputLocation, [object]$RootObject
        $reportContextName = $ReportHandler.ConstructReportFile($report.ReportShortName, 
                                                                $report.ReportOutputType, 
                                                                $ReportHandler.GetDropLocation($report.ReportShortName), 
                                                                $DatabaseHandler.RawQuery("SELECT * from sys.tables")) #todo :update rawQuery() context from ARC

        # Add event
        $DatabaseHandler.Events($DefinitionSchema.EventSchema.Modules.ReportAutomation, 
                                $DefinitionSchema.EventSchema.Action.Routine,
                                $DefinitionSchema.EventSchema.Types.Insert,
                               ($DefinitionSchema.EventSchema.Definitions.InsertRecord -f "ReportExecution($($report.ReportShortName))"))

        # Add report history
        $DatabaseHandler.InsertRecordReportHistory($reportContextName,
                                                   $ReportHandler.GetDropLocation($report.ReportShortName), 
                                                   $DefinitionSchema.ReportSchema.Status.Complete)
    }
    catch 
    {
        # Catch ExecuteReader() exception and write it to the ILogger
        $DatabaseHandler.ILogger($DefinitionSchema.ILoggerSchema.Levels.Info, 
                                 $DefinitionSchema.ILoggerSchema.Severity.Error, 
                                ($DefinitionSchema.ILoggerSchema.Definitions.Error -f ("InsertRecordReportHistory()", $Error[0].Exception.Message)))

        # Catch ExecuteReader() exception and update the report state as error state
        $DatabaseHandler.InsertRecordReportHistory($reportContextName,
                                                   $ReportHandler.GetDropLocation($report.ReportShortName), 
                                                   $DefinitionSchema.ReportSchema.Status.ErrorState)
    }
}

# Start routine

# Validate routine

# End routine

# Send confirmation

# Clean script structure
$Environment            = $null
$LocalConfiguration     = $null
$RemoteConfiguration    = $null
$DatabaseHandler        = $null
$ReportHandler          = $null
$RoutineHandler         = $null
$masterVersion          = $null
$DefinitionSchema       = $null