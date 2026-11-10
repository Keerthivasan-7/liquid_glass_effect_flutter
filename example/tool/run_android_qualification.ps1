#requires -Version 7.2
param(
 [string]$Flutter='flutter',
 [string]$Adb='adb',
 [Parameter(Mandatory)][string]$Device,
 [Parameter(Mandatory)][string]$Binary,
 [Parameter(Mandatory)][string]$OutputDirectory,
 [string]$Route='/?mode=contracts',
 [ValidateSet('default','enabled','disabled')][string]$Impeller='default'
)
$ErrorActionPreference='Stop'
$exampleRoot=Split-Path -Parent $PSScriptRoot
$packageRoot=Split-Path -Parent $exampleRoot
. (Join-Path $packageRoot 'benchmark/tool/android_session.ps1')
$outputRoot=[IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force $outputRoot | Out-Null
$binaryPath=(Resolve-Path -LiteralPath $Binary).Path
Install-LiquidTestApk $Adb $Device 'dev.liquidglass.liquid_glass_showcase' $binaryPath $outputRoot
$previousOutput=$env:LIQUID_GLASS_RESULTS
$session=$null
Push-Location -LiteralPath $exampleRoot
try {
 $env:LIQUID_GLASS_RESULTS=$outputRoot
 $session=Start-LiquidAndroidSession $Adb $Device 'dev.liquidglass.liquid_glass_showcase' $Route $outputRoot $Impeller
 & $Flutter drive --no-pub --driver=test_driver/integration_test.dart --target=integration_test/renderer_qualification_test.dart -d $Device --profile "--use-existing-app=$($session.uri)" 2>&1 | Tee-Object -FilePath (Join-Path $outputRoot 'runtime.log')
 $code=$LASTEXITCODE
 @{driverExitCode=$code;route=$Route;impellerOverride=$Impeller;binarySha256=(Get-FileHash -LiteralPath $binaryPath).Hash;endedAtUtc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content (Join-Path $outputRoot 'result.json')
 if($code -ne 0) { throw 'Qualification did not pass; preserved exported data and logs.' }
} finally {
 Stop-LiquidAndroidSession $Adb $session
 $env:LIQUID_GLASS_RESULTS=$previousOutput
 Pop-Location
}
