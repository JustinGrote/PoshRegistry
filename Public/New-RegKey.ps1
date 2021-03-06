function New-RegKey
{

	<#
	.SYNOPSIS
	       Creates a new registry key on local or remote machines.

	.DESCRIPTION
	       Use New-RegKey to create a new registry key on local or remote machines.

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
	       The path of the registry key.

	.PARAMETER Name
	       The name of the new key to create.

	.PARAMETER Ping
	       Use ping to test if the machine is available before connecting to it.
	       If the machine is not responding to the test a warning message is output.

	.PARAMETER PassThru
	       Passes the newly custom object to the pipeline. By default, this function does not generate any output.

	.EXAMPLE
		$Key = "SOFTWARE\MyCompany"
		New-RegKey -ComputerName SERVER1,SERVER2 -Key $Key -Name NewSubKey -PassThru

		ComputerName Hive            Key                       SubKeyCount ValueCount
		------------ ----            ---                       ----------- ----------
		SERVER1      LocalMachine    SOFTWARE\MyCompany\New... 0           0
		SERVER2      LocalMachine    SOFTWARE\MyCompany\New... 0           0


		Description
		-----------
		The command creates new regitry key on two remote computers.
		When PassThru is present the command returns the registry key custom object.

	.EXAMPLE
		Get-Content servers.txt | New-RegKey -Key $Key -Name NewSubKey -PassThru | Set-RegString -Value TestValue -Data TestData -Force -PassThru

		ComputerName Hive            Key                  Value       Data     Type
		------------ ----            ---                  -----       ----     ----
		SERVER1      LocalMachine    SOFTWARE\MyCompan... TestValue   TestData String
		SERVER2      LocalMachine    SOFTWARE\MyCompan... TestValue   TestData String
		SERVER3      LocalMachine    SOFTWARE\MyCompan... TestValue   TestData String


		Description
		-----------
		The command uses the Get-Content cmdlet to get the server names from a text file. The names are piped into
		New-RegKey which creates the key in the remote computers.
		The result of New-RegKey is piped into Set-RegString which creates a new String value under the new key and sets its data.

	.OUTPUTS
		PSFanatic.Registry.RegistryKey (PSCustomObject)

	.LINK
		Get-RegKey
		Remove-RegKey
		Test-RegKey

	#>


	[OutputType('PSFanatic.Registry.RegistryKey')]
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

		[Parameter(Mandatory=$true,Position=3,ValueFromPipelineByPropertyName=$true)]
		[string]$Name,

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

				Write-Verbose "Open remote subkey: [$Key] with write access."
				$subKey = $reg.OpenSubKey($Key,$true)

				if(!$subKey)
				{
					Throw "Key '$Key' doesn't exist."
				}


				Write-Verbose "Creating new Key."
				$new = $subKey.CreateSubKey($Name)

				if($PassThru)
				{
					Write-Verbose "Parameter [PassThru] is presnet, creating PSFanatic registry custom objects."
					Write-Verbose "Create PSFanatic registry key custom object."

					$pso = New-Object PSObject -Property @{
						ComputerName=$c
						Hive=$Hive
						Key="$Key\$Name"
						Name=$Name
						SubKeyCount=$new.SubKeyCount
						ValueCount=$new.ValueCount
					}

					Write-Verbose "Adding format type name to custom object."
					$pso.PSTypeNames.Clear()
					$pso.PSTypeNames.Add('PSFanatic.Registry.RegistryKey')
					$pso
				}

				Write-Verbose "Closing remote registry connection on: [$c]."
				$subKey.close()
			}
			catch
			{
				Write-Error $_
			}
		}

		Write-Verbose "Exit process block..."
	}
}presentpresentpresent