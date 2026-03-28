function Update-AudioAsset {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true
                ,  ValueFromRemainingArguments = $false
                ,  Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.Object]
        $Podcast
    )
    begin {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin."
        $Stopwatch = [System.Diagnostics.Stopwatch]::new()
        $Stopwatch.Reset()
        $Stopwatch.Start()
    }
    process {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Process: $($Podcast.title) ($($Podcast.id))."
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): BoundParameters: $(($MyInvocation.BoundParameters.Keys | ForEach-Object { "[$($MyInvocation.BoundParameters[$_].GetType().Name)]$($_)=$($MyInvocation.BoundParameters[$_])" }) -join '; ');"
        foreach ($Episode in $Podcast.episodes) {
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Episode: $($Episode.title) ($($Episode.id))."
            # Convert the the episode publishTime to RSS required format.
            $Episode.publishTime = $Episode.publishTime.ToString("ddd, dd MMM yyyy HH:mm:ss zzz")
            # Convert duration from milliseconds to required RSS format and add it to the feed object.
            $Duration = (New-TimeSpan -Milliseconds $Episode.durationMilliseconds).ToString('hh\:mm\:ss')
            if (!$Episode.duration) { $Episode | Add-Member -NotePropertyName 'duration' -NotePropertyValue $Duration }
            else { $Episode.duration = $Duration }
            # Reorder/sort the audio assets.
            $AudioAssets  = $Episode.audioAssets | 
                Where-Object { $_.format -in @('mp3', 'mp4') } | 
                Sort-Object -Property format,bitrate
            $AudioAssets += $Episode.audioAssets | 
                Where-Object { $_.format -in @('hls') } | 
                Sort-Object -Property bitrate
            # Add the content-type for the respektive formats.
            foreach ($AudioAsset in $AudioAssets) {
                if (!$AudioAsset.contentType) { $AudioAsset | Add-Member -NotePropertyName 'contentType' -NotePropertyValue $null }
                switch ($AudioAsset.format) {
                    'mp4' { $AudioAsset.contentType = 'audio/x-m4a' }
                    'mp3' { $AudioAsset.contentType = 'audio/mpeg' }
                    'hls' { $AudioAsset.contentType = 'application/vnd.apple.mpegurl' }
                }
            }
        }
    }
    end {
        $Stopwatch.Stop()
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
    }
}