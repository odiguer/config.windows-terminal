# First thing is to download and install a NerdFont. I use Agave

$fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Agave.zip"

Write-Output "Downloading Agave nerd fonts"
Invoke-WebRequest -Uri $fontUrl -OutFile Agave.zip

Write-Output "Extracting"
mkdir agave-font
Expand-Archive -LiteralPath Agave.zip -DestinationPath agave-font

Write-Output "Installing Fonts"
$sourceDir = "agave-font"
$systemFontsPath = "C:\Windows\Fonts"

# Get all font files from source directory
$fonts = Get-ChildItem -Path $sourceDir -Include '*.ttf','*.otf' -Recurse
foreach ($font in $fonts) {
    $targetPath = Join-Path $systemFontsPath $font.Name
    
    if (!(Test-Path $targetPath)) {
        # Copy font to Windows Fonts directory
        Copy-Item $font.FullName -Destination $targetPath -Force
        
        # Add registry entry based on font type
        if ($font.Extension -eq '.otf') {
            $regName = "$($font.BaseName) (OpenType)"
        } else {
            $regName = "$($font.BaseName) (TrueType)"
        }
        
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" `
            -Name $regName -Value $font.Name -PropertyType String -Force
			
		Write-Output "$($font.Name) installed."
    }else{
		Write-Output "$($font.Name)  already installed, skipping."
	}
}

# Actually handling the window terminal's settings.
Write-Output "Deleting windows' terminal's settings.json and replacing it with a symlink to the settings.json from our git repo."

Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
New-Item -ItemType SymbolicLink -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Target "C:\Users\odiguer\Documents\config.windows-terminal\settings.json"



