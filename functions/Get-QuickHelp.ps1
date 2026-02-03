Function Get-QuickHelp {
<#
	.SYNOPSIS
	Provides a quick summary of a command's help information.

	.DESCRIPTION
	The `Get-QuickHelp` function retrieves and formats help information for one or more commands.
	It allows users to select specific details such as the synopsis, examples, or detailed information about the command.

	.PARAMETER Command
	Specifies the name(s) of the command(s) for which help information is retrieved.
	This parameter is mandatory and accepts one or more command names.

	.PARAMETER Format
	Specifies the formatting you want back to the console.
	The valid options are:
	- `SynopsisOnly`: Retrieves only the synopsis of the command.
	- `AllExamples`: Retrieves all examples along with other details like required parameters and pipeline input.
	- `Detailed`: Retrieves detailed information, including input/output objects, description, and examples.

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
	[Alias('qhelp')]
	param(
		[Parameter(Mandatory=$True, ValueFromPipelineByPropertyName)]
		[string[]]$Name,
		[ValidateSet('SynopsisOnly',
		'AllExamples',
		'Detailed'
		)]
		[string]$Format
	)
	<#Ideas
	Add custom views and a parameter for the user to switch the view even if they don't know how to do it.
	Maybe instead of select it should be "Properties" and allow wildcards this would be like active directory commands

	#>
	begin{}#begin
	process{

		$help = foreach ($c in $Name){ Get-Help $c -Full }#foreach

		$data = foreach ($h in $help){
			[PSCustomObject]@{
				PSTypeName = "TLDRHelp"
				Name = $h.Name
				Alias = (Get-Alias -Definition $h.Name -ErrorAction SilentlyContinue).Name -join ', '
				ModuleName= "$($h.ModuleName)"
				Synopsis = $h.Synopsis
				Description = $h.Description
				Details = $h.Details
				InputObjects = ($h.inputTypes | out-string).trim()
				OutputObjects = ($h.returnValues | out-string).trim()
				RequiredParams = ($h.Parameters.parameter | Where Required -eq 'True').Name -join ', '
				WildcardsAllowed = ($h.Parameters.parameter | Where globbing -eq 'True').Name -join ', '
				PipelineInputAllowed = (($h.Parameters.parameter | Where pipelineInput -match 'True' | Select @{l='Pipeline';Expr={"$($_.Name) - $($_.pipelineInput -replace 'True \(([A-Za-z]+)\)','$1')"}}).Pipeline | Out-String) -join ', '
				Related = $h.RelatedLinks
				Examples = (($h.Examples.Example | Select @{l='Examples';Expr={"$($_.Title) `n $($_.code )"}}).Examples | Out-String) -join ', '
			}#PSCustomObject
		}#foreach
			switch ($Format) {

			'SynopsisOnly' {
				$results = $data | Format-Table -View $Format
			}#case

			'AllExamples' {
				$results = $data | Format-List -View $Format
			}#case

			'Detailed' {
				$results = $data | Format-Table -View $Format
			}#case

			default {
				$results = $data
			}#defaultcase

			}#switch
		Write-Output $results | Sort PipelineInputAllowed -Descending
	}#process
	end{
	}#end

}#function
