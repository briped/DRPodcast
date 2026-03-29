function New-Rss {
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
        ,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $Template
    )
    begin {
        if ($DebugPreference -ne 'SilentlyContinue') {
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
        $TemplateContent = [System.IO.File]::ReadAllText($Template.FullName, [System.Text.Encoding]::UTF8)
        $MustacheTemplate = Get-MustacheTemplate -Template $TemplateContent
    }
    process {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Processing: $($Podcast.title) ($($Podcast.id); $($Podcast.titleSlug))."
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        #https://www.rssboard.org/

        # Create a copy of the podcast object for feed specific changes.
        $Feed = ($Podcast | ConvertTo-Json -Depth 10) | ConvertFrom-Json

        # Update the feed title.
        $TitleAppend = ' (recycled)'
        if ($Feed.title -notmatch "$([regex]::Escape($TitleAppend))$") { $Feed.title += $TitleAppend }
        # Escape HTML reserved characters with hex-entities
        $Feed.title = $Feed.title | ConvertTo-HexTML

        # Escape HTML reserved characters with hex-entities
        $Feed.description = $Feed.description | ConvertTo-HexTML

        # Add/update the LastBuildDate for the feed.
        $LastBuildDate = (Get-Date).ToString("ddd, dd MMM yyyy HH:mm:ss zzz")
        if (!$Feed.lastBuildDate) { $Feed | Add-Member -NotePropertyName 'lastBuildDate' -NotePropertyValue $LastBuildDate }
        else { $Feed.lastBuildDate = $LastBuildDate }

        # Find the Podcast cover from the image assets and add/update the feed object with the uri.
        $Cover = Join-Path -Path $Config.Path.Cover.FullName -ChildPath "$($Podcast.titleSlug).jpg"
        if (Test-Path -PathType Leaf -Path $Cover) {
            # Use local cover.
            $Urlbuilder = [System.UriBuilder]::new($Config.Uri.Base)
            $Urlbuilder.Path = "/cover/$($Podcast.titleSlug).jpg"
        }
        else {
            # No local cover. Check for original cover.
            foreach ($Target in @('Podcast', 'SquareImage', 'Default')) {
                $ImageAsset = $Podcast.imageAssets | Where-Object { $_.ratio -eq '1:1' -and $_.target -eq $Target } | Select-Object -First 1 -ExpandProperty uri
                if ($null -ne $ImageAsset) { break }
            }
            if ($null -ne $ImageAsset) {
                # Use original cover.
                $Urlbuilder = [System.UriBuilder]::new($ImageAsset)
                $Urlbuilder.Query = $Urlbuilder.Query.Replace('&', '&#x26;')
            }
            else {
                # Use unknown cover.
                $Urlbuilder = [System.UriBuilder]::new($Config.Uri.Base)
                $Urlbuilder.Path = '/assets/icon-logo-drlyd-recycled-unknown-800x800.png'
            }
        }
        if (!$Feed.feedCoverUri) { $Feed | Add-Member -NotePropertyName 'feedCoverUri' -NotePropertyValue $Urlbuilder.Uri.AbsoluteUri }
        else { $Feed.feedCoverUri = $Urlbuilder.Uri.AbsoluteUri }

        foreach ($Category in $Feed.categories) {
            # Escape HTML reserved characters with hex-entities
            $Category = $Category | ConvertTo-HexTML
        }

        foreach ($Episode in $Feed.episodes) {
            # Escape HTML reserved characters with hex-entities
            $Episode.title = $Episode.title | ConvertTo-HexTML
            $Episode.description = $Episode.description | ConvertTo-HexTML

            # Convert the the episode publishTime to RSS required format.
            #TODO: I should probably do some sort of sanity checking on the publishTime to ensure proper conversion.
            $Episode.publishTime = $Episode.publishTime.ToString("ddd, dd MMM yyyy HH:mm:ss zzz")

            # Convert duration from milliseconds to required RSS format and add it to the feed object.
            $Duration = (New-TimeSpan -Milliseconds $Episode.durationMilliseconds).ToString('hh\:mm\:ss')
            if (!$Episode.duration) { $Episode | Add-Member -NotePropertyName 'duration' -NotePropertyValue $Duration }
            else { $Episode.duration = $Duration }

            # Reorder/sort the audio assets.
            $AudioAssets  = $Episode.audioAssets | Where-Object { $_.format -in @('mp3', 'mp4') } | Sort-Object -Property format,bitrate
            $AudioAssets += $Episode.audioAssets | Where-Object { $_.format -in @('hls') } | Sort-Object -Property bitrate
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
        ConvertFrom-MustacheTemplate -Template $MustacheTemplate -Values $Feed
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}