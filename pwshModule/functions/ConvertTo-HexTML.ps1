function ConvertTo-HexTML {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true
                ,  ValueFromPipeline = $true)]
        [string[]]
        $String
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
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): Process: BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        foreach ($s in $String) {
            if ($s -match '&#x[0-9a-f]{2};') { continue }
            $n = ''
            for ($i = 0; $i -lt $s.Length; $i++) {
                $c = $s[$i]
                $e = [System.Web.HttpUtility]::HtmlEncode($c)
                $n += if ($e -ne $c) { ("&#x{0:X};" -f [int][char]$c) } else { $c }
            }
            $n
        }
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}
