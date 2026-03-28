function Get-Episode {
    [CmdletBinding(DefaultParameterSetName = 'limit')]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromRemainingArguments = $false
                ,  Position = 0)]
        [Alias('p')]
        [object]
        $Podcast
        ,
        [Parameter(ParameterSetName = 'limit')]
        [Parameter(ParameterSetName = 'all')]
        [Parameter(ParameterSetName = 'offset'
                ,  Mandatory = $true)]
        [Alias('l')]
        [int]
        $Limit
        ,
        [Parameter(ParameterSetName = 'offset')]
        [Alias('o')]
        [int]
        $Offset
        ,
        [Parameter(ParameterSetName = 'all')]
        [Alias('a')]
        [switch]
        $All
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

        $Uri = "$($Config.Uri.Api)/series/$($Podcast.id)/episodes"
        $Attributes = @{
            Uri         = $Uri
            Method      = 'GET'
            ContentType = 'application/json; charset=utf-8'
        }
        $Option = @{}
        if ($Limit -gt 0) { $Option.limit = $Limit }
        if ($All -and !$Limit) { $Option.limit = 100 }
        if (!$All -and $Offset -gt 0) { $Option.offset = $Offset }
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Options: $($Option | ConvertTo-Json -Compress)"
        $Items = @()
        do {
            $UriQuery = @()
            foreach ($Key in $Option.Keys) {
                $UriQuery += "$($Key)=$([uri]::EscapeDataString($Option[$Key]))"
            }
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Query: $($UriQuery -join '&')"
            if ($UriQuery.Count -gt 0) { $Attributes.Uri = "$($Uri)?$($UriQuery -join '&')" }
            $Response = Invoke-ApiRequest @Attributes
            $Items += $Response.items
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Request returned $($Response.items.Count) items."
            if ($All -and $null -eq $Option.offset) { $Option.offset = 0 }
            $Option.offset += $Option.limit
        } while ($All -and $Response.items.Count -ge $Option.limit)
        $Items | Add-AudioContentType
        if (!$Podcast.episodes) { $_ | Add-Member -NotePropertyName 'episodes' -NotePropertyValue $Items }
        else { $Podcast.episodes = $Items }
        #$Podcast
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}
function Get-EpisodeV1 {
    [CmdletBinding(DefaultParameterSetName = 'limit')]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true
                ,  ValueFromPipelineByPropertyName = $true
                ,  ValueFromRemainingArguments = $false
                ,  Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Id
        ,
        [Parameter(ParameterSetName = 'limit')]
        [Parameter(ParameterSetName = 'all')]
        [Parameter(ParameterSetName = 'offset'
                ,  Mandatory = $true)]
        [Alias('l')]
        [int]
        $Limit
        ,
        [Parameter(ParameterSetName = 'offset')]
        [Alias('o')]
        [int]
        $Offset
        ,
        [Parameter(ParameterSetName = 'all')]
        [Alias('a')]
        [switch]
        $All
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
        $Uri = "$($Config.Uri.Api)/series/$($Id)/episodes"
        $Attributes = @{
            Uri         = $Uri
            Method      = 'GET'
            ContentType = 'application/json; charset=utf-8'
        }
        $Option = @{}
        if ($Limit -gt 0) { $Option.limit = $Limit }
        if ($All -and !$Limit) { $Option.limit = 100 }
        if (!$All -and $Offset -gt 0) { $Option.offset = $Offset }
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Options: $($Option | ConvertTo-Json -Compress)"
        do {
            $UriQuery = @()
            foreach ($Key in $Option.Keys) {
                $UriQuery += "$($Key)=$([uri]::EscapeDataString($Option[$Key]))"
            }
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Query: $($UriQuery -join '&')"
            if ($UriQuery.Count -gt 0) { $Attributes.Uri = "$($Uri)?$($UriQuery -join '&')" }
            $Response = Invoke-ApiRequest @Attributes
            $Items = $Response.items
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Request returned $($Items.Count) items."
            if ($All -and $null -eq $Option.offset) { $Option.offset = 0 }
            $Option.offset += $Option.limit
            $Items | Add-AudioContentType
            if (!$_.episodes) { $_ | Add-Member -NotePropertyName 'episodes' -NotePropertyValue $Uri }
            else { $Asset.uri = $Uri }
        } while ($All -and $Items.Count -ge $Option.limit)
    }
    end {
        $Stopwatch.Stop()
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
    }
}