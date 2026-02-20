$packageName = 'learmond'
$toolsDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition

# URL to the release ZIP for Windows. Replace with your GitHub Release URL.
$url = 'https://github.com/thelearmondcorporation/learmond/releases/download/vX.Y.Z/learmond-windows-x64.zip'
# SHA256 checksum for the ZIP file (replace with the real hash)
$checksum = 'a96a57752e56695c7bbd47e74b739ff6db4da96b05fc5aa1975c1f1239769e21'

Write-Host "Installing $packageName from $url"

Install-ChocolateyZipPackage $packageName $url $toolsDir -Checksum $checksum -ChecksumType 'sha256'

# If the zip contains the exe at tools\learmond.exe, Chocolatey will create a shim automatically.
# Optionally you can add/remove files or create shortcuts here.