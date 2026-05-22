
# Host declaration : 

$HOSTNAME1 = "ipaddress"
$HOSTNAME2 = "ipaddress"
$HOSTNAME3 = "ipaddress"
$HOSTNAME4 = "ipaddress"
$HOSTNAME5 = "ipaddress"
$HOSTNAME6 = "ipaddress"


# Object declaration :


"Network connectivity test"


$Servers = @(
    [PSCustomObject]@{
        'Server Name' = 'HOSTNAME'
        IPAddress = 'ipaddress'
        Port = targetport
    }
    [PSCustomObject]@{
        'Server Name' = 'HOSTNAME'
        IPAddress = 'ipaddress'
        Port = targetport
    }
    [PSCustomObject]@{
        'Server Name' = 'HOSTNAME'
        IPAddress = 'ipaddress'
        Port = targetport
    }
    [PSCustomObject]@{
        'Server Name' = 'HOSTNAME'
        IPAddress = 'ipaddress'
        Port = targetport
    }
    [PSCustomObject]@{
        'Server Name' = 'HOSTNAME'
        IPAddress = 'ipaddress'
        Port = targetport
    }
    [PSCustomObject]@{
        'Server Name' = 'HOSTNAME'
        IPAddress = 'ipaddress'
        Port = targetport
    }
    [PSCustomObject]@{
        'Server Name' = 'HOSTNAME'
        IPAddress = 'ipaddress'
        Port = targetport
    }
)

# ICMP Request

$report_connection = foreach ($Server in $Servers) {

    # Data collect in object

    $result_connection = [PSCustomObject]@{
        Name   = $Server.'Server Name'
        IP     = $Server.IPAddress
        Online = $false
        TCP_Port = $false
    }


    if (Test-Connection -ComputerName $Server.IPAddress -Count 1 -Quiet) {

        # If connection is good, passing in TRUE

        $Result_connexion.Online = $true
    }


    if (Test-NetConnection -ComputerName $Server.IPAddress -Port $Server.Port) {

        # If connection is good, passing in TRUE

        $Result_connexion.TCP_Port = $true
    }
   
    $Result_connexion
}


#Report generation with data collection :  


$report_connexion | Select-Object Name, IP, Online, TCP_Port

#Export in a CSV file :

$report_connexion | Export-Csv -Path network-report.csv -NoTypeInformation
