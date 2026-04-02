<#
.SYNOPSIS
Generates hashtable splat templates for a command's parameter sets.

.DESCRIPTION
Get-SplatHelp inspects the specified command and emits one or more hashtable
definitions that can be used for splatting. Each parameter set on the target
command becomes its own hashtable, with keys for every parameter in that set.

.PARAMETER Command
The name of the command to inspect and generate splat templates for.

.PARAMETER Format
Controls how much help text is included in the generated splats.
Use 'WithHelp' to include comment blocks containing the parameter help
description; use 'Clean' to generate only parameter keys with empty values.

.EXAMPLE
PS> Get-SplatHelp -Command Get-ChildItem

Generates one or more hashtable splats for Get-ChildItem's parameter sets,
with empty values for each parameter.

.EXAMPLE
PS> Get-SplatHelp -Command Get-ChildItem -Format WithHelp

Generates hashtable splats for Get-ChildItem, including inline comment blocks
that contain the current help description for each parameter.
#>
Function Get-SplatHelp {
	[CmdletBinding()]
	param(
		[string]$Command,
		[ValidateSet('WithHelp','Clean')]
		[string]$Format = 'Clean'
	)


	$results = switch ($Format) {

		'WithHelp' {
			$ParameterSets = (Get-Command $command).ParameterSets

			$splat = foreach ($set in $parameterSets) {

				$string = "`$$($set.Name) = @{`n"

					foreach ($p in $set.parameters) {

						$string += "`n  $($p.name) = "
						$string += "`n<#`n$( (Get-Help $command -Parameter $($p.Name) ).description.text | Out-String )`n#>`n`n"

				}#foreach

				$string += "`n}#hashtableSplat_$($set.name)`n`n`n`n`n"

				Write-Output $string

			}#foreach

			Write-Output $splat

		}#withHelpSwitch





		'Clean' {
			$ParameterSets = (Get-Command $command).ParameterSets

			$splat = foreach ($set in $parameterSets) {

				$string = "`$$($set.Name) = @{`n"

					foreach ($p in $set.parameters) {

						$string += "`n  $($p.name) = "

				}#foreach

				$string += "`n}#hashtableSplat_$($set.name)`n`n`n`n`n"

				Write-Output $string
			}#foreach

			Write-Output $splat

			}#cleanSwitch
		}#switch

	Write-Output $results
}#function
