function Add-ImageUri {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromRemainingArguments = $false
                ,  Position = 0)]
        [Alias('p')]
        [object]
        $Podcast
        ,
        [Parameter()]
        [Alias('w')]
        [int]
        $Width = 720
        ,
        [Parameter()]
        [Alias('q')]
        [ValidateRange(1, 10)]
        [int]
        $Quality = 7
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
        foreach ($Asset in $Podcast.imageAssets) {
            # Calculate height from width while keeping ratio.
            $Ratio = $Asset.ratio -split ':'
            $Height = [Math]::Round($Width / ($Ratio[0] / $Ratio[1]))
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Height: $Height."
            # Insert asset id and make string ready for posting.
            $AssetFile = [uri]::EscapeDataString($Config.AssetFile.Replace('{{assetId}}', $Asset.id))
            $Uri = [string]$Config.Uri.Image.ToString().Replace('{{assetFile}}', $AssetFile).Replace('{{quality}}', ($Quality * 10)).Replace('{{width}}', $Width).Replace('{{height}}', $Height)
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Uri: $Uri."
            # Add/update the asset uri.
            if (!$Asset.uri) { $Asset | Add-Member -NotePropertyName 'uri' -NotePropertyValue $Uri }
            else { $Asset.uri = $Uri }
        }
        $Podcast
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}