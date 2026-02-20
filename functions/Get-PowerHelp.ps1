Function Get-PowerHelp {
<#
	.SYNOPSIS
	Provides a quick summary of a command's help information.

	.DESCRIPTION
	The `Get-QuickHelp` function retrieves and formats help information for one or more commands.
	It allows users to select specific details such as the synopsis, examples, or detailed information about the command.

	.PARAMETER Name
	Specifies the name(s) of the command(s) for which help information is retrieved.
	This parameter is mandatory and accepts one or more command names.

	.PARAMETER Format
	Specifies the formatting you want back to the console.
	The valid options are:
	- `SynopsisOnly`: Retrieves only the synopsis of the command.
	- `AllExamples`: Retrieves all examples along with other details like required parameters and pipeline input.
	- `Detailed`: Retrieves detailed information, including input/output objects, description, and examples.
	- `Oneliners`: Retrieves a short synopsis plus one-line runnable example commands.

	.EXAMPLE
	Get-QuickHelp -command gal -Format SynopsisOnly

	Name      Synopsis
	----      --------
	Get-Alias Gets the aliases for the current session.


	.EXAMPLE
	qhelp -command gal -Format SynopsisOnly

	Name      Synopsis
	----      --------
	Get-Alias Gets the aliases for the current session.
	.EXAMPLE
	>gcm -module Microsoft.powershell.management | qhelp

	Name                  Alias                         ModuleName                      Synopsis                                                                                           RequiredParams                                                                   WildcardsAllowe
																																		d
	----                  -----                         ----------                      --------                                                                                           --------------                                                                   ---------------
	Add-Content           ac                            Microsoft.PowerShell.Management Adds content to the specified items, such as adding words to a file.                               LiteralPath, Path, Value                                                         Exclude, Filte…
	Clear-Content         clc                           Microsoft.PowerShell.Management Deletes the contents of an item, but does not delete the item.                                     LiteralPath, Path                                                                Exclude, Filte…
	Clear-Item            cli                           Microsoft.PowerShell.Management Clears the contents of an item, but does not delete the item.                                      LiteralPath, Path                                                                Exclude, Filte…
	Clear-ItemProperty    clp                           Microsoft.PowerShell.Management Clears the value of a property but does not delete the property.                                   LiteralPath, Name, Path                                                          Exclude, Filte…

	#>
	[CmdletBinding()]
	[Alias('phelp')]
	[Alias('ph')]
	param(
		[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[Alias('Command')]
		[string[]]$Name = "Get-BetterHelp",

		[ValidateSet('SynopsisOnly','AllExamples','Detailed','Oneliners')]
		[string]$Format
	)
	begin {
		$data = [System.Collections.Generic.List[psobject]]::new()
	}
	process {
		foreach ($commandName in $Name) {
			try {
				$helpItems = @(Get-Help -Name $commandName -Full -ErrorAction Stop)
			} catch {
				Write-Error "Unable to retrieve help for '$commandName'. $($_.Exception.Message)"
				continue
			}

			foreach ($h in $helpItems) {
				$data.Add([PSCustomObject]@{
						PSTypeName = 'PowerHelp'
						Name = $h.Name
						Alias = (Get-Alias -Definition $h.Name -ErrorAction SilentlyContinue).Name -join ', '
						ModuleName = "$($h.ModuleName)"
						Synopsis = $h.Synopsis
						Description = $h.Description
						Details = $h.Details
						InputObjects = ($h.inputTypes | Out-String).Trim()
						OutputObjects = ($h.returnValues | Out-String).Trim()
						RequiredParams = ($h.Parameters.parameter | Where-Object Required -eq 'True').Name -join ', '
						WildcardsAllowed = ($h.Parameters.parameter | Where-Object globbing -eq 'True').Name -join ', '
						PipelineInputAllowed = (($h.Parameters.parameter | Where-Object pipelineInput -match 'True' | Select-Object @{l = 'Pipeline'; Expr = { "$($_.Name) - $($_.pipelineInput -replace 'True \(([A-Za-z]+)\)', '$1')" } }).Pipeline | Out-String) -join ', '
						Related = $h.RelatedLinks
						Examples = (($h.Examples.Example | Select-Object @{l = 'Examples'; Expr = { "$($_.Title) `n $($_.code )" } }).Examples | Out-String) -join ', '
						Oneliners = [PowerHelpEntry]::GetOnelinersFromExamples($h.Examples.Example)
					})
			}#foreach help item
		}
	}
	end {
		$sorted = $data | Sort-Object PipelineInputAllowed -Descending
		switch ($Format) {
			'SynopsisOnly' {
				$sorted | Format-Table -View SynopsisOnly
			}

			'AllExamples' {
				$sorted | Format-List -View AllExamples
			}

			'Detailed' {
				$sorted | Format-List -View Detailed
			}

			'Oneliners' {
				$sorted | Format-List -View Oneliners
			}

			default {
				$sorted
			}
		}
	}

}#function
