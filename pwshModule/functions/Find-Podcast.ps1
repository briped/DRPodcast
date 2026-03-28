function Find-Podcast {
    [CmdletBinding(DefaultParameterSetName = 'limit')]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('q')]
        [string]
        $Query
        ,
        [Parameter()]
        [ValidateSet('series', 'episodes')]
        [Alias('t')]
        [string]
        $Type = 'series'
        ,
        [Parameter()]
        [Alias('cg')]
        [ValidateSet('dansktop','dokumentar','electronic-dance-music','folk'
                    ,'hip-hop','historie','indie-og-alternative','jazz'
                    ,'kaerlighed-og-sex','klassisk','krimi','kultur','livsstil'
                    ,'musik','nyheder','opera','pop','rock','soul-og-rnb','sport'
                    ,'sundhed','tro-og-eksistens','underholdning','videnskab-og-tech')]
        [string[]]
        $Category
        ,
        [Parameter()]
        [Alias('ch')]
        [ValidateSet('p1','p2','p3','p4','p4aarhus','p4bornholm','p4esbjerg'
                    ,'p4fyn','p4kbh','p4nord','p4sjaelland','p4syd','p4trekanten'
                    ,'p4vest','p5','p6beat','p8jazz','special-radio')]
        [string[]]
        $Channel
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
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
    }
    process {
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Process: BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        $Uri = "$($Config.Uri.Api)/search/$($Type)"
        $Attributes = @{
            Uri         = $Uri
            Method      = 'GET'
            ContentType = 'application/json; charset=utf-8'
        }
        $Option = @{}
        $Option.q = if (!$Query) { '*' } else { $Query }
        if ($Limit -gt 0) { $Option.limit = $Limit }
        if ($All -and !$Limit) { $Option.limit = 100 }
        if (!$All -and $Offset -gt 0) { $Option.offset = $Offset }
        if ($Category) { $Option.categories = ($Category -join ',') }
        if ($Channel) { $Option.channels = ($Channel -join ',') }
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Options: $($Option | ConvertTo-Json -Compress)"
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
            $Items | Add-TitleSlug | Add-ImageUri | Add-RssUri
        } while ($All -and $Items.Count -ge $Option.limit)
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}