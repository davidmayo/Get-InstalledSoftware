# Get-InstalledSoftware
Get installed software from a remote PC without using WS-Man


NAME
    Get-InstalledSoftware
    
SYNOPSIS
    Get installed software from a remote PC without using WS-Man
    
    
SYNTAX
    Get-InstalledSoftware [[-ComputerName] <String[]>] [-Credential <PSCredential>] [<CommonParameters>]
    
    
DESCRIPTION
    Get installed software from a remote PC without using WS-Man. Uses DCOM via Get-WMIObject and StdRegProv methods.
    

PARAMETERS
    -ComputerName <String[]>
        Computer name(s) to be queried. Default is "Localhost".
        
        Required?                    false
        Position?                    1
        Default value                Localhost
        Accept pipeline input?       true (ByValue, ByPropertyName)
        Accept wildcard characters?  false
        
    -Credential <PSCredential>
        An optional [PSCredential] to be passed to Get-WMIobject.
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see 
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216). 
    
INPUTS
    
OUTPUTS
    An array of [PSCustomObject] representing installed applications with these fields:
    ComputerName, SoftwareName, SoftwareVersion, Publisher, RegistryLocation
    
    
NOTES
        Most people would recommend turning on WS-Man and do this via PS-Remoting.
        But some of us work in environments where that's not allowed by policy, so here we are.
    
    -------------------------- EXAMPLE 1 --------------------------
    
    PS C:\>Get-InstalledSoftware
    
    By default, will return a [PSCustomObject] array with information about software installed on Localhost
    
    
    
    
    -------------------------- EXAMPLE 2 --------------------------
    
    PS C:\>Get-Content c:\server-list.txt | Get-InstalledSoftware
    
    Pipeline input is supported.
    
    -------------------------- EXAMPLE 3 --------------------------
    
    PS C:\>Get-InstalledSoftware 'PC-NAME' | Where-Object {$_.Publisher -match 'Adobe'}
    
    Only get software published by Adobe.




