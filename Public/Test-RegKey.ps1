function Test-RegKey
{

	<#
	.SYNOPSIS
	       Determines if a registry key exists.

	.DESCRIPTION
	       Use Test-RegKey to determine if a registry key exists.

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

	.PARAMETER Ping
	       Use ping to test if the machine is available before connecting to it.
	       If the machine is not responding to the test a warning message is output.

	.PARAMETER PassThru
	       Passes the registry key, if found.

	.EXAMPLE
		$Key = "SOFTWARE\MyCompany"
		Test-RegKey -ComputerName SERVER1 -Key $Key

		True


		Description
		-----------
		The command checks if the MyCompany key exists on SERVER1.
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
		The command uses the Get-Content cmdlet to get the server names from a text file. The computer names are piped into
		Test-RegValue. If the Value was found and PassThru is specidied, the result is the registry value custom object.

	.OUTPUTS
		System.Boolean
		PSFanatic.Registry.RegistryValue (PSCustomObject)

	.LINK
		Get-RegKey
		New-RegKey
		Remove-RegKey
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
				$subKey = $reg.OpenSubKey($Key)

				if($subKey)
				{
					Write-Verbose "Registry sub key: $subKey has been found"

					if($PassThru)
					{
						Write-Verbose "Parameter [PassThru] is presnet, creating PSFanatic registry custom objects."
						Write-Verbose "Create PSFanatic registry key custom object."

						$pso = New-Object PSObject -Property @{
							ComputerName=$c
							Hive=$Hive
							Key=$Key
							SubKeyCount=$subKey.SubKeyCount
							ValueCount=$subKey.ValueCount
						}

						Write-Verbose "Adding format type name to custom object."
						$pso.PSTypeNames.Clear()
						$pso.PSTypeNames.Add('PSFanatic.Registry.RegistryKey')
						$pso
					}
					else
					{
						$true
					}
				}
				else
				{
					Write-Verbose "Registry sub key: $subKey cannot be found"
					$false
				}

				Write-Verbose "Closing remote registry connection on: [$c]."
				$subKey.close()
			}
			catch
			{
				#Write-Error $_
			}
		}

		Write-Verbose "Exit process block..."
	}
}presentpresentpresent