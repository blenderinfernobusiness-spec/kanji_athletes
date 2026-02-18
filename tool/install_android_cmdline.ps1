$sdk = "$env:LOCALAPPDATA\Android\Sdk"
New-Item -ItemType Directory -Force -Path $sdk | Out-Null
$zip = "$env:TEMP\cmdline-tools.zip"
Invoke-WebRequest 'https://dl.google.com/android/repository/commandlinetools-win-latest.zip' -OutFile $zip -UseBasicParsing
$tmp = "$env:TEMP\cmdline_tools_tmp"
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Expand-Archive -Path $zip -DestinationPath $tmp -Force
if (Test-Path (Join-Path $tmp 'cmdline-tools')) {
    Move-Item -Force -Path (Join-Path $tmp 'cmdline-tools') -Destination (Join-Path $sdk 'cmdline-tools\latest')
} else {
    Move-Item -Force -Path (Join-Path $tmp 'tools') -Destination (Join-Path $sdk 'cmdline-tools\latest')
}
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
Remove-Item -Force $zip -ErrorAction SilentlyContinue
Write-Output 'cmdline-tools installed'
