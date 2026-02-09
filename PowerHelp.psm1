
# PowerHelp Module
# Author: Mason Moser
# Version: 1.0.0

#Region Module Variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = '2.0.0'
$script:ConfigPath = Join-Path -Path $ModuleRoot -ChildPath 'Config'
#EndRegion Module Variables

# Ensure required folders exist
$requiredFolders = @('functions', 'internal', 'Classes', 'Config')
foreach ($folder in $requiredFolders) {
	$folderPath = Join-Path -Path $ModuleRoot -ChildPath $folder
	if (-not (Test-Path -Path $folderPath)) {
		New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
	}
}

# One-time migration of files from Cmdlets to functions if needed
$cmdletsPath = Join-Path -Path $ModuleRoot -ChildPath 'Cmdlets'
if (Test-Path -Path $cmdletsPath) {
	$cmdletFiles = Get-ChildItem -Path "$cmdletsPath\*.ps1" -recurse -File
	if ($cmdletFiles) {
		Write-Verbose 'Moving cmdlet files to functions folder'
		foreach ($file in $cmdletFiles) {
			$destinationPath = Join-Path -Path "$ModuleRoot\functions" -ChildPath $file.Name
			if (-not (Test-Path -Path $destinationPath)) {
				Move-Item -Path $file.FullName -Destination $destinationPath -Force
			}
		}
	}
}

#Region Import Functions
$functionFolders = @('Classes', 'internal', 'functions')
foreach ($folder in $functionFolders) {
	$folderPath = Join-Path -Path $ModuleRoot -ChildPath $folder
	if (Test-Path -Path $folderPath) {
		$files = Get-ChildItem -Path $folderPath -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue
		foreach ($file in $files) {
			try {
				Write-Verbose "Importing file: $($file.FullName)"
				. $file.FullName
			} catch {
				Write-Error "Failed to import file $($file.FullName): $_"
			}
		}
	}
}
#EndRegion Import Functions

# Export functions
$functions = @(Get-ChildItem -Path "$ModuleRoot\functions\" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue).BaseName
Export-ModuleMember -Function $Functions -Alias *

#Import Custom Objects
./internal/objects/BetterHelpObject.ps1
