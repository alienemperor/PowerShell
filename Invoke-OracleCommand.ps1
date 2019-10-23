Function Invoke-OracleCmd {
    param(
        [Parameter(Mandatory=$true)]$DBName, 
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$SQL, 
        #[Parameter(Mandatory=$false)]$Parameters,
        [Parameter(Mandatory=$true)]$Credential
    )

    #import dependencies

    add-type -path Oracle.DataAccess.dll

    #start connection (Database and Credentials)

    try {
        $con = New-Object -TypeName Oracle.DataAccess.Client.OracleConnection
        $con.ConnectionString = "Data Source ="+$DBName+";User ID="+$credential.GetNetworkCredential().Username+";Password="+$credential.GetNetworkCredential().password 

        $con.open()

        $result = "Connected to database: {0} running on host: {1} - Servicename: {2} -Serverversion: {3}" -f `

        $con.DataBaseName, $con.Hostname, $con.ServiceName, $con.ServerVersion

        Write-Log "Connection created successfully"
        Write-Log $result
        Write-host $result
    }catch{
        $result = ("Can't open connection: {0}`n{1}" -f `
        
            $con.ConnectionString, $_.Exception.ToString())
        Write-Log "Could not connect to database."
        Write-Log $_.Exception.ToString()
        Write-Host $result
    }

    #create command (from SQL and Parameter)

    $cmd = $con.CreateCommand()
    $cmd.CommandText = $SQL
    $dataset = $null
    Write-Log $SQL

    #decide if query or non-query
    if ($SQL -like "*SELECT*"){
    #If Query:
        Write-Log "Executing command as query"
        try {
            $rdr = $cmd.ExecuteReader()
            Write-Log "The query Executed Successfully"
        }catch{
            Write-Log "The Command failed."
            Write-Log ($_.Exception.ToString())
            Write-Error ($_.Exception.ToString())
        }

        $fields = @()
        for ($i=0;$i -lt $rdr.FieldCount;$i++){
            $fields += $rdr.GetName($i)
        }

        $dataset = @()
        try{
            while ($rdr.read()){
            
                $data = New-Object -TypeName PSCustomObject
                for ($i=0; $i -lt $fields.count;$i++){
                    $value = $rdr.GetValue($i)
                    $name  = $fields[$i]
                    try{
                        $data | Add-Member -MemberType NoteProperty -Name $name -Value $value
                    }catch{
                        $name = $name+"$i"
                        $data | Add-Member -MemberType NoteProperty -Name $name -Value $value
                    }
                }
            $dataset += $data
            }
        }Catch{
            Write-Log "There was an error reading query data"
            Write-Log ($_.Exception.ToString())
            Write-Error ($_.Exception.ToString())

        }
        $rdr.Dispose()

    }else{
    #if Non-Query
        try{
            $rows = $cmd.ExecuteNonQuery()
            $dataset = "$rows rows affected."
            Write-Log "Command executed successfully: $dataset"
        }catch{
            Write-Log "The command failed"
            Write-Log ($_.Exception.ToString())
        }

    }
        try { 
            $con.close()
            $con.Dispose()
            Write-Log "Connection to database closed"
        }Catch{
            Write-Log "The connection could not be closed"
            Write-Log ($_.Exception.ToString())
        }
        return $dataset
    }

