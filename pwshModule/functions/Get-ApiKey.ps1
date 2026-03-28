function Get-ApiKey {
    [CmdletBinding()]
    param(
        [Parameter()]
        [uri]
        $Uri = 'https://www.dr.dk/lyd/'
    )

    begin {
        if ($DebugPreference -ne 'SilentlyContinue') {
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
    }
    process {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Process: BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        $File = [System.IO.FileInfo](Join-Path -Path $PSScriptRoot -ChildPath '.apiKey')
        if ($File.Exists) {
            $ApiKey = Get-Content -TotalCount 1 -Path $File
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): $($File.Name) exists and contains '$($ApiKey)'."
            return $ApiKey
        }

        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Trying to fetch '$($Uri)'."
        try {
            $Attributes = @{
                Uri = $Uri
                UseBasicParsing = $true
            }
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Invoke-WebRequest @$($Attributes | ConvertTo-Json -Compress)"
            $Response = Invoke-WebRequest @Attributes
        }
        catch { throw $_ } #TODO: Better error handling?
        # Find the API Client JavaScript file.
        $JsPath = ([regex]::Matches($Response.Content, '<script[^>]+src=["'']?([^"'']+_app-[^"'']+\.js)["'']?[^>]*>', 'IgnoreCase')).Groups[1].Value
        # Set default JsUri, assuming absolute path.
        $JsUri = "$($Uri.Scheme)://$($Uri.DnsSafeHost)$($JsPath)"
        if ($JsPath[0] -ne '/') {
            # Path is not absolute. Set relative to Uri.AbsolutePath
            $JsUri = [uri]"$($Uri.Scheme)://$($Uri.DnsSafeHost)$(($Uri.AbsolutePath+$JsPath) -replace '/+', '/')"
        }
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Trying to fetch '$($JsUri)'."
        try {
            $Attributes = @{
                Uri = $JsUri
                UseBasicParsing = $true
            }
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Invoke-WebRequest @$($Attributes | ConvertTo-Json -Compress)"
            $Response = Invoke-WebRequest @Attributes
        }
        catch { throw $_ } #TODO: Better error handling?
        # Extract API key.
        $ApiKey = ([regex]::Matches($Response.Content, '"/lyd".{0,20}"([a-z0-9]{32})"', 'IgnoreCase')).Groups[1].Value
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Likely API key: $($ApiKey)"

        # Test the API key.
        #TODO: Find a good endpoint to test it against.
        try {
            $Attributes = @{
                ContentType = 'application/json; charset=utf-8'
                Headers     = @{ 'x-apikey' = $ApiKey }
                Method      = 'GET'
                Uri         = "$($Config.Uri.Api)"
            }
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Invoke-RestMethod @$($Attributes | ConvertTo-Json -Compress)"
            $Response = Invoke-RestMethod @Attributes
        }
        catch {
            #throw $_.ErrorDetails.Message | ConvertFrom-Json
        }
        return $ApiKey
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}