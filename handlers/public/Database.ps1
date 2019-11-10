class DatabaseHandler
{

    # Properties
    [string]$SQLServer
    [string]$Database
    [string]$Query
    [string]$QueryFile
    [string]$Path
    [int]$ConnectionTimeout = 5
    [int]$CommandTimeout = 600
    # Connection string keywords: https://msdn.microsoft.com/en-us/library/system.data.sqlclient.sqlconnection.connectionstring(v=vs.110).aspx
    [string]$ConnectionString
    [object]$SQLConnection
    [object]$SQLCommand
    hidden $SQLReader
    [System.Data.DataTable]$Result
    [System.Data.DataTable]$Tables
    [System.Data.DataTable]$Views
    [bool]$DisplayResults = $True
    
     # Constructor -empty object
    DatabaseHandler ()
    { 
        Return 
    }
    
    # Constructor - sql server and database
    DatabaseHandler ([String]$SQLServer,[String]$Database)
    { 
        $this.SQLServer = $SQLServer
        $this.Database = $Database
    }

    # Constructor - sql server, database and query
    DatabaseHandler ([String]$SQLServer,[String]$Database,[string]$Query)
    { 
        $this.SQLServer = $SQLServer
        $this.Database = $Database
        $this.Query = $Query
    }

    # Method
    LoadQueryFromFile([String]$Path)
    {
       if (Test-Path $Path)
       {
        if ([IO.Path]::GetExtension($Path) -ne ".sql")
        {
            throw "'$Path' does not have an '.sql' extension'"
        }
        else
        {
            try
            {
                [String]$this.Query = Get-Content -Path $Path -Raw -ErrorAction Stop
                [String]$this.QueryFile = $Path
            }
            catch
            {
                $_
            }
        }

       } 
       else
       {
         throw [System.IO.FileNotFoundException] "'$Path' not found"
       }
    }

    # Method
    [Object] Execute()
    {
        if ($this.SQLConnection)
        {
            $this.SQLConnection.Dispose()
        }

        if ($this.ConnectionString)
        {

        }
        else
        {
            $this.ConnectionString = "Server=$($this.SQLServer);Database=$($this.Database);Integrated Security=SSPI;Connection Timeout=$($this.ConnectionTimeout)"
        }

        $this.SQLConnection = [System.Data.SqlClient.SqlConnection]::new()
        $this.SQLConnection.ConnectionString = $this.ConnectionString

        try
        {
            $this.SQLConnection.Open()
        }
        catch
        {
            return $Error[0].Exception.Message
        }

        try
        {
            $this.SQLCommand = $this.SQLConnection.CreateCommand()
            $this.SQLCommand.CommandText = $this.Query
            $this.SQLCommand.CommandTimeout = $this.CommandTimeout
            $this.SQLReader = $this.SQLCommand.ExecuteReader()
        }
        catch
        {
            $this.SQLConnection.Close()
            return $Error[0].Exception.Message      
        }

        if ($this.SQLReader)
        {
            $this.Result = [System.Data.DataTable]::new()
            $this.Result.Load($this.SQLReader)
            $this.SQLConnection.Close()
        }

        if ($this.DisplayResults)
        {
            Return $this.Result
        }
        else
        {
            Return $null
        }

    }


    # Method
    [object] ListReports()
    {
        if ($this.ConnectionString)
        {
            $ReportConnectionString = $this.ConnectionString
        }
        else
        {
            $ReportConnectionString = "Server=$($this.SQLServer);Database=$($this.Database);Integrated Security=SSPI;Connection Timeout=$($this.ConnectionTimeout)"
        }

        $ReportSQLConnection = [System.Data.SqlClient.SqlConnection]::new()
        $ReportSQLConnection.ConnectionString = $ReportConnectionString

        try
        {
            $ReportSQLConnection.Open()
        }
        catch
        {
            return $Error[0].Exception.Message 
        }

        try
        {
            $ReportQuery = "select * from dbo.ReportMaster with(nolock)"
            
            $ReportSQLCommand = $ReportSQLConnection.CreateCommand()
            $ReportSQLCommand.CommandText = $ReportQuery
            $ReportSQLCommand.CommandTimeout = $this.CommandTimeout
            $ReportSQLReader = $ReportSQLCommand.ExecuteReader()
        }
        catch
        {
            $ReportSQLConnection.Close()
            $ReportSQLConnection.Dispose()
            return $Error[0].Exception.Message          
        }

        if ($ReportSQLReader)
        {
            $this.Tables = [System.Data.DataTable]::new()
            $this.Tables.Load($ReportSQLReader)
            $ReportSQLConnection.Close()
            $ReportSQLConnection.Dispose()
        }

        if ($this.DisplayResults)
        {
            return $this.Tables
        }
        else
        {
            Return $null
        }

    }

    
    # Method
    [Object] RawQuery([string]$query)
    {

        if ($this.ConnectionString)
        {
            $TableConnectionString = $this.ConnectionString
        }
        else
        {
            $TableConnectionString = "Server=$($this.SQLServer);Database=$($this.Database);Integrated Security=SSPI;Connection Timeout=$($this.ConnectionTimeout)"
        }

        $TableSQLConnection = [System.Data.SqlClient.SqlConnection]::new()
        $TableSQLConnection.ConnectionString = $TableConnectionString

        try
        {
            $TableSQLConnection.Open()
        }
        catch
        {
            return $Error[0].Exception.Message 
        }

        try
        {
            $TableQuery = $query
            
            $TableSQLCommand = $TableSQLConnection.CreateCommand()
            $TableSQLCommand.CommandText = $TableQuery
            $TableSQLCommand.CommandTimeout = $this.CommandTimeout
            $TableSQLReader = $TableSQLCommand.ExecuteReader()
        }
        catch
        {
            $TableSQLConnection.Close()
            $TableSQLConnection.Dispose()
            return $Error[0].Exception.Message          
        }

        if ($TableSQLReader)
        {
            $this.Tables = [System.Data.DataTable]::new()
            $this.Tables.Load($TableSQLReader)
            $TableSQLConnection.Close()
            $TableSQLConnection.Dispose()
        }

        if ($this.DisplayResults)
        {
            Return $this.Tables
        }
        else
        {
            Return $null
        }

    }

    # ILogger Method
    [Object] ILogger([int]$LogLevel, [int]$LogSeverity, [string]$message)
    {

        if ($this.ConnectionString)
        {
            $ILoggerConnectionString = $this.ConnectionString
        }
        else
        {
            $ILoggerConnectionString = "Server=$($this.SQLServer);Database=$($this.Database);Integrated Security=SSPI;Connection Timeout=$($this.ConnectionTimeout)"
        }

        $ILoggerSQLConnection = [System.Data.SqlClient.SqlConnection]::new()
        $ILoggerSQLConnection.ConnectionString = $ILoggerConnectionString

        try
        {
            $ILoggerSQLConnection.Open()
        }
        catch
        {
            return $Error[0].Exception.Message 
        }

        try
        {
            $ILoggerMessage = "EXEC sp_ups_AutomationILoggerAddRecord $LogLevel, $LogSeverity, '$message'"
            
            $ILoggerSQLCommand = $ILoggerSQLConnection.CreateCommand()
            $ILoggerSQLCommand.CommandText = $ILoggerMessage
            $ILoggerSQLCommand.CommandTimeout = $this.CommandTimeout
            $ILoggerSQLReader = $ILoggerSQLCommand.ExecuteReader()
        }
        catch
        {
            $ILoggerSQLConnection.Close()
            $ILoggerSQLConnection.Dispose()
            return $Error[0].Exception.Message          
        }

        if ($ILoggerSQLReader)
        {
            $this.Tables = [System.Data.DataTable]::new()
            $this.Tables.Load($ILoggerSQLReader)
            $ILoggerSQLConnection.Close()
            $ILoggerSQLConnection.Dispose()
        }

        if ($this.DisplayResults)
        {
            Return $this.Tables
        }
        else
        {
            Return $null
        }

    }

    # Events Method
    [Object] Events([int]$EventModule, [int]$EventAction, [string]$EventType, [string]$EventText)
    {

        if ($this.ConnectionString)
        {
            $EventsConnectionString = $this.ConnectionString
        }
        else
        {
            $EventsConnectionString = "Server=$($this.SQLServer);Database=$($this.Database);Integrated Security=SSPI;Connection Timeout=$($this.ConnectionTimeout)"
        }

        $EventsSQLConnection = [System.Data.SqlClient.SqlConnection]::new()
        $EventsSQLConnection.ConnectionString = $EventsConnectionString

        try
        {
            $EventsSQLConnection.Open()
        }
        catch
        {
            return $Error[0].Exception.Message 
        }

        try
        {
            $EventsMessage = "EXEC sp_ups_AutomationEventsAddRecord {0}, {1}, {2}, '{3}'" -f ($EventModule, 
                                                                                              $EventAction, 
                                                                                              $EventType, 
                                                                                              $EventText)
            
            $EventsSQLCommand = $EventsSQLConnection.CreateCommand()
            $EventsSQLCommand.CommandText = $EventsMessage
            $EventsSQLCommand.CommandTimeout = $this.CommandTimeout
            $EventsSQLReader = $EventsSQLCommand.ExecuteReader()
        }
        catch
        {
            $EventsSQLConnection.Close()
            $EventsSQLConnection.Dispose()
            return $Error[0].Exception.Message          
        }

        if ($EventsSQLReader)
        {
            $this.Tables = [System.Data.DataTable]::new()
            $this.Tables.Load($EventsSQLReader)
            $EventsSQLConnection.Close()
            $EventsSQLConnection.Dispose()
        }

        if ($this.DisplayResults)
        {
            Return $this.Tables
        }
        else
        {
            Return $null
        }

    }

    # GetConfig Method
    [Object] GetConfig([int]$ApplicationID)
    {

        if ($this.ConnectionString)
        {
            $ConfigConnectionString = $this.ConnectionString
        }
        else
        {
            $ConfigConnectionString = "Server=$($this.SQLServer);Database=$($this.Database);Integrated Security=SSPI;Connection Timeout=$($this.ConnectionTimeout)"
        }

        $ConfigSQLConnection = [System.Data.SqlClient.SqlConnection]::new()
        $ConfigSQLConnection.ConnectionString = $ConfigConnectionString

        try
        {
            $ConfigSQLConnection.Open()
        }
        catch
        {
            return $Error[0].Exception.Message   
        }

        try
        {
            $ConfigQuery = "EXEC sp_GetApplicationConfiguration {0}" -f ($ApplicationID)
            
            $ConfigSQLCommand = $ConfigSQLConnection.CreateCommand()
            $ConfigSQLCommand.CommandText = $ConfigQuery
            $ConfigSQLCommand.CommandTimeout = $this.CommandTimeout
            $ConfigSQLReader = $ConfigSQLCommand.ExecuteReader()
        }
        catch
        {
            $ConfigSQLConnection.Close()
            $ConfigSQLConnection.Dispose()
            return $Error[0].Exception.Message          
        }

        if ($ConfigSQLReader)
        {
            $this.Tables = [System.Data.DataTable]::new()
            $this.Tables.Load($ConfigSQLReader)
            $ConfigSQLConnection.Close()
            $ConfigSQLConnection.Dispose()
        }

        if ($this.DisplayResults)
        {
            Return $this.Tables
        }
        else
        {
            Return $null
        }

    }

    # Insert into Reporthistory table
    #ReportFileContextName	
        # ReportOutputPath		
        # ReportStatus			
        # ReportCompletionDateTime
        
    [void]InsertRecordReportHistory([string]$ReportFileContextName, [string]$ReportOutputPath, [int]$ReportStatus)
    {

        if ($this.ConnectionString)
        {
            $ReportHistoryConnectionString = $this.ConnectionString
        }
        else
        {
            $ReportHistoryConnectionString = "Server=$($this.SQLServer);Database=$($this.Database);Integrated Security=SSPI;Connection Timeout=$($this.ConnectionTimeout)"
        }

        $ReportHistorySQLConnection = [System.Data.SqlClient.SqlConnection]::new()
        $ReportHistorySQLConnection.ConnectionString = $ReportHistoryConnectionString

        try
        {
            $ReportHistorySQLConnection.Open()
        }
        catch
        {
            throw $Error[0].Exception.Message   
        }

        try
        {
            $ReportHistoryQuery = "EXEC sp_ReportHistoryAddRecord '{0}', '{1}', {2}" -f ($ReportFileContextName, 
                                                                                         $ReportOutputPath, 
                                                                                         $ReportStatus)
            
            $ReportHistorySQLCommand = $ReportHistorySQLConnection.CreateCommand()
            $ReportHistorySQLCommand.CommandText = $ReportHistoryQuery
            $ReportHistorySQLCommand.CommandTimeout = $this.CommandTimeout
            $ReportHistorySQLReader = $ReportHistorySQLCommand.ExecuteReader()
        }
        catch
        {
            $ReportHistorySQLConnection.Close()
            $ReportHistorySQLConnection.Dispose()
            throw $Error[0].Exception.Message          
        }

        if ($ReportHistorySQLReader)
        {
            $this.Tables = [System.Data.DataTable]::new()
            $this.Tables.Load($ReportHistorySQLReader)
            $ReportHistorySQLConnection.Close()
            $ReportHistorySQLConnection.Dispose()
        }

        if ($this.DisplayResults)
        {
            
        }
        else
        {
        }

    }
}