function Test-RegValue
{

	<#
	.SYNOPSIS
	       Determines if a registry value exists.

	.DESCRIPTION
	       Use Test-RegValue to determine if the registry value exists.

	.PARAMETER ComputerName
	    	An array of computer names. The default is the local computer.

	.PARAMETER Hive
	   	The HKEY to open, from the RegistryHive enumeration. The default is 'LocalMachine'.
	   	Possible values:

		- ClassesRoot
		- CurrentUser
		- LocalMachine
		- Users
		- PerformanceData
		- CurrentConfig
		- DynData

	.PARAMETER Key
	       The path of the registry key to open.

	.PARAMETER Value
	       The name of the registry value.

	.PARAMETER Ping
	       Use ping to test if the machine is available before connecting to it.
	       If the machine is not responding to the test a warning message is output.

	.PARAMETER PassThru
	       Passes the registry value, if found.

	.EXAMPLE
		$Key = "SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine"
		Test-RegValue -ComputerName SERVER1 -Key $Key -Value PowerShellVersion

		True


		Description
		-----------
		The command checks if the PowerShellVersion value exists on SERVER1.
		If the Value was found the result is True, else False.

	.EXAMPLE
		Get-Content servers.txt | Test-RegValue -Key $Key -PassThru

		ComputerName Hive            Key                  Value              Data   Type
		------------ ----            ---                  -----              ----   ----
		SERVER1      LocalMachine    SOFTWARE\Microsof... PowerShellVersion  1.0    String
		SERVER2      LocalMachine    SOFTWARE\Microsof... PowerShellVersion  1.0    String
		SERVER3      LocalMachine    SOFTWARE\Microsof... PowerShellVersion  1.0    String

		Description
		-----------
		The command uses the Get-Content cmdlet to get the server names from a text file. The names are piped into
		Test-RegValue. If the Value was found and PassThru is specidied, the result is the registry value custom object.

	.OUTPUTS
		System.Boolean
		PSFanatic.Registry.RegistryValue (PSCustomObject)

	.LINK
		Get-RegValue
		Remove-RegValue

	#>


	[OutputType('System.Boolean','PSFanatic.Registry.RegistryValue')]
	[CmdletBinding(DefaultParameterSetName="__AllParameterSets")]

	param(
		[Parameter(
			Position=0,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="An array of computer names. The default is the local computer."
		)]
		[Alias("CN","__SERVER","IPAddress")]
		[string[]]$ComputerName="",

		[Parameter(
			Position=1,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The HKEY to open, from the RegistryHive enumeration. The default is 'LocalMachine'."
		)]
		[ValidateSet("ClassesRoot","CurrentUser","LocalMachine","Users","PerformanceData","CurrentConfig","DynData")]
		[string]$Hive="LocalMachine",

		[Parameter(
			Mandatory=$true,
			Position=2,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The path of the subkey to open."
		)]
		[string]$Key,

		[Parameter(
			Mandatory=$true,
			Position=3,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="The name of the value to test."
		)]
		[string]$Value,

		[switch]$Ping,

		[switch]$PassThru
	)


	process
	{

	    	Write-Verbose "Enter process block..."

		foreach($c in $ComputerName)
		{
			try
			{
				if($c -eq "")
				{
					$c=$env:COMPUTERNAME
					Write-Verbose "Parameter [ComputerName] is not presnet, setting its value to local computer name: [$c]."

				}

				if($Ping)
				{
					Write-Verbose "Parameter [Ping] is presnet, initiating Ping test"

					if( !(Test-Connection -ComputerName $c -Count 1 -Quiet))
					{
						Write-Warning "[$c] doesn't respond to ping."
						return
					}
				}


				Write-Verbose "Starting remote registry connection against: [$c]."
				Write-Verbose "Registry Hive is: [$Hive]."
				$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]$Hive,$c)

				Write-Verbose "Open remote subkey: [$Key]"
				$subKey = $reg.OpenSubKey($key)

				if(!$subKey)
				{
					Throw "Key '$Key' doesn't exist."
				}

				if($Value -ne '(default)')
				{
					$rv=$subKey.GetValue($Value,-1)

					if($rv -eq -1)
					{
						$false
					}
					else
					{
						if($PassThru)
						{
							Write-Verbose "Parameter [PassThru] is presnet, creating PSFanatic registry custom objects."
							Write-Verbose "Create PSFanatic registry value custom object."

							$pso = New-Object PSObject -Property @{
								ComputerName=$c
								Hive=$Hive
								Value=$Value
								Key=$Key
								Data=$subKey.GetValue($Value)
								Type=$subKey.GetValueKind($Value)
							}

							Write-Verbose "Adding format type name to custom object."
							$pso.PSTypeNames.Clear()
							$pso.PSTypeNames.Add('PSFanatic.Registry.RegistryValue')
							$pso
						}
						else
						{
							$true
						}
					}
				}

				Write-Verbose "Closing remote registry connection on: [$c]."
				$subKey.close()
			}
			catch
			{
				#Write-Error $_
				$false
			}
		}

		Write-Verbose "Exit process block..."
	}
}presentpresentpresent