# powershell-scripts
A collection of scripts written in PowerShell for various tasks.

## detect-nearby-wifi-details
Get a list of all nearby detectable wifi signals and gets vendor details where possible for the mac addresses found. Outputs a table with signal strength, channels used, SSID if found, etc. On Windows 11, this requires Location services to be enable else the windows API does not return any results.
