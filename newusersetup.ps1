#The block of code below will promp the user for first/last name and department and make sure they enter something. 
[CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
param (
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$FirstName,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$LastName,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Department,

    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Location,

    [Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Title
)

try {
    #This will create a username with first initial + lastname. Note the (0,1) in $FirstName.Substring(0, 1)...
    #is saying to extract the first character (0) of the string, and the 1 is specifiying the length of the substring to extract. 
    #The -f operator is used to format the string by replacing the placeholders with the values specified after the operator.
    $userName = '{0}{1}' -f $FirstName.Substring(0, 1), $LastName


	#i=2 so $FirstName.Substring will now be comprised of 2 characters. 
    #Checks AD to see if the username already exists. 
    #If it does already exists, keeps incrementing $i until an available username is found. 
    #($userName -notlike "$FirstName*) If this condition is false, it means that the generated username starts with the user's first name, which is not allowed...
    #as we have run out of characters. Once either condition are false, the loop stops. 
    $i = 2
	while ((Get-AdUser -Filter "samAccountName -eq '$userName'") -and ($userName -notlike "$FirstName*")) {
		Write-Warning -Message "The username [$($userName)] already exists. Trying another..."
		$userName = '{0}{1}' -f $FirstName.Substring(0, $i), $LastName
		Start-Sleep -Seconds 1
		$i++
	}

    if ($userName -like "$FirstName*") {
		throw 'No available username could be found'
        
        ## Check to see if the OU with the name of the location exists
    } 
    elseif (-not ($ou = Get-ADOrganizationalUnit -Filter "Name -eq '$Location'")) {
        throw "The Active Directory OU for location [$($Location)] could not be found."
	} 
    elseif (-not (Get-AdGroup -Filter "Name -eq '$Department'")) {
		throw "The group [$($Department)] does not exist."
	}
    else {
		## Create a random password
		Add-Type -AssemblyName 'System.Web'
		$password = [System.Web.Security.Membership]::GeneratePassword((Get-Random -Minimum 12 -Maximum 16), 3)
		$secPw = ConvertTo-SecureString -String $password -AsPlainText -Force
    }
        ## Create a hashtable which will later be passed into New-AdUser
        $newUserParams = @{
			GivenName             = $FirstName
			Surname               = $LastName
			Name                  = "$Firstname $Lastname"
            SamAccountName        = $userName 
			AccountPassword       = $secPw
			Enabled               = $true
            Title                 = $Title
			Department            = $Department
			Path                  = $ou.DistinguishedName
			Confirm               = $false
        }
        if ($PSCmdlet.ShouldProcess("AD user [$userName]", "Create AD user $FirstName $LastName")) {
			## Create the user
			New-AdUser @newUserParams
			
			## Add the user to the department group
			Add-AdGroupMember -Identity $Department -Members $userName


			[pscustomobject]@{
				FirstName      = $FirstName
				LastName       = $LastName
				Department     = $Department
                Title          = $Title
				Password       = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($secPw))
			}
		}
	}    
catch {
    Write-Error -Message $_.Exception.Message
    <#Do this if a terminating exception happens#>
}
