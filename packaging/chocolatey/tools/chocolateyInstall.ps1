$packageName = 'learmond'
$toolsDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition

# URL to the release ZIP for Windows. Replace with your GitHub Release URL.
$url = 'https://github.com/thelearmondcorporation/learmond/releases/download/vX.Y.Z/learmond-windows-x64.zip'
# SHA256 checksum for the ZIP file (replace with the real hash)
$checksum = 'f7738a01096b51d6d05d01dbe29638d9d6d53f8579c9aa0a3da3e87c43bd6b9f'

Write-Host "Installing $packageName from $url"

Install-ChocolateyZipPackage $packageName $url $toolsDir -Checksum $checksum -ChecksumType 'sha256'

# If the zip contains the exe at tools\learmond.exe, Chocolatey will create a shim automatically.
# Optionally you can add/remove files or create shortcuts here.