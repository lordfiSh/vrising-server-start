
# Script by lordfiSh - https://github.com/lordfiSh/vrising-server-start

$discord_notifaction=0
$discord_webhook="https://discord.com/api/webhooks/XXXX"

# ----------------------
$version="0.1"

$servername=(Get-Item $PSCommandPath).Basename
$servername = $servername.replace(" ","")
$date = Get-Date -Format "dd.MM HH:mm"
$public_ipv4 = Invoke-RestMethod -Uri ('http://ipinfo.io/'+(Invoke-WebRequest -uri "http://ifconfig.me/ip").Content)
$public_ipv4 = $public_ipv4.ip
$local_ipv4 = (Get-NetIPAddress | Where-Object {$_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00"}).IPAddress
$router_ipv4 = (Get-wmiObject Win32_networkAdapterConfiguration | ?{$_.IPEnabled}).DefaultIPGateway



if (-not (Test-Path -Path $PSScriptRoot\$servername)) {
    Write-Verbose -Message 'Creating $servername directory.'
    New-Item -Path $PSScriptRoot\$servername -ItemType Directory | Write-Verbose
    New-Item -Path $PSScriptRoot\$servername\Settings -ItemType Directory | Write-Verbose
    New-Item -Path $PSScriptRoot\$servername\Saves -ItemType Directory | Write-Verbose
    Copy-Item -Path $PSScriptRoot\VRisingServer_Data\StreamingAssets\Settings\ServerHostSettings.json $PSScriptRoot\$servername\Settings
}


$ServerHostSettings = Get-Content $PSScriptRoot\$servername\Settings\ServerHostSettings.json | Out-String | ConvertFrom-Json
$port_game = $ServerHostSettings.Port
$port_query = $ServerHostSettings.QueryPort

$porttest = Get-NetUDPEndpoint -LocalPort $port_game -ErrorAction SilentlyContinue
if ($porttest -eq $null) {

} else {
    echo "Your Port $port_game is use, change it in $PSScriptRoot\$servername\Settings\ServerHostSettings.json"
    Read-Host -Prompt "Press Enter to exit."
    exit
}

$porttest = Get-NetUDPEndpoint -LocalPort $port_query -ErrorAction SilentlyContinue
if ($porttest -eq $null) {

} else {
    echo "Your Port $port_query is use, change it in $PSScriptRoot\$servername\Settings\ServerHostSettings.json"
    Read-Host -Prompt "Press Enter to exit."
    exit
}



if ($port_game = "9876") {
    $joinport = ""
} else {
    $joinport = $port_game
}

$url_portcheck = "https://steam-portcheck.herokuapp.com/api.php?server=" + "$public_ipv4" + "&port=" + $port_query
$test_portforwarding = Invoke-WebRequest -Uri $url_portcheck
$test_portforwarding = $test_portforwarding.Content -replace "`n","" -replace "`r",""

echo ""
Write-Host "Starting your Server $servername, others can join you at " -nonewline; Write-Host "$public_ipv4$joinport " -f yellow;
echo ""
echo "Make sure that you Forwards your Ports:"
echo "$public_ipv4 (Your Public IP) -->  $router_ipv4 (Your Router) --> ($port_game (udp) + $port_query (udp)) --> $local_ipv4 (Your PC)"
echo ""
echo "Checking Portforwarding via https://steam-portcheck.herokuapp.com ..."
if ($test_portforwarding -eq "OK") {
    Write-Host "Port-Forwarding $test_portforwarding" -f green;
 
} else {
    Write-Host "Port-Forwarding $test_portforwarding - See http://steam-portcheck.herokuapp.com/index.php?server=$public_ipv4 for more Infos" -f red;
}
echo ""
echo ""

$host.ui.RawUI.WindowTitle = "$servername on $public_ipv4" + ":" + $port_game + " - serverscript $version"


for ($crashed = 1; $crashed -le 3; $crashed++ ) {
    sleep 5 
    $crashlog= "$PSScriptRoot" + "\logs\VRisingServer_" + "$servername" + "_crash_" + "$crashed" + ".log"
    if (Get-Item -Path "$PSScriptRoot\logs\VRisingServer_$servername.log" -ErrorAction Ignore) {
        Clear-Content "$PSScriptRoot\logs\VRisingServer_$servername.log"
    }

    $vrising_server = Start-Process -FilePath "VRisingServer.exe" -WorkingDirectory $PSScriptRoot -ArgumentList "-persistentDataPath .\$servername", "-logFile .\logs\VRisingServer_$servername.log" -PassThru  -WindowStyle Minimized
    $vrising_pid = $vrising_server.id
    echo "Started Server with PID $vrising_pid"
 
    
    do {
        $vrising_status = Get-Process -id $vrising_pid -ErrorAction SilentlyContinue
        Get-Content "$PSScriptRoot\logs\VRisingServer_$servername.log" -Tail 50
        Start-Sleep -Seconds 5
    } until ($vrising_status -eq $null)

    echo "---------------------------------------"
    sleep 5
    if ($discord_notifaction = 1) {
        $Body = @{
        "username" = "V Rising Server Script"
        "content" = "Server $servername crashed ($crashed times) ... restarting"
        }
        Invoke-RestMethod -Uri $discord_webhook -Method 'post' -Body $Body
    }
    Copy-Item "$PSScriptRoot\logs\VRisingServer_$servername.log" -Destination "$crashlog"
    echo "$date - Process crashed ($crashed times), Crashlog is saved at $crashlog"

} 


$info = "crashed three times, stopping script"

if ($discord_notifaction = 1) {
    $Body = @{
    "username" = "V Rising Server Script"
    "content" = "Server $servername $info"
    }
    Invoke-RestMethod -Uri $discord_webhook -Method 'post' -Body $Body
}

echo $info
Read-Host -Prompt "Press Enter to exit."
exit

