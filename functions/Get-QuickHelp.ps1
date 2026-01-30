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

	.PARAMETER Select
	Specifies the level of detail to retrieve.
	The valid options are:
	- `SynopsisOnly`: Retrieves only the synopsis of the command.
	- `AllExamples`: Retrieves all examples along with other details like required parameters and pipeline input.
	- `Detailed`: Retrieves detailed information, including input/output objects, description, and examples.

	.EXAMPLE
	Get-QuickHelp -command gal -Select SynopsisOnly

	Name      Synopsis
	----      --------
	Get-Alias Gets the aliases for the current session.


	.EXAMPLE
	qhelp -command gal -Select SynopsisOnly

	Name      Synopsis
	----      --------
	Get-Alias Gets the aliases for the current session.

	#>
	[CmdletBinding()]
	[Alias('qhelp')]
	param(
		[Parameter(Mandatory=$True, ValueFromPipeline=$True)]
		[string[]]$Command,
		[ValidateSet('SynopsisOnly',
		'AllExamples',
		'Detailed'
		)]
		[string]$Select
	)
	<#Ideas
	Add custom views and a parameter for the user to switch the view even if they don't know how to do it.
	Maybe instead of select it should be "Properties" and allow wildcards this would be like active directory commands

	#>

	$help = foreach ($c in $Command){ Get-Help $c -Full }#foreach

	$Results = foreach ($h in $help){
		switch ($Select) {

		'SynopsisOnly' {
			[PSCustomObject]@{
				Name = $h.Name
				Alias = (Get-Alias -Definition $h.Name).Name | Out-String
				Synopsis = $h.Synopsis
			}#PSCustomObject
		}#case

		'AllExamples' {
			[PSCustomObject]@{
				Name = $h.Name
				Alias = (Get-Alias -Definition $h.Name).Name | Out-String
				ModuleName= "$($h.ModuleName) Related Links: $($h.relatedLinks)"
				Synopsis = $h.Synopsis
				RequiredParams = (($h.Parameters.parameter | Where Required -eq 'True' | Select Name).Name | Out-String) -join ', '
				WildcardsAllowed = (($h.Parameters.parameter | Where globbing -eq 'True' | Select Name).Name | Out-String) -join ', '
				PipelineInputAllowed = (($h.Parameters.parameter | Where pipelineInput -match 'True' | Select @{l='Pipeline';Expr={"$($_.Name) - $($_.pipelineInput -replace 'True \(([A-Za-z]+)\)','$1')"}}).Pipeline | Out-String) -join ', '
				Examples = (($h.Examples.Example | Select @{l='Examples';Expr={"$($_.Title) `n $($_.code )"}}).Examples | Out-String) -join ', '
			}#PSCustomObject
		}#case

		'Detailed' {
			[PSCustomObject]@{
				Name = $h.Name
				Alias = (Get-Alias -Definition $h.Name).Name | Out-String
				ModuleName= "$($h.ModuleName) Related Links: $($h.relatedLinks)"
				Synopsis = $h.Synopsis
				Description = $h.Description
				Details = $h.Details
				InputObjects = ($h.inputTypes | out-string).trim()
				OutputObjects = ($h.returnValues | out-string).trim()
				RequiredParams = (($h.Parameters.parameter | Where Required -eq 'True' | Select Name).Name | Out-String) -join ', '
				WildcardsAllowed = (($h.Parameters.parameter | Where globbing -eq 'True' | Select Name).Name | Out-String) -join ', '
				PipelineInputAllowed = (($h.Parameters.parameter | Where pipelineInput -match 'True' | Select @{l='Pipeline';Expr={"$($_.Name) - $($_.pipelineInput -replace 'True \(([A-Za-z]+)\)','$1')"}}).Pipeline | Out-String) -join ', '
				Examples = (($h.Examples.Example | Select @{l='Examples';Expr={"$($_.Title) `n $($_.code )"}}).Examples | Out-String) -join ', '
			}#PSCustomObject
		}#case

		default {
			[PSCustomObject]@{
				Name = $h.Name
				Alias = (Get-Alias -Definition $h.Name).Name | Out-String
				ModuleName= "$($h.ModuleName) Related Links: $($h.relatedLinks)"
				Synopsis = $h.Synopsis
				RequiredParams = (($h.Parameters.parameter | Where Required -eq 'True' | Select Name).Name | Out-String) -join ', '
				WildcardsAllowed = (($h.Parameters.parameter | Where globbing -eq 'True' | Select Name).Name | Out-String) -join ', '
				PipelineInputAllowed = (($h.Parameters.parameter | Where pipelineInput -match 'True' | Select @{l='Pipeline';Expr={"$($_.Name) - $($_.pipelineInput -replace 'True \(([A-Za-z]+)\)','$1')"}}).Pipeline | Out-String) -join ', '
				Examples = (($h.Examples.Example | Select @{l='Examples';Expr={"$($_.Title) `n $($_.code )"}} -first 1).Examples | Out-String) -join ', '
			}#PSCustomObject

		}#defaultcase

		}#switch
	}#foreach

	Write-Output $Results


}#function
