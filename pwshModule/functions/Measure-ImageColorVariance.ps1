function Measure-ImageColorVariance {
    [CmdletBinding()]
    param (
        # Path to image file that should be tested.
        [Parameter(Mandatory = $true
                , Position = 0
                , ValueFromPipeline = $true
                , ValueFromPipelineByPropertyName = $true)]
        [Alias('PSPath', 'Image', 'i')]
        [System.IO.FileInfo]
        $Path
        ,
        # X starting position of area to be excluded in the brightness calculation.
        [Parameter()]
        [Alias('ex')]
        [int]
        $ExcludeX = 45
        ,
        # Y starting position of area to be excluded in the brightness calculation.
        [Parameter()]
        [Alias('ey')]
        [int]
        $ExcludeY = 45
        ,
        # Width of area to be excluded in the brightness calculation.
        [Parameter()]
        [Alias('ew')]
        [int]
        $ExcludeWidth = 90
        ,
        # Height of area to be excluded in the brightness calculation.
        [Parameter()]
        [Alias('eh')]
        [int]
        $ExcludeHeight = 90
    )
    begin {
        if ($DebugPreference -ne 'SilentlyContinue') {
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
        # Load the necessary .NET assemblies
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Runtime.InteropServices
    }
    process {
        Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Processing image: $($Path.Name)"
        Write-Debug -Message "$($MyInvocation.MyCommand.Name): BoundParameters: $($PSBoundParameters | ConvertTo-Json -Compress -WarningAction SilentlyContinue)"
        # Load the image
        $Image = [System.Drawing.Image]::FromFile($Path.FullName)
        try {
            # Validate exclusion area doesn't exceed image bounds
            $ActualExcludeWidth = [Math]::Min($ExcludeWidth, $Image.Width - $ExcludeX)
            $ActualExcludeHeight = [Math]::Min($ExcludeHeight, $Image.Height - $ExcludeY)
            if ($ExcludeX -lt 0 -or $ExcludeY -lt 0 -or $ExcludeX -ge $Image.Width -or $ExcludeY -ge $Image.Height) {
                Write-Warning "Exclusion area is outside image bounds. Processing entire image."
                $ActualExcludeWidth = 0
                $ActualExcludeHeight = 0
            }

            # Lock the bitmap for direct memory access
            $BitmapData = $Image.LockBits(
                [System.Drawing.Rectangle]::new(0, 0, $Image.Width, $Image.Height),
                [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
                $Image.PixelFormat
            )
            $Stride = $BitmapData.Stride
            $Scan0 = $BitmapData.Scan0
            $PixelBytes = [byte[]]::new($BitmapData.Height * $Stride)

            # Copy bitmap data to managed array
            [System.Runtime.InteropServices.Marshal]::Copy($Scan0, $PixelBytes, 0, $PixelBytes.Length)

            # Unlock the bitmap
            $Image.UnlockBits($BitmapData)

            # Determine bytes per pixel based on pixel format
            $BytesPerPixel = [System.Drawing.Image]::GetPixelFormatSize($Image.PixelFormat) / 8
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): PixelFormat: $($Image.PixelFormat), BytesPerPixel: $BytesPerPixel"
            if ($BytesPerPixel -lt 3) {
                Write-Warning "Image format for has less than 3 color channels. Cannot process."
                return $false
            }

            # Use individual typed variables to avoid PowerShell type coercion issues
            [double]$ColorSumR = 0.0
            [double]$ColorSumG = 0.0
            [double]$ColorSumB = 0.0
            [double]$ColorSquaredSumR = 0.0
            [double]$ColorSquaredSumG = 0.0
            [double]$ColorSquaredSumB = 0.0
            [int]$PixelCount = 0

            # Iterate through pixels using raw byte data
            for ($y = 0; $y -lt $Image.Height; $y++) {
                for ($x = 0; $x -lt $Image.Width; $x++) {
                    # Skip pixels within the exclusion area
                    if ($x -ge $ExcludeX -and $x -lt ($ExcludeX + $ActualExcludeWidth) -and 
                        $y -ge $ExcludeY -and $y -lt ($ExcludeY + $ActualExcludeHeight)) { continue }

                    # Calculate byte offset in the pixel array
                    $Offset = $y * $Stride + $x * $BytesPerPixel

                    # Extract RGB values (accounting for different pixel formats)
                    # Most common formats: BGR or BGRA (Windows default)
                    [double]$B = $PixelBytes[$Offset]
                    [double]$G = $PixelBytes[$Offset + 1]
                    [double]$R = $PixelBytes[$Offset + 2]

                    # Accumulate sums for average calculation
                    $ColorSumR += $R
                    $ColorSumG += $G
                    $ColorSumB += $B

                    # Accumulate squared sums for variance calculation
                    $ColorSquaredSumR += $R * $R
                    $ColorSquaredSumG += $G * $G
                    $ColorSquaredSumB += $B * $B

                    $PixelCount++
                }
            }

            if ($PixelCount -le 0) {
                Write-Warning "No pixels processed after exclusion area."
                return $false
            }
            # Calculate average color
            $AverageColorR = $ColorSumR / $PixelCount
            $AverageColorG = $ColorSumG / $PixelCount
            $AverageColorB = $ColorSumB / $PixelCount

            # Calculate variance using the formula: Var = E[X²] - E[X]²
            # This is more efficient than recalculating deviations
            $VarianceR = ($ColorSquaredSumR / $PixelCount) - ($AverageColorR * $AverageColorR)
            $VarianceG = ($ColorSquaredSumG / $PixelCount) - ($AverageColorG * $AverageColorG)
            $VarianceB = ($ColorSquaredSumB / $PixelCount) - ($AverageColorB * $AverageColorB)

            $Variance = ($VarianceR + $VarianceG + $VarianceB) / 3
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Average Color: R=$([int]$AverageColorR), G=$([int]$AverageColorG), B=$([int]$AverageColorB)"
            $Variance
        }
        catch {
            return $false
        }
        finally {
            $Image.Dispose()
        }
    }
    end {
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}
