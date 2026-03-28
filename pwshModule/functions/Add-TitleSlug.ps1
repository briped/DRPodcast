function Add-TitleSlug {
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
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
    }
    process {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Process: $($Podcast.title) ($($Podcast.id))."
        $TitleSlug = $Podcast.slug.Replace("-$($Podcast.productionNumber)", '')
        if (!$Podcast.titleSlug) { $Podcast | Add-Member -NotePropertyName 'titleSlug' -NotePropertyValue $TitleSlug }
        else { $Podcast.titleSlug = $TitleSlug }
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