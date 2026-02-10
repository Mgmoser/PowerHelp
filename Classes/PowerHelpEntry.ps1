class PowerHelpEntry {
	[string]$Name
	[string]$Alias
	[string]$ModuleName
	[string]$Synopsis
	[string]$Description
	[string]$Details
	[string]$InputObjects
	[string]$OutputObjects
	[string]$RequiredParams
	[string]$WildcardsAllowed
	[string]$PipelineInputAllowed
	[string]$Related
	[string]$Examples

	PowerHelpEntry([object]$HelpInfo) {
		$this.Name = [PowerHelpEntry]::NormalizeText($HelpInfo.Name)
		$this.Alias = ((Get-Alias -Definition $this.Name -ErrorAction SilentlyContinue).Name -join ', ')
		$this.ModuleName = [PowerHelpEntry]::NormalizeText($HelpInfo.ModuleName)
		$this.Synopsis = [PowerHelpEntry]::NormalizeText($HelpInfo.Synopsis)
		$this.Description = [PowerHelpEntry]::JoinTextEntries($HelpInfo.Description)
		$this.Details = [PowerHelpEntry]::NormalizeText($HelpInfo.Details)
		$this.InputObjects = [PowerHelpEntry]::NormalizeText($HelpInfo.inputTypes)
		$this.OutputObjects = [PowerHelpEntry]::NormalizeText($HelpInfo.returnValues)

		$required = @(
			$HelpInfo.Parameters.parameter |
				Where-Object { $_.Required -eq 'True' } |
				ForEach-Object { $_.Name }
		)
		$this.RequiredParams = ($required -join ', ')

		$wildcards = @(
			$HelpInfo.Parameters.parameter |
				Where-Object { $_.globbing -eq 'True' } |
				ForEach-Object { $_.Name }
		)
		$this.WildcardsAllowed = ($wildcards -join ', ')

		$pipelineInput = @(
			$HelpInfo.Parameters.parameter |
				Where-Object { $_.pipelineInput -match 'True' } |
				ForEach-Object {
					$bindingType = ($_.pipelineInput -replace 'True \(([A-Za-z]+)\)', '$1')
					"$($_.Name) - $bindingType"
				}
		)
		$this.PipelineInputAllowed = ($pipelineInput -join ', ')
		$this.Related = [PowerHelpEntry]::NormalizeText($HelpInfo.RelatedLinks)

		$exampleBlocks = [System.Collections.Generic.List[string]]::new()
		$helpExamples = @($HelpInfo.examples.example)

		foreach ($helpExample in $helpExamples) {
			$title = [PowerHelpEntry]::NormalizeText($helpExample.Title)
			$code = [PowerHelpEntry]::NormalizeText($helpExample.Code)

			if ($title -and $code) {
				$exampleBlocks.Add("$title`n$code")
			} elseif ($code) {
				$exampleBlocks.Add($code)
			} elseif ($title) {
				$exampleBlocks.Add($title)
			}

		}

		$this.Examples = ($exampleBlocks -join "`n`n")
	}

	hidden static [string] GetOnelinerFromExampleCode([string]$Code) {
		if ([string]::IsNullOrWhiteSpace($Code)) {
			return ''
		}

		$normalizedCode = $Code -replace "`r", ''
		if ($normalizedCode -match "`n") {
			return ''
		}

		$line = [PowerHelpEntry]::NormalizePromptPrefix($normalizedCode.Trim())
		if ([string]::IsNullOrWhiteSpace($line)) {
			return ''
		}

		if ($line.StartsWith('#')) {
			return ''
		}

		if ([PowerHelpEntry]::LooksLikeCommandOutput($line)) {
			return ''
		}

		if (-not [PowerHelpEntry]::ContainsCommandInvocation($line)) {
			return ''
		}

		return $line
	}

	hidden static [string] GetOnelinersFromExamples([object[]]$Examples) {
		if ($null -eq $Examples -or $Examples.Count -eq 0) {
			return ''
		}

		$onelinerCandidates = [System.Collections.Generic.List[string]]::new()
		foreach ($example in $Examples) {
			$code = [PowerHelpEntry]::NormalizeText($example.Code)
			$oneliner = [PowerHelpEntry]::GetOnelinerFromExampleCode($code)
			if (-not [string]::IsNullOrWhiteSpace($oneliner)) {
				$onelinerCandidates.Add($oneliner)
			}
		}

		return [PowerHelpEntry]::JoinDistinct($onelinerCandidates)
	}

	hidden static [string] NormalizePromptPrefix([string]$Line) {
		if ([string]::IsNullOrWhiteSpace($Line)) {
			return ''
		}

		$normalized = $Line.Trim()
		$normalized = $normalized -replace '^\s*(PS [^>]+>\s*|>>\s*|>\s*)', ''
		return $normalized.Trim()
	}

	hidden static [bool] LooksLikeCommandOutput([string]$Line) {
		if ([string]::IsNullOrWhiteSpace($Line)) {
			return $true
		}

		if ($Line -match '^\s*-{3,}\s*$') {
			return $true
		}

		if ($Line -match '^\s*(Mode|Name|----|Directory:|Hive:)\b') {
			return $true
		}

		return $false
	}

	hidden static [bool] ContainsCommandInvocation([string]$Line) {
		if ([string]::IsNullOrWhiteSpace($Line)) {
			return $false
		}

		return ($Line -match '\b[A-Za-z][A-Za-z0-9]*-[A-Za-z0-9][A-Za-z0-9\-]*\b')
	}

	hidden static [string] JoinDistinct([System.Collections.Generic.List[string]]$Lines) {
		if ($null -eq $Lines -or $Lines.Count -eq 0) {
			return ''
		}

		$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
		$ordered = [System.Collections.Generic.List[string]]::new()

		foreach ($line in $Lines) {
			$normalized = [PowerHelpEntry]::NormalizeText($line)
			if ([string]::IsNullOrWhiteSpace($normalized)) {
				continue
			}

			if ($seen.Add($normalized)) {
				$ordered.Add($normalized)
			}
		}

		return ($ordered -join [Environment]::NewLine)
	}

	hidden static [string] JoinTextEntries([object]$Value) {
		if ($null -eq $Value) {
			return ''
		}

		$entries = @($Value | ForEach-Object {
			if ($null -eq $_) {
				return
			}

			if ($_.PSObject.Properties.Match('Text').Count -gt 0) {
				[PowerHelpEntry]::NormalizeText($_.Text)
			} else {
				[PowerHelpEntry]::NormalizeText($_)
			}
		})

		return ($entries -join [Environment]::NewLine).Trim()
	}

	hidden static [string] NormalizeText([object]$Value) {
		if ($null -eq $Value) {
			return ''
		}

		if ($Value -is [string]) {
			return $Value.Trim()
		}

		return (($Value | Out-String).Trim())
	}
}
