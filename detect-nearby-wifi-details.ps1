# Set this to $true to enable debug output, $false to disable
$debug = $false

# Your API key from https://my.maclookup.app/admin/api/keys
$apiKey = ""

# Clear the screen
Clear-Host

# Get Wi-Fi networks information
$wifiNetworks = netsh wlan show networks mode=bssid

# Initialize an array to store network details
$networkDetails = @()

# Initialize variables to store network details
$ssid = ""
$bssid = ""
$signal = ""
$radioType = ""
$channel = ""
$basicRates = ""
$otherRates = ""

# Parse the output and extract network details
foreach ($line in $wifiNetworks) {
    if ($debug) { Write-Host "Processing line: $line" }

    if ($line -match "BSSID\s+\d+\s+:\s+(.*)") {
        $bssid = $matches[1]
        if ($debug) { Write-Host "Matched BSSID: $bssid" }
    }
    elseif ($line -match "SSID\s+\d+\s+:\s+(.*)") {
        $ssid = $matches[1]
        if ($debug) { Write-Host "Matched SSID: $ssid" }
    }
    elseif ($line -match "Signal\s+:\s+(.*)") {
        $signal = $matches[1]
        if ($debug) { Write-Host "Matched Signal: $signal" }
    }
    elseif ($line -match "Radio type\s+:\s+(.*)") {
        $radioType = $matches[1]
        if ($debug) { Write-Host "Matched Radio Type: $radioType" }
    }
    elseif ($line -match "Channel\s+:\s+(.*)") {
        $channel = $matches[1]
        if ($debug) { Write-Host "Matched Channel: $channel" }
    }
    elseif ($line -match "Basic rates\s+.*\s+:\s+(.*)") {
        $basicRates = $matches[1]
        if ($debug) { Write-Host "Matched Basic Rates: $basicRates" }
    }
    elseif ($line -match "Other rates\s+.*\s+:\s+(.*)") {
        $otherRates = $matches[1]
        if ($debug) { Write-Host "Matched Other Rates: $otherRates" }
        # Add the network details to the array
        $networkDetails += [PSCustomObject]@{
            SSID = $ssid
            BSSID = $bssid
            Signal = $signal
            RadioType = $radioType
            Channel = $channel
            BasicRates = $basicRates
            OtherRates = $otherRates
        }
    }
}

# Function to lookup MAC address vendor
function Get-MacVendor {
    param (
        [string]$macAddress,
        [string]$apiKey
    )
    $url = "https://api.maclookup.app/v2/macs/{0}?apiKey={1}" -f $macAddress, $apiKey
    if ($debug) { Write-Host "URL: $url" }
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers @{ "Accept" = "application/json" }
    $responseData = $response.Content | ConvertFrom-Json
    if ($responseData.success -and $responseData.found -and -not $responseData.isPrivate) {
        return $responseData.company
    }
    return ""
}

# Add vendor information to network details with delay to respect API call limits
try {
    foreach ($network in $networkDetails) {
        $vendor = Get-MacVendor -macAddress $network.BSSID -apiKey $apiKey
        $network | Add-Member -MemberType NoteProperty -Name Vendor -Value $vendor

        if($response.Headers) {
            # Check rate limit headers
            $rateLimitRemaining = [int]$response.Headers["X-RateLimit-Remaining"]
            $rateLimitReset = [int]$response.Headers["X-RateLimit-Reset"]
            $currentTime = [int][DateTimeOffset]::Now.ToUnixTimeSeconds()

            if ($rateLimitRemaining -le 1) {
                $waitTime = $rateLimitReset - $currentTime
                if ($waitTime -gt 60) {
                    $resumeTime = [DateTimeOffset]::FromUnixTimeSeconds($rateLimitReset).ToLocalTime()
                    Write-Host "Rate limit exceeded. Sleeping until $resumeTime ($waitTime seconds) to respect rate limits."
                }
                if ($waitTime -gt 0) {
                    Start-Sleep -Seconds $waitTime
                }
            } else {
                Start-Sleep -Milliseconds 20  # Add delay to respect API call limits
            }
        }
    }
} catch {
    Write-Host "An error occurred: $_"
    break
}

# Display the network details with vendor information
$networkDetails | Format-Table -AutoSize
