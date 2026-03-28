$Manifest = [System.IO.FileInfo](Join-Path -Path $(Join-Path -Path $PSScriptRoot -ChildPath 'pwshModule') -ChildPath 'DRPodcastShell.psd1')
Import-Module -Force -Name $Manifest
Start-Transcript -OutputDirectory (Join-Path -Path $Config.Path.Module.Parent -ChildPath '.transcripts')
$VerbosePreference = 'Continue'
#$DebugPreference = 'Continue'

$WalledFile = [System.IO.FileInfo](Join-Path -Path $PSScriptRoot -ChildPath 'walled.json')

#<#
$Walled = Get-Content -Raw -Encoding utf8 -Path $WalledFile.FullName | ConvertFrom-Json
$Podcasts = $Walled | 
    Get-DRPodcast | 
    Sort-Object -Unique -Property id
#>

foreach ($Podcast in $Podcasts) {
    $Refresh = $false
    Write-Verbose -Message "Processing: '$($Podcast.title)'."
    if (!$Podcast.episodes) {
        Write-Verbose -Message "Adding episodes to '$($Podcast.title)'."
        $Podcast | Get-DREpisode -All
    }
    $CacheFile = Join-Path -Path $Config.Path.Workspace -ChildPath "$($Podcast.titleSlug).json"
    if (!(Test-Path -PathType Leaf -Path $CacheFile)) { $Refresh = $true }
    else {
        $Cache = Get-Content -Raw -Encoding utf8 -Path $CacheFile | ConvertFrom-Json -Depth 10
        if ($null -ne $Cache.latestEpisodeStartTime -and $null -ne $Podcast.latestEpisodeStartTime -and 
            $Podcast.latestEpisodeStartTime -gt $Cache.latestEpisodeStartTime) { $Refresh = $true }
        else { $Refresh = $false }
    }
    if ($Refresh -eq $true) {
        $Podcast | ConvertTo-Json -Depth 10 | Out-File -Force -Encoding utf8 -FilePath $CacheFile
        $XmlFile = [System.IO.FileInfo](Join-Path -Path $Config.Path.Feed -ChildPath "$($Podcast.titleSlug).xml")
        $TemplateFile = [System.IO.FileInfo](Join-Path -Path $Config.Path.Module -ChildPath 'podcast.template.rss')
        try {
            $Podcast | New-DRRss -Template $TemplateFile | Out-File -Force -Encoding utf8 -FilePath $XmlFile
        }
        catch {
            #$_ | Write-Error -ErrorAction Stop
        }
    }
}
$Podcasts | New-DRJson | Out-File -Force -Encoding utf8 -FilePath $(Join-Path -Path $Config.Path.Pages -ChildPath "podcasts.json")
$VerbosePreference = 'SilentlyContinue'
#$DebugPreference = 'SilentlyContinue'
Stop-Transcript