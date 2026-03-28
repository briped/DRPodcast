function Add-RssUri {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromRemainingArguments = $false
                ,  Position = 0)]
        [Alias('p')]
        [object]
        $Podcast
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
        $Uri = [string]$Config.Uri.Rss.ToString().Replace('{{titleSlug}}', $($Podcast.titleSlug))
        if (!$Podcast.rssUri) { $Podcast | Add-Member -NotePropertyName 'rssUri' -NotePropertyValue $Uri }
        else { $Podcast.rssUri = $Uri }
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