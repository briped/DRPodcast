function New-Json {
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
        if ($DebugPreference -ne 'SilentlyContinue') {
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
        $Shows = @()
    }
    process {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Processing: $($Podcast.title) ($($Podcast.id))."
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
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
        $Shows += [PSCustomObject]@{
            title    = $Podcast.title
            xml      = "$($Podcast.titleSlug).xml"
            cover    = $Urlbuilder.Uri.AbsoluteUri
            episodes = $Podcast.numberOfEpisodes
        }
    }
    end {
        [PSCustomObject]@{
            podcasts = $Shows | Sort-Object -Descending -Property lastBuildDate
            lastUpdated = [datetime]::Now.ToString('yyyy-MM-ddTHH:mm:ssK')
        } | ConvertTo-Json
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}