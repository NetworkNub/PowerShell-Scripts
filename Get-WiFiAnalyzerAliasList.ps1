#Use Cisco Prime Infrastructure to generate a list of aliases for farproc's WiFi Analyzer http://wifianalyzer.mobi

$PIAddress = Read-Host 'Prime Infrastructure hostname or IP'
$username  = Read-Host 'Username'
$password  = Read-Host -asSecureString 'Password'
$filename  = Read-Host 'Filename [WifiAnalyzer_Alias.txt]'

$password = (New-Object System.Management.AUtomation.PSCredential('N/A',$password)).GetNetworkCredential().password
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(('{0}:{1}' -f $username,$password)))
$Headers = @{Authorization = 'Basic {0}' -f $encodedCreds}

if ($filename -eq '') {$filename = 'WifiAnalyzer_Alias.txt'}

$firstResult = $i = 0
$aliasList = @()

Do
{
  $uri = 'https://{0}/webacs/api/v1/data/AccessPoints?.firstResult={1}' -f $PIAddress ,$firstResult
  $APList = (Invoke-RestMethod -Headers $Headers -Uri $uri).queryResponse
  foreach ($url in $APList.entityId.url)
  { 
    $i ++
    Write-Progress -Activity ('Processing AP list: {0}' -f $uri) -status ('AP {0} of {1}' -f $i,$APList.count) -PercentComplete ($i / $APList.count * 100)
    $AP = (Invoke-RestMethod -Headers $Headers -Uri $url).queryResponse.entity.accessPointsDTO
    (0..9)+'a','b','c','d','e','f' | Foreach { $aliasList += $AP.macAddress -replace '.$', ('{0}|{1}' -f $_,$AP.name) }
  }
  $firstResult = [int]$APList.last + 1
} While ([int]$APList.last -lt [int]$APList.count - 1)

$aliasList | Out-File -Encoding 'utf8' $filename