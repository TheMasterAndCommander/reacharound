clear
Write-Host "Gathering inventory information..."
# Date
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
# IP
$IP = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null }).IPAddress | Select-Object -First 1
# MAC address
$MAC = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.DefaultIPGateway -ne $null } | Select-Object -ExpandProperty MACAddress
# Serial Number
$SN = Get-WmiObject -Class Win32_Bios | Select-Object -ExpandProperty SerialNumber
# Model
$Model = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
# CPU
$CPU = Get-WmiObject -Class win32_processor | Select-Object -ExpandProperty Name
# RAM
$RAM = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object { [math]::Round(($_.sum / 1GB),2) }
# Storage
$Storage = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$env:systemdrive'" | ForEach-Object { [math]::Round($_.Size / 1GB,2) }
#GPU(s)
function GetGPUInfo {
  $GPUs = Get-WmiObject -Class Win32_VideoController
  foreach ($GPU in $GPUs) {
    $GPU | Select-Object -ExpandProperty Description
  }
}

## If some computers have more than two GPUs, you can copy the lines below, but change the variable and index number by counting them up by 1.
$GPU0 = GetGPUInfo | Select-Object -Index 0
$GPU1 = GetGPUInfo | Select-Object -Index 1
# OS
$OS = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
# OS Build
$OSBuild = (Get-Item "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue('ReleaseID')
# Username
$Username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# Monitor(s)
function GetMonitorInfo {
  # Thanks to https://github.com/MaxAnderson95/Get-Monitor-Information
  $Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID"
  foreach ($Monitor in $Monitors) {
    ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
    ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
    ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
  }
}
## If some computers have more than three monitors, you can copy the lines below, but change the variable and index number by counting them up by 1.
$Monitor1 = GetMonitorInfo | Select-Object -Index 0,1
$Monitor1SN = GetMonitorInfo | Select-Object -Index 2
$Monitor2 = GetMonitorInfo | Select-Object -Index 3,4
$Monitor2SN = GetMonitorInfo | Select-Object -Index 5
$Monitor3 = GetMonitorInfo | Select-Object -Index 6,7
$Monitor3SN = GetMonitorInfo | Select-Object -Index 8
$Monitor1 = $Monitor1 -join ' '
$Monitor2 = $Monitor2 -join ' '
$Monitor3 = $Monitor3 -join ' '
# Type of computer
# Values are from https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
$Chassis = Get-CimInstance -ClassName Win32_SystemEnclosure -Namespace 'root\CIMV2' -Property ChassisTypes | Select-Object -ExpandProperty ChassisTypes
$ChassisDescription = switch ($Chassis) {
  "1" { "Other" }
  "2" { "Unknown" }
  "3" { "Desktop" }
  "4" { "Low Profile Desktop" }
  "5" { "Pizza Box" }
  "6" { "Mini Tower" }
  "7" { "Tower" }
  "8" { "Portable" }
  "9" { "Laptop" }
  "10" { "Notebook" }
  "11" { "Hand Held" }
  "12" { "Docking Station" }
  "13" { "All in One" }
  "14" { "Sub Notebook" }
  "15" { "Space-Saving" }
  "16" { "Lunch Box" }
  "17" { "Main System Chassis" }
  "18" { "Expansion Chassis" }
  "19" { "SubChassis" }
  "20" { "Bus Expansion Chassis" }
  "21" { "Peripheral Chassis" }
  "22" { "Storage Chassis" }
  "23" { "Rack Mount Chassis" }
  "24" { "Sealed-Case PC" }
  "30" { "Tablet" }
  "31" { "Convertible" }
  "32" { "Detachable" }
  default { "Unknown" }
}



  $infoObject = New-Object PSObject
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Date Collected" -Value $Date
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "IP Address" -Value $IP
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Hostname" -Value $env:computername
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "MAC Address" -Value $MAC
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "User" -Value $Username
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Type" -Value $ChassisDescription
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Serial Number/Service Tag" -Value $SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Model" -Value $Model
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "CPU" -Value $CPU
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "RAM (GB)" -Value $RAM
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Storage (GB)" -Value $Storage
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "GPU 0" -Value $GPU0
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "GPU 1" -Value $GPU1
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS" -Value $OS
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "OS Version" -Value $OSBuild
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 1" -Value $Monitor1
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 1 Serial Number" -Value $Monitor1SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 2" -Value $Monitor2
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 2 Serial Number" -Value $Monitor2SN
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 3" -Value $Monitor3
  Add-Member -InputObject $infoObject -MemberType NoteProperty -Name "Monitor 3 Serial Number" -Value $Monitor3SN
  $infoObject
  $infoColl += $infoObject

    $infoColl
