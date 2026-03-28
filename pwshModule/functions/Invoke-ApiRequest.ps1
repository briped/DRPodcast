function Invoke-ApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ApiUrl')]
        [uri]
        $Uri
        ,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Body
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ContentType = 'application/json; charset=utf-8'
    )
    begin {
        if ($DebugPreference -ne 'SilentlyContinue') {
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
    }
    process {
        write-Verbose -Message "$($MyInvocation.MyCommand.Name): Processing request to '$Uri' with method '$Method'."
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        # Check for existing headers.Initialize if missing or incorrect.
        if (!$Script:Headers -or $Script:Headers.GetType().Name -ne 'Hashtable') {
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Re-initiating headers."
            Remove-Variable -Force -Name Headers -Scope Script -ErrorAction SilentlyContinue
            $Script:Headers = @{}
        }
        # Check for API key. Add if missing or incorrect.
        if (!$Script:Headers.'x-apikey' -or $Script:Headers.'x-apikey'.Length -ne 32) {
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Setting x-apikey"
            $Script:Headers.'x-apikey' = Get-ApiKey
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Headers: $($Script:Headers | ConvertTo-Json -Compress)"
        }

        $Attributes = @{
            Uri         = $Uri
            Method      = $Method
            ContentType = $ContentType
            Headers     = $Script:Headers
        }
        if ($Body) {
            $Attributes.Body = $Body
        }
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Invoke-RestMethod $($Attributes | ConvertTo-Json -Compress)"
        Invoke-RestMethod @Attributes
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}