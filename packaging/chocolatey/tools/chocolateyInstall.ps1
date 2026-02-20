$packageName = 'learmond'
$toolsDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition

# URL to the release ZIP for Windows. Replace with your GitHub Release URL.
$url = 'https://github.com/thelearmondcorporation/learmond/releases/download/vX.Y.Z/learmond-windows-x64.zip'
# SHA256 checksum for the ZIP file (replace with the real hash)
$checksum = '344228171cde88393a79d47b9b492e8ade7f4206a8178f6ef7ef950a858ae543'

Write-Host "Installing $packageName from $url"

Install-ChocolateyZipPackage $packageName $url $toolsDir -Checksum $checksum -ChecksumType 'sha256'

# If the zip contains the exe at tools\learmond.exe, Chocolatey will create a shim automatically.
# Optionally you can add/remove files or create shortcuts here.