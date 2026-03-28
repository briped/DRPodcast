function Add-Watermark {
    [CmdletBinding()]
    param (
        # Path to image file that should be watermarked.
        [Parameter(Mandatory = $true)]
        [Alias('ip', 'Image', 'Img')]
        [System.IO.FileInfo]
        $ImagePath
        ,
        # Path to where the watermarked image should be saved.
        [Parameter(Mandatory = $true)]
        [Alias('op', 'Output', 'Out')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutputPath
        ,
        # Path to the watermark.
        [Parameter()]
        [Alias('wp', 'Watermark')]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $WatermarkPath
        ,
        # X starting position of the watermark. Defaults to 0.
        [Parameter()]
        [Alias('x')]
        [int]
        $PositionX = 0
        ,
        # Y starting position of the watermark. Defaults to 0.
        [Parameter()]
        [Alias('y')]
        [int]
        $PositionY = 10
        ,
        # Width of the watermark. Can be specified in pixels or percentage. If no unit is found the number is read as pixels. Defaults to watermark width.
        [Parameter()]
        [ValidatePattern('[1-9]+(px|%)?')]
        [Alias('w')]
        [string]
        $Width = '180px'
        ,
        # Height of the watermark. Can be specified in pixels or percentage. If no unit is found the number is read as pixels. Defaults to watermark height.
        [Parameter()]
        [ValidatePattern('[1-9]+(px|%)?')]
        [Alias('h')]
        [string]
        $Height
        ,
        # Opacity of the watermark in percent.
        [Parameter()]
        [ValidateRange(0, 100)]
        [Alias('o')]
        [int]
        $Opacity = 70
        ,
        # X starting position of area to be excluded in the brightness calculation. Defaults to 0.
        [Parameter()]
        [Alias('ex')]
        [int]
        $ExcludeX = 45
        ,
        # Y starting position of area to be excluded in the brightness calculation. Defaults to 0.
        [Parameter()]
        [Alias('ey')]
        [int]
        $ExcludeY = 45
        ,
        # Width of area to be excluded in the brightness calculation. Defaults to image width.
        [Parameter()]
        [Alias('ew')]
        [int]
        $ExcludeWidth = 90
        ,
        # Height of area to be excluded in the brightness calculation. Defaults to image height.
        [Parameter()]
        [Alias('eh')]
        [int]
        $ExcludeHeight = 90
    )

    begin{
        if ($DebugPreference -ne 'SilentlyContinue') {
            Write-Debug -Message "$($MyInvocation.MyCommand.Name): Begin."
            $Stopwatch = [System.Diagnostics.Stopwatch]::new()
            $Stopwatch.Reset()
            $Stopwatch.Start()
        }
        # Load the necessary .NET assemblies
        Add-Type -AssemblyName System.Drawing
    }
    process{
        # Load the image and the watermark
        $Image = [System.Drawing.Image]::FromFile($ImagePath.FullName)
        $Watermark = [System.Drawing.Image]::FromFile($WatermarkPath.FullName)

        # Calculate the aspect ratio of the watermark
        $Ratio = $Watermark.Width / $Watermark.Height
        Write-Verbose -Message "Watermark ratio is '$($Ratio)'."

        # Parse the requested dimensions of the watermark.
        if ($Height -match '(?<n>\d+)(?<u>px|%)?') {
            [int]$Height = if ($Matches.u -eq '%') { [int](($Image.Height / 100) * $Matches.n) } else { [int]$Matches.n }
        }
        if ($Width -match '(?<n>\d+)(?<u>px|%)?') {
            [int]$Width = if ($Matches.u -eq '%') { [int](($Image.Width / 100) * $Matches.n) } else { [int]$Matches.n }
        }

        # Calculate the dimensions of the watermark
        if (!$Width -and !$Height) {
            [int]$Width = $Watermark.Width
            [int]$Height = $Watermark.Height
        }
        elseif (!$Height) {
            [int]$Height = [int]($Width / $Ratio)
        }
        elseif (!$Width) {
            [int]$Width = [int]($Height * $Ratio)
        }
        Write-Verbose -Message "Watermark width: '$($Width)'; height: '$($Height)'."

        # Create a graphics object from the image
        $Graphics = [System.Drawing.Graphics]::FromImage($Image)

        # Calculate the brightness exclusion area.
        # Set to 0 if null, otherwise the actual value.
        $ExcludeX = [int]$ExcludeX
        $ExcludeY = [int]$ExcludeY
        # Set the missing exclude dimension to image dimension.
        if ($ExcludeWidth -and !$ExcludeHeight) {
            $ExcludeHeight = $Image.Height
        }
        elseif ($ExcludeHeight -and !$ExcludeWidth) {
            $ExcludeWidth = $Image.Width
        }

        $Brightness = 0.0
        $PixelCount = 0
        for ($i = $PositionX; $i -lt $PositionX + $Width; $i++) {
            for ($j = $PositionY; $j -lt $PositionY + $Height; $j++) {
                if ($i -lt $Image.Width -and $j -lt $Image.Height) {
                    # Skip pixel from brightness check.
                    if (!$ExcludeWidth -and !$ExcludeHeight) { continue }
                    if ($i -ge $ExcludeX -and $i -lt ($ExcludeX + $ExcludeWidth) -and 
                        $j -ge $ExcludeY -and $j -lt ($ExcludeY + $ExcludeHeight)) { Continue }

                    $Pixel = $Image.GetPixel($i, $j)
                    $Brightness += ($Pixel.R * 0.299 + $Pixel.G * 0.587 + $Pixel.B * 0.114) / 255
                    $PixelCount++
                }
            }
        }
        if ($PixelCount -gt 0) {
            $Brightness /= $PixelCount
        }

        $AdjustedWatermark = [System.Drawing.Bitmap]::new($Width, $Height)
        $GraphicsWatermark = [System.Drawing.Graphics]::FromImage($AdjustedWatermark)
        $GraphicsWatermark.DrawImage($Watermark, [System.Drawing.Rectangle]::new(0, 0, $Width, $Height))
        for ($i = 0; $i -lt $Width; $i++) {
            for ($j = 0; $j -lt $Height; $j++) {
                $Pixel = $AdjustedWatermark.GetPixel($i, $j)
                $Alpha = $Pixel.A
                if ($Pixel.R -eq 0 -and $Pixel.G -eq 0 -and $Pixel.B -eq 0) {
                    if ($Brightness -lt 0.5) {
                        $NewColor = [System.Drawing.Color]::FromArgb($Alpha, 255, 255, 255) # White on dark
                    }
                    else {
                        $NewColor = [System.Drawing.Color]::FromArgb($Alpha, 0, 0, 0) # Black on bright
                    }
                }
                else {
                    $NewColor = [System.Drawing.Color]::FromArgb($Alpha, $Pixel.R, $Pixel.G, $Pixel.B)
                }
                $AdjustedWatermark.SetPixel($i, $j, $NewColor)
            }
        }

        [float]$Opacity = if ($Opacity -gt 0) { $Opacity / 100 } else { $Opacity }
        $ColorMatrix = New-Object System.Drawing.Imaging.ColorMatrix
        $ColorMatrix.Matrix33 = $Opacity

        $ImageAttributes = New-Object System.Drawing.Imaging.ImageAttributes
        $ImageAttributes.SetColorMatrix($ColorMatrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)

        $Graphics.DrawImage(
            $AdjustedWatermark,
            [System.Drawing.Rectangle]::new($PositionX, $PositionY, $Width, $Height),
            0,
            0,
            $AdjustedWatermark.Width,
            $AdjustedWatermark.Height,
            [System.Drawing.GraphicsUnit]::Pixel,
            $ImageAttributes
        )

        $Image.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

        $Graphics.Dispose()
        $Image.Dispose()
        $Watermark.Dispose()
        $GraphicsWatermark.Dispose()
        $AdjustedWatermark.Dispose()
    }
    end{
        if ($DebugPreference -ne 'SilentlyContinue') {
            $Stopwatch.Stop()
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Execution time: $($Stopwatch.Elapsed.ToString())"
            Write-Verbose -Message "$($MyInvocation.MyCommand.Name): End."
        }
    }
}