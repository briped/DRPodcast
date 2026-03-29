New-Variable -Force -Scope Script -Name Config -Value @{}
$Config.Uri = @{}
$Config.Uri.Base       = [uri]'https://dr.xmpl.dk'
$Config.Uri.Rss        = [uri]'https://dr.xmpl.dk/feed/{{titleSlug}}.xml'
$Config.Uri.Api        = [uri]'https://api.dr.dk/radio/v3'
$Config.Uri.Image      = [uri]'https://asset.dr.dk/imagescaler/?protocol=https&server=api.dr.dk&file={{assetFile}}&scaleAfter=crop&quality={{quality}}&w={{width}}&h={{height}}'
$Config.AssetFile      = [string]'/radio/v2/images/raw/{{assetId}}'

$Config.Path = @{}
$Config.Path.Module    = [System.IO.DirectoryInfo]$PSScriptRoot
$Config.Path.Workspace = [System.IO.DirectoryInfo](Join-Path -Path $Config.Path.Module.Parent -ChildPath '.workspace')
$Config.Path.Pages     = [System.IO.DirectoryInfo](Join-Path -Path $Config.Path.Module.Parent -ChildPath '.pages')
$Config.Path.Assets    = [System.IO.DirectoryInfo](Join-Path -Path $Config.Path.Pages -ChildPath 'assets')
$Config.Path.Cover     = [System.IO.DirectoryInfo](Join-Path -Path $Config.Path.Pages -ChildPath 'cover')
$Config.Path.Feed      = [System.IO.DirectoryInfo](Join-Path -Path $Config.Path.Pages -ChildPath 'feed')
$Config.Path.Watermark = [System.IO.FileInfo](Join-Path -Path $Config.Path.Assets -ChildPath 'icon-recycle-469x454.png')

Export-ModuleMember -Variable Config

$FunctionsDirectory = [System.IO.DirectoryInfo](Join-Path -Path $Config.Path.Module -ChildPath 'functions')
Get-ChildItem -Recurse -File -Path $FunctionsDirectory -Filter '*.ps1' | 
    Where-Object { $_.BaseName -notmatch '(^\.|\.dev$|\.test$)' } | 
    ForEach-Object {
        . $_.FullName
    }
