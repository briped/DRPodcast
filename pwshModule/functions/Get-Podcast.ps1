function Get-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true
                ,  ValueFromRemainingArguments = $false
                ,  Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Id
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
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Process: $($Podcast.title) ($($Podcast.id))."
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        $Uri = "$($Config.Uri.Api)/series/$($Id)"
        $Attributes = @{
            Uri         = $Uri
            Method      = 'GET'
            ContentType = 'application/json; charset=utf-8'
        }
        $Podcast = Invoke-ApiRequest @Attributes
        # Add/update image assets.
        $Podcast | Add-TitleSlug | Add-ImageUri | Add-RssUri
        # Return the podcast object.
        $Podcast
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}