<#
.Synopsis
   Get installed software from a remote PC without using WS-Man
.DESCRIPTION
   Get installed software from a remote PC without using WS-Man. Uses DCOM via Get-WMIObject and StdRegProv methods.
.EXAMPLE
   Get-InstalledSoftware | Format-List
   ComputerName     : Localhost
   SoftwareName     : Microsoft Office 365 - en-us
   SoftwareVersion  : 16.0.11601.20178
   Publisher        : Microsoft Corporation
   RegistryLocation : HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\O365HomePremRetail - en-us
   [Further output omitted]
.EXAMPLE
   Get-Content c:\server-list.txt | Get-InstalledSoftware
   Pipeline input is supported. The PC Name 
.EXAMPLE
   Get-InstalledSoftware 'PC-NAME' | Where-Object {$_.Publisher -match 'Adobe'}
   Get software published by Adobe and installed on PC-NAME
.OUTPUTS
   An array of [PSCustomObject] representing installed applications with these fields:
   ComputerName, SoftwareName, SoftwareVersion, Publisher, RegistryLocation
.NOTES
   Most people would recommend turning on WS-Man and do this via PS-Remoting.
   But some of us work in environments where that's not allowed by policy, so here we are.
#>
function Get-InstalledSoftware
{
    [CmdletBinding()]
    [Alias('software')]
    Param
    (
        # Computer name(s) to be queried. Default is "Localhost".
        [Parameter(Mandatory = $False,
                   ValueFromPipelineByPropertyName = $True,
                   ValueFromPipeline = $True,
                   Position = 0)]
        [Alias('Name','PC','Computer','DNShostname','cn')]
        [string[]]$ComputerName = 'Localhost',

        # An optional [PSCredential] to be passed to Get-WMIobject.
        [Parameter(Mandatory = $False)]
        [PSCredential]$Credential = $null
    )
    Begin
    {
        # The base registry locations we'll be crawling through.
        $UninstallRegistryLocations = @(
            'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'
            'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )

        # A magic number representing the HKLM hive when using the WMI StdRegProv functions.
        $HKLM = [UInt32] "0x80000002"
    }
    Process
    {
        foreach( $Computer in $ComputerName )
        {
            if( -not (Test-Connection $Computer -Count 1 -Quiet) )
            {
                Write-Error "[$Computer] not pingable"
                continue
            }

            # Get the StdRegProv object via WMI. Will not work with Get-CimInstance
            $WMIarguments = @{
                List         = $true
                Class        = 'StdRegProv'
                Namespace    = 'root\default'
                ComputerName = $Computer
                ErrorAction  = 'SilentlyContinue'
            }

            # Add the credential, if one was passed.
            if( $Credential )
            {
                $WMIarguments['Credential'] = $Credential
            }
            $RegistryProvider = Get-Wmiobject @WMIarguments

            if( -not $RegistryProvider )
            {
                Write-error "Unable to get registry provider for [$computer]."
                continue
            }

            # Iterate through the two registry locations with 'Uninstall' information
            foreach( $UninstallRegistryLocation in $UninstallRegistryLocations )
            {
                try
                {
                    # Each sub-key from the base location represents an installed application.
                    # The key itself is often (though not always) a GUID.
                    $SoftwareRegistryKeys = ($RegistryProvider.EnumKey($HKLM, $UninstallRegistryLocation)).sNames
                    foreach($SoftwareRegistryKey in $SoftwareRegistryKeys)
                    {
                        $SoftwareRegistryKeyFullPath = Join-Path -Path $UninstallRegistryLocation -ChildPath $SoftwareRegistryKey

                        # The values in these subkeys have a bunch of information about the software. We'll only grab a few.
                        $SoftwareName      = $RegistryProvider.GetStringValue($HKLM, $SoftwareRegistryKeyFullPath, "DisplayName").sValue
                        $SoftwareVersion   = $RegistryProvider.GetStringValue($HKLM, $SoftwareRegistryKeyFullPath, "DisplayVersion").sValue
                        $SoftwarePublisher = $RegistryProvider.GetStringValue($HKLM, $SoftwareRegistryKeyFullPath, "Publisher").sValue
                        if( -not [string]::IsNullOrWhiteSpace($SoftwareName) )
                        {
                            Write-Output -InputObject (
                                [pscustomobject]@{
                                    ComputerName     = $Computer
                                    SoftwareName     = $SoftwareName
                                    SoftwareVersion  = $SoftwareVersion
                                    Publisher        = $SoftwarePublisher
                                    RegistryLocation = Join-Path -Path 'HKLM\' -ChildPath $SoftwareRegistryKeyFullPath
                                }
                            )
                        }
                    }
                } # end   try
                catch
                {
                    write-error "Error enumerating registry values on [$computer]."
                }
            } #end   foreach( $UninstallRegistryLocation in $UninstallRegistryLocations )
        } # end   foreach( $computer in $ComputerName )
    } # end   Process block
    End
    {
    }
} # end  function Get-InstalledSoftware

$software = Get-InstalledSoftware -ComputerName localhost

$software | fl
