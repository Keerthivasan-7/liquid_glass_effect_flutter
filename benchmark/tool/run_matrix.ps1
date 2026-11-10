#requires -Version 7.2
param(
 [string]$Flutter='flutter',
 [string]$Adb='adb',
 [string]$Python='python',
 [Parameter(Mandatory)][string]$Device,
 [Parameter(Mandatory)][string]$DeviceLabel,
 [Parameter(Mandatory)][string]$GpuLabel,
 [Parameter(Mandatory)][string]$RendererLabel,
 [Parameter(Mandatory)][string]$PowerMode,
 [Parameter(Mandatory)][string]$OutputDirectory,
 [string]$TargetPlatform='android-x64',
 [ValidateRange(0,1048576)][int]$MinimumHostFreeMemoryMiB=2048,
 [string]$PreparedResultsDirectory,
 [ValidateSet('default','enabled','disabled')][string]$Impeller='default',
 [switch]$IncludeFilter,
 [switch]$BuildOnly,
 [string[]]$OnlyScenario
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'android_session.ps1')
$benchmarkRoot=Split-Path -Parent $PSScriptRoot
$packageRoot=Split-Path -Parent $benchmarkRoot
$outputRoot=[IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force $outputRoot | Out-Null
$source=[ordered]@{}
Push-Location -LiteralPath $packageRoot
try {
 $files=& rg --files lib shaders benchmark/lib benchmark/integration_test benchmark/test_driver benchmark/android/app/src benchmark/android/gradle
 foreach($file in ($files | Sort-Object)) {
  if($file -match '\.(dart|frag|kt|java|xml|kts|properties)$') {
   $source[$file.Replace('\','/')]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
  }
 }
 foreach($file in @('pubspec.yaml','benchmark/pubspec.yaml','pubspec.lock','benchmark/pubspec.lock','benchmark/android/app/build.gradle.kts','benchmark/android/build.gradle.kts','benchmark/android/gradle.properties','benchmark/android/settings.gradle.kts')) {
  if(Test-Path -LiteralPath $file) {
   $source[$file]=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
  }
 }
} finally { Pop-Location }
$sourceJson=$source | ConvertTo-Json -Compress
$hasher=[Security.Cryptography.SHA256]::Create()
try { $sourceHash=[Convert]::ToHexString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($sourceJson))).ToLowerInvariant() }
finally { $hasher.Dispose() }
$sdkJson=(& $Flutter --version --machine) -join "`n"
$sdk=$sdkJson | ConvertFrom-Json
$configuration=[ordered]@{protocolVersion=7;runnerSha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash;sourceHash=$sourceHash;frameworkRevision=$sdk.frameworkRevision;engineRevision=$sdk.engineRevision;dartSdkVersion=$sdk.dartSdkVersion;validatorSha256=(Get-FileHash (Join-Path $PSScriptRoot 'analyze_matrix.py')).Hash;launcherSha256=(Get-FileHash (Join-Path $PSScriptRoot 'android_session.ps1')).Hash;device=$Device;deviceLabel=$DeviceLabel;gpu=$GpuLabel;renderer=$RendererLabel;powerMode=$PowerMode;targetPlatform=$TargetPlatform;includeFilter=[bool]$IncludeFilter;minimumHostFreeMemoryMiB=$MinimumHostFreeMemoryMiB;impellerOverride=$Impeller;startupSettleSeconds=10;initialSettleSeconds=60}
$indexPath=Join-Path $outputRoot 'index.json'
$index=@{schemaVersion=1;configuration=$configuration;startedAtUtc=[DateTime]::UtcNow.ToString('o');completed=$false;attempts=@()}
if(Test-Path -LiteralPath $indexPath) {
 $previous=Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json -AsHashtable
 foreach($key in $configuration.Keys) {
  if($previous.configuration[$key] -ne $configuration[$key]) { throw "Existing results have a different $key. Choose another output directory." }
 }
 $index=$previous
 $index.completed=$false
}
$source | ConvertTo-Json | Set-Content (Join-Path $outputRoot 'source-snapshot.json')
$sdkJson | Set-Content (Join-Path $outputRoot 'sdk.json')
$materials=@('ordinary','blur','refraction','capturePerformance','captureBalanced','captureUltra')
if($IncludeFilter) { $materials+='filter' }
$scenarios=@()
foreach($background in @('static','animated')) {
 foreach($count in @(1,4,10)) {
  foreach($material in $materials) { $scenarios+="$material-$count-compact-$background" }
 }
 $scenarios+="captureBalanced-4-overlapping-$background"
 $scenarios+="captureBalanced-10-spread-$background"
}
if($OnlyScenario) {
 foreach($name in $OnlyScenario) { if($name -notin $scenarios) { throw "Unknown scenario: $name" } }
 $scenarios=@($scenarios | Where-Object { $_ -in $OnlyScenario })
}
$index.scenarios=$scenarios
$index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
$binary=Join-Path $outputRoot 'benchmark-profile.apk'
$reuse=(Test-Path -LiteralPath $binary) -and $index.ContainsKey('binarySha256') -and (Get-FileHash -LiteralPath $binary).Hash -eq $index.binarySha256
if(-not $reuse -and $PreparedResultsDirectory) {
 $preparedRoot=[IO.Path]::GetFullPath($PreparedResultsDirectory)
 $prepared=Get-Content -LiteralPath (Join-Path $preparedRoot 'index.json') -Raw | ConvertFrom-Json -AsHashtable
 foreach($key in @('protocolVersion','startupSettleSeconds','initialSettleSeconds','sourceHash','frameworkRevision','engineRevision','dartSdkVersion','deviceLabel','gpu','renderer','powerMode','targetPlatform')) {
  if($prepared.configuration[$key] -ne $configuration[$key]) { throw "Prepared binary has a different $key." }
 }
 $preparedBinary=Join-Path $preparedRoot 'benchmark-profile.apk'
 if((Get-FileHash -LiteralPath $preparedBinary).Hash -ne $prepared.binarySha256) { throw 'Prepared binary hash mismatch.' }
 Copy-Item -LiteralPath $preparedBinary -Destination $binary -Force
 $index.binarySha256=$prepared.binarySha256
 $index.binaryImportedFrom=$preparedRoot
 $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
 $reuse=$true
}
function Read-HostState {
 $state=@{recordedAtUtc=[DateTime]::UtcNow.ToString('o');freeMemoryMiB=$null;totalMemoryMiB=$null;measurement='Unavailable on this host'}
 if($IsWindows) {
  $os=Get-CimInstance Win32_OperatingSystem
  $state.freeMemoryMiB=[math]::Round($os.FreePhysicalMemory/1024,2)
  $state.totalMemoryMiB=[math]::Round($os.TotalVisibleMemorySize/1024,2)
  $state.measurement='Win32_OperatingSystem.FreePhysicalMemory; before/after group, not continuous telemetry'
 }
 return $state
}
function Test-HostMemory($State) {
 return $MinimumHostFreeMemoryMiB -eq 0 -or ($null -ne $State.freeMemoryMiB -and $State.freeMemoryMiB -ge $MinimumHostFreeMemoryMiB)
}
# Build separately when needed; measuring must not silently compete with an
# idle compiler heap or a memory-constrained host. Never close user apps here.
if(-not $BuildOnly) {
 $preflight=Read-HostState
 $index.hostPreflight=$preflight
 $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
 if(-not (Test-HostMemory $preflight)) { throw "Host memory preflight failed: $($preflight.freeMemoryMiB) MiB free; $MinimumHostFreeMemoryMiB required. No measurement started." }
}
Push-Location -LiteralPath $benchmarkRoot
$previousOutput=$env:LIQUID_GLASS_RESULTS
try {
 if(-not $reuse) {
  $buildArguments=@('build','apk','--profile','--target=integration_test/benchmark_matrix_test.dart',"--target-platform=$TargetPlatform",'--dart-define=BENCHMARK_SECONDS=30','--dart-define=BENCHMARK_STARTUP_SETTLE_SECONDS=10','--dart-define=BENCHMARK_INITIAL_SETTLE_SECONDS=60','--dart-define=BENCHMARK_REQUIRE_SCENARIO=true',"--dart-define=FLUTTER_REVISION=$($sdk.frameworkRevision)","--dart-define=DEVICE_LABEL=$DeviceLabel","--dart-define=GPU_LABEL=$GpuLabel","--dart-define=RENDERER_LABEL=$RendererLabel","--dart-define=POWER_MODE=$PowerMode")
  & $Flutter @buildArguments 2>&1 | Tee-Object -FilePath (Join-Path $outputRoot 'build.log')
  if($LASTEXITCODE -ne 0) { throw 'Benchmark build failed' }
  Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-profile.apk' -Destination $binary -Force
  $index.binarySha256=(Get-FileHash -LiteralPath $binary).Hash
  $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
 }
 if($BuildOnly) { Write-Output "MATRIX_BINARY_READY $binary"; return }
 $apkVerified=$false
 foreach($scenario in $scenarios) {
  $previousAttempts=@($index.attempts | Where-Object { $_.scenario -eq $scenario })
  if($previousAttempts.Count -gt 0 -and $previousAttempts[-1].qualified) {
   $previousGroup=Join-Path $outputRoot $previousAttempts[-1].directory
   & $Python (Join-Path $PSScriptRoot 'analyze_matrix.py') $previousGroup --group
   if($LASTEXITCODE -eq 0) { Write-Output "MATRIX_REUSE $scenario"; continue }
  }
  # Refuse to combine a stale binary with modified source files.
  foreach($entry in $source.GetEnumerator()) {
   if((Get-FileHash -LiteralPath (Join-Path $packageRoot $entry.Key)).Hash -ne $entry.Value) { throw "Source changed during measurement: $($entry.Key)" }
  }
  $hostBefore=Read-HostState
  if(-not (Test-HostMemory $hostBefore)) {
   $index.hostPreflight=$hostBefore
   $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
   throw 'Host memory fell below the declared minimum before this group. No measurement started.'
  }
  $health=(& $Adb -s $Device shell service check package) -join "`n"
  if($health -notmatch 'found' -or $health -match 'not found') { throw "Android package service is unavailable: $health" }
  if(-not $apkVerified) {
   Install-LiquidTestApk $Adb $Device 'dev.liquidglass.liquid_glass_benchmark' $binary $outputRoot
   $apkVerified=$true
  }
  $attemptNumber=@($index.attempts | Where-Object scenario -eq $scenario).Count+1
  $directory=Join-Path $outputRoot "$scenario/attempt-$attemptNumber"
  while(Test-Path -LiteralPath $directory) {
   $attemptNumber+=1
   $directory=Join-Path $outputRoot "$scenario/attempt-$attemptNumber"
  }
  New-Item -ItemType Directory -Force $directory | Out-Null
  foreach($telemetry in @(@('battery','dumpsys','battery'),@('thermal','dumpsys','thermalservice'),@('low-power','settings','get','global','low_power'))) {
   $reading=Invoke-LiquidAndroidShell $Adb $Device $telemetry[1..($telemetry.Count-1)]
   $reading.output | Set-Content (Join-Path $directory "device-$($telemetry[0])-before.log")
  }
  $env:LIQUID_GLASS_RESULTS=$directory
  $session=$null
  $exitCode=1
  $driverFailure=$null
  try {
   $session=Start-LiquidAndroidSession $Adb $Device 'dev.liquidglass.liquid_glass_benchmark' "/?scenario=$scenario" $directory $Impeller
   $driveArguments=@('drive','--no-pub','--driver=test_driver/integration_test.dart','--target=integration_test/benchmark_matrix_test.dart','-d',$Device,'--profile',"--use-existing-app=$($session.uri)")
   & $Flutter @driveArguments 2>&1 | Tee-Object -FilePath (Join-Path $directory 'runtime.log')
   $exitCode=$LASTEXITCODE
  } catch {
   $driverFailure=$_.Exception.Message
   $driverFailure | Set-Content (Join-Path $directory 'driver-failure.log')
  } finally { Stop-LiquidAndroidSession $Adb $session }
  foreach($telemetry in @(@('battery','dumpsys','battery'),@('thermal','dumpsys','thermalservice'),@('low-power','settings','get','global','low_power'))) {
   $reading=Invoke-LiquidAndroidShell $Adb $Device $telemetry[1..($telemetry.Count-1)]
   $reading.output | Set-Content (Join-Path $directory "device-$($telemetry[0])-after.log")
  }
  $qualified=$false
  $manifestPath=Join-Path $directory 'matrix.json'
  if(Test-Path -LiteralPath $manifestPath) {
   $manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
   $qualified=$exitCode -eq 0 -and $manifest.completed -and $manifest.results.Count -eq 3
   foreach($resultFile in $manifest.results) {
    $result=Get-Content -LiteralPath (Join-Path $directory $resultFile) -Raw | ConvertFrom-Json
    $qualified=$qualified -and $result.qualifiedMeasurement -and $result.scenario -eq $scenario
   }
   & $Python (Join-Path $PSScriptRoot 'analyze_matrix.py') $directory --group
   $qualified=$qualified -and $LASTEXITCODE -eq 0
  }
  $healthAfter=(& $Adb -s $Device shell service check package) -join "`n"
  $healthy=$healthAfter -match 'found' -and $healthAfter -notmatch 'not found'
  $hostAfter=Read-HostState
  $hostMemoryQualified=Test-HostMemory $hostAfter
  $qualified=$qualified -and $healthy -and $hostMemoryQualified
  $index.attempts+=@{scenario=$scenario;attempt=$attemptNumber;directory=[IO.Path]::GetRelativePath($outputRoot,$directory);exitCode=$exitCode;qualified=$qualified;deviceHealthAfter=$healthAfter;hostBefore=$hostBefore;hostAfter=$hostAfter;hostMemoryQualified=$hostMemoryQualified;finishedAtUtc=[DateTime]::UtcNow.ToString('o')}
  $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
  Write-Output "MATRIX_GROUP_COMPLETE $scenario qualified=$qualified"
  if(-not $healthy) { throw 'Android system became unhealthy; preserved the group and stopped the matrix.' }
  if(-not $hostMemoryQualified) { throw 'Host memory fell below the declared minimum; preserved this invalid group and stopped the matrix.' }
  if($exitCode -ne 0) { throw 'The driver did not complete. Preserved the attempt and stopped the matrix; resume when the device is available and focused.' }
 }
 $missing=@($scenarios | Where-Object {
  $name=$_
  $history=@($index.attempts | Where-Object { $_.scenario -eq $name })
  $history.Count -eq 0 -or -not $history[-1].qualified
 })
 $index.completed=$missing.Count -eq 0
 $index.finishedAtUtc=[DateTime]::UtcNow.ToString('o')
 $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
 if(-not $index.completed) { throw "$($missing.Count) scenarios need a complete new three-run attempt." }
 & $Python (Join-Path $PSScriptRoot 'analyze_matrix.py') $outputRoot
 if($LASTEXITCODE -ne 0) {
  $index.completed=$false
  $index | ConvertTo-Json -Depth 10 | Set-Content $indexPath
  throw 'Final independent analysis rejected the selected matrix; all attempts were preserved.'
 }
} finally {
 $env:LIQUID_GLASS_RESULTS=$previousOutput
 Pop-Location
}
