# Shared by source-checkout qualification and benchmark runners.
# Keeps VM-service authentication enabled and never uninstalls an app.

function Invoke-LiquidAndroidShell([string]$AdbPath,[string]$Serial,[string[]]$RemoteArguments) {
 $quoted=@($RemoteArguments | ForEach-Object { "'"+$_.Replace("'","'\''")+"'" }) -join ' '
 $output=(& $AdbPath -s $Serial shell $quoted 2>&1) -join "`n"
 $code=$LASTEXITCODE
 return @{exitCode=$code;output=$output}
}

function Get-LiquidInstalledApkHash([string]$AdbPath,[string]$Serial,[string]$Package) {
 $path=Invoke-LiquidAndroidShell $AdbPath $Serial @('pm','path',$Package)
 $line=@($path.output -split "`n" | Where-Object { $_ -match '^package:.*/base\.apk\s*$' })
 if(-not $line.Count) { return $null }
 $remotePath=$line[0].Substring(8).Trim()
 $hash=Invoke-LiquidAndroidShell $AdbPath $Serial @('sha256sum',$remotePath)
 if($hash.exitCode -eq 0 -and $hash.output -match '^([a-fA-F0-9]{64})\s') { return $Matches[1].ToUpperInvariant() }
 return $null
}

function Install-LiquidTestApk([string]$AdbPath,[string]$Serial,[string]$Package,[string]$Binary,[string]$EvidenceDirectory) {
 if($Package -notin @('dev.liquidglass.liquid_glass_showcase','dev.liquidglass.liquid_glass_benchmark')) { throw 'Only the project test app packages are allowed.' }
 $expected=(Get-FileHash -LiteralPath $Binary -Algorithm SHA256).Hash
 $installed=Get-LiquidInstalledApkHash $AdbPath $Serial $Package
 if($installed -eq $expected) { Write-Output 'ANDROID_APK_REUSED'; return }
 $output=(& $AdbPath -s $Serial install -t -r $Binary 2>&1) -join "`n"
 $code=$LASTEXITCODE
 $output | Set-Content (Join-Path $EvidenceDirectory 'install.log')
 if($code -ne 0 -or $output -match 'Failure|INSTALL_FAILED') { throw "Android refused the test APK installation: $output" }
 $installed=Get-LiquidInstalledApkHash $AdbPath $Serial $Package
 if($installed -ne $expected) { throw 'Installed APK hash could not be verified; no measurements started.' }
 Write-Output 'ANDROID_APK_INSTALLED_AND_VERIFIED'
}

function Start-LiquidAndroidSession([string]$AdbPath,[string]$Serial,[string]$Package,[string]$Route,[string]$EvidenceDirectory,[string]$Impeller='default') {
 if($Package -notin @('dev.liquidglass.liquid_glass_showcase','dev.liquidglass.liquid_glass_benchmark')) { throw 'Unexpected application package.' }
 $stop=Invoke-LiquidAndroidShell $AdbPath $Serial @('am','force-stop',$Package)
 if($stop.exitCode -ne 0) { throw "Cannot stop the previous test process: $($stop.output)" }
 $arguments=@('am','start','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-f','0x20000000','--ez','enable-dart-profiling','true','--ez','start-paused','true','--es','route',$Route)
 if($Impeller -eq 'enabled') { $arguments+=@('--ez','enable-impeller','true') }
 elseif($Impeller -eq 'disabled') { $arguments+=@('--ez','enable-impeller','false') }
 $arguments+="$Package/.MainActivity"
 $launch=Invoke-LiquidAndroidShell $AdbPath $Serial $arguments
 $launch.output | Set-Content (Join-Path $EvidenceDirectory 'launch.log')
 if($launch.exitCode -ne 0 -or $launch.output -match 'Error:|Error type|SecurityException') { throw 'Android could not launch the installed test app.' }
 $watch=[Diagnostics.Stopwatch]::StartNew()
 $appProcess=$null
 $service=$null
 $messages=''
 while($watch.Elapsed.TotalSeconds -lt 60) {
  $process=Invoke-LiquidAndroidShell $AdbPath $Serial @('pidof','-s',$Package)
  if($process.output.Trim() -match '^\d+$') {
   $appProcess=$process.output.Trim()
   # Only this app's messages, never a global phone-log dump.
   $messages=(& $AdbPath -s $Serial logcat -d "--pid=$appProcess" -v brief 2>&1) -join "`n"
   if($messages -match '(?:The Dart VM service|Dart VM service|VM Service).*?(http://127\.0\.0\.1:\d+/[^\s]+)') {
    $service=[uri]$Matches[1]
    break
   }
  }
  Start-Sleep -Milliseconds 250
 }
 if($null -eq $service) {
  $stop=Invoke-LiquidAndroidShell $AdbPath $Serial @('am','force-stop',$Package)
  throw 'The installed app did not publish its authenticated VM service within 60 seconds.'
 }
 $backend=@($messages -split "`n" | Where-Object { $_ -match 'Using the Impeller rendering backend|Using the Skia rendering backend' })
 $backend | Set-Content (Join-Path $EvidenceDirectory 'engine-backend.log')
 $port=((& $AdbPath -s $Serial forward tcp:0 "tcp:$($service.Port)" 2>&1) -join '').Trim()
 if($LASTEXITCODE -ne 0 -or $port -notmatch '^\d+$') {
  $stop=Invoke-LiquidAndroidShell $AdbPath $Serial @('am','force-stop',$Package)
  throw 'Could not forward the test VM service.'
 }
 @{appProcess=$appProcess;deviceServicePort=$service.Port;hostForwardPort=[int]$port;route=$Route;impellerOverride=$Impeller;authentication='Enabled; token intentionally omitted';backend=$backend} | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $EvidenceDirectory 'session.json')
 return @{uri="http://127.0.0.1:$port$($service.AbsolutePath)";forwardPort=$port;package=$Package;serial=$Serial}
}

function Stop-LiquidAndroidSession([string]$AdbPath,$Session) {
 if($null -eq $Session) { return }
 $stop=Invoke-LiquidAndroidShell $AdbPath $Session.serial @('am','force-stop',$Session.package)
 & $AdbPath -s $Session.serial forward --remove "tcp:$($Session.forwardPort)" 2>&1 | Out-Null
}
