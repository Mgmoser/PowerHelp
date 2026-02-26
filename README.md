# PowerHelp

### A simple module that assists the user in getting useful help snippets fast!
* Get the help you need to see.
* Get examples from the PowerShell help files, but only the oneliners, not the long paragraphs.
* Find commands that take pipeline input quickly.
* Easily see which parameters are required.
* Easily see what inputs and outputs come from a command.
* And more!

# Installation
* Clone this GitHub repository to your $Env:PSModulePath.
* ```powershell
  #Use the below complicated oneliner to easily get the paths in which all your PowerShell modules are installed. Use the path that has your username in it.
  (Get-Module -ListAvailable).path -replace '^(.+?Modules).+$','$1' | Group | select Name

  #Use the below if you just want to see paths with your username. (There's just a where clause added)

  (Get-Module -ListAvailable).path -replace '^(.+?Modules).+$','$1' | Group | Where name -match $env:USERNAME | select Name
  
  #Or you can use the classic command, but it may not make it as obvious.:
  $Env:PSModulePath -split ';'
  
  #Go to the path where your modules are located. You can also look at other modules and their Path parameters to find where this location is.
  #For example
  Set-Location $HOME\Documents\PowerShell\Modules

  #In this directory run your Github clone command:
  gh repo clone Mgmoser/PowerHelp

  #Now run the below to import the module.
  Import-Module PowerHelp -Force -Verbose
  ```
