# Check if the current PowerShell session is running as Administrator
$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if (-not $isAdmin) {
    # Relaunch PowerShell as Administrator
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -NoExit -File `"$($MyInvocation.MyCommand.Definition)`""
    # Exit the current non-elevated session
    exit
}

# Check for Developer Mode (required for symlinks if not admin)
$devMode = $false
try {
    $devMode = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense -eq 1
} catch {}
if (-not $devMode) {
    Write-Error "Developer Mode is not enabled. Please enable Developer Mode in Windows settings before running this script."
    exit 1
}

# First thing is to download and install a NerdFont. I use Agave
$ErrorActionPreference = 'Stop'
$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Agave.zip"
try {
    Write-Output "Downloading Agave nerd fonts"
    Invoke-WebRequest -Uri $fontUrl -OutFile Agave.zip
    Write-Output "Extracting"
    mkdir agave-font
    Expand-Archive -LiteralPath Agave.zip -DestinationPath agave-font
} catch {
    Write-Error "Font download or extraction failed: $_"
    exit 1
}

Write-Output "Installing Fonts"
$sourceDir = "agave-font"
$systemFontsPath = "C:\Windows\Fonts"
$fonts = Get-ChildItem -Path $sourceDir -Include '*.ttf','*.otf' -Recurse
foreach ($font in $fonts) {
    $targetPath = Join-Path $systemFontsPath $font.Name
    try {
        if (!(Test-Path $targetPath)) {
            Copy-Item $font.FullName -Destination $targetPath -Force
            if ($font.Extension -eq '.otf') {
                $regName = "$($font.BaseName) (OpenType)"
            } else {
                $regName = "$($font.BaseName) (TrueType)"
            }
            New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name $regName -Value $font.Name -PropertyType String -Force
            Write-Output "$($font.Name) installed."
        } else {
            Write-Output "$($font.Name) already installed, skipping."
        }
    } catch {
        Write-Error "Failed to install $($font.Name): $_"
    }
}

# Clean up font files
try {
    Remove-Item Agave.zip -Force
    Remove-Item agave-font -Recurse -Force
} catch {
    Write-Warning "Failed to clean up temporary font files."
}

# Actually handling the window terminal's settings.
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$repoSettings = "$PSScriptRoot\settings.json"

Write-Output "Backing up existing Windows Terminal settings.json if present."
if (Test-Path $wtSettings) {
    try {
        Copy-Item $wtSettings "$wtSettings.bak" -Force
        Remove-Item $wtSettings -Force
    } catch {
        Write-Warning "Failed to backup or remove existing settings.json: $_"
    }
}

try {
    New-Item -ItemType SymbolicLink -Path $wtSettings -Target $repoSettings -Force
    Write-Output "Symlink created: $wtSettings -> $repoSettings"
} catch {
    Write-Error "Failed to create symbolic link: $_"
}

Read-Host -Prompt "Press Enter to exit"
exit 0