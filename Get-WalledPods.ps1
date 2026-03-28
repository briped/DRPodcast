$VerbosePreference = 'Continue'
$Manifest = [System.IO.FileInfo](Join-Path -Path $(Join-Path -Path $PSScriptRoot -ChildPath 'pwshModule') -ChildPath 'DRPodcastShell.psd1')
Import-Module -Force -Name $Manifest

$WalledPath = Join-Path -Path $PSScriptRoot -ChildPath 'walled.json'

$Walled = @()
$Podcasts = Find-DRPodcast -Type series -All
foreach ($Podcast in $Podcasts) {
    if (!$Podcast.podcastUrl) { continue }
    try {
        $Response = Invoke-WebRequest -Uri $Podcast.podcastUrl
    } catch {}
    if ($Response.Content -notmatch 'utm_source=thirdparty') { continue }

    foreach ($Target in @('Podcast', 'SquareImage', 'Default')) {
        Clear-Variable -Name SquareImage -ErrorAction SilentlyContinue
        $SquareImage = $Podcast.imageAssets | Where-Object { $_.ratio -eq '1:1' -and $_.target -eq $Target }
        if (!$SquareImage) { continue }

        $Image = @{}
        $Image.DirectoryName = $Config.Path.Workspace.FullName
        $Image.BaseName = @(
            $Podcast.titleSlug,
            $SquareImage.ratio.Replace(':', '-'),
            $SquareImage.target.ToLower(),
            ($SquareImage.id -split ':')[-1]
        ) -join '_'
        $Image.Extension = ($SquareImage.format -split '/')[-1]
        $Image.Name = "$($Image.BaseName).$($Image.Extension)"
        $Image.FullName = Join-Path -Path $Image.DirectoryName -ChildPath $Image.Name

        Write-Verbose -Message "ImageName: '$($Image.Name)'. Podcast: '$($Podcast.titleSlug)'. Target: '$($SquareImage.target)'. Ratio: '$($SquareImage.ratio)'. Format: '$($SquareImage.format)'."

        Invoke-WebRequest -Uri $SquareImage.uri -OutFile $Image.FullName
        $Variance = Measure-DRImageColorVariance -Path $Image.FullName
        if ($Variance -lt 0.5) {
            Write-Verbose -Message "Image '$($Image.Name)' is solid color. Next."
            Remove-Item -Force -Path $Image.FullName
            continue
        }

        $Attributes = @{
            PositionX     = 0
            PositionY     = 10
            Width         = '180px'
            Opacity       = 70
            ImagePath     = $Image.FullName
            WatermarkPath = $Config.Path.Watermark
            OutputPath    = Join-Path -Path $Config.Path.Cover -ChildPath "$($Podcast.titleSlug).jpg"
        }
        try {
            Write-Verbose -Message "Watermarking '$($Image.Name)' to '$($Podcast.titleSlug)'."
            Add-DRWatermark @Attributes
            Remove-Item -Force -Path $Image.FullName
            break
        }
        catch {
            $_
            #Copy-Item -Force -Path $Image.FullName -Destination $CoverFilePath
        }
    }
    $Walled += $Podcast | Select-Object -Property title, slug, id
}
$Walled | ConvertTo-Json | Out-File -Force -Encoding utf8 -FilePath $WalledPath
$VerbosePreference = 'SilentlyContinue'
