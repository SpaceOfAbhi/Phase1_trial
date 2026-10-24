$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repo = (Resolve-Path "$PSScriptRoot/../..").Path
$app = Join-Path $repo 'workout_ai'
$lime = [System.Drawing.ColorTranslator]::FromHtml('#D5FF63')
$mark = [System.Drawing.Drawing2D.GraphicsPath]::new()
$mark.AddLines([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(0,94), [System.Drawing.PointF]::new(72,67), [System.Drawing.PointF]::new(72,207)))
$mark.AddBezier(72,207, 72,214, 76,217, 84,217)
$mark.AddLines([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(84,217), [System.Drawing.PointF]::new(166,217), [System.Drawing.PointF]::new(166,269), [System.Drawing.PointF]::new(65,269)))
$mark.AddBezier(65,269, 22,269, 0,247, 0,204)
$mark.CloseFigure()
$mark.StartFigure()
$mark.AddLines([System.Drawing.PointF[]]@([System.Drawing.PointF]::new(92,55), [System.Drawing.PointF]::new(168,0), [System.Drawing.PointF]::new(168,106)))
$mark.AddBezier(168,106, 168,148, 143,173, 92,181)
$mark.CloseFigure()
$brush = [System.Drawing.SolidBrush]::new($lime)

function Write-Icon([string]$file, [int]$size, [bool]$transparent = $false) {
    # Render large first so even the 32px favicon keeps smooth edges.
    $bitmap = [System.Drawing.Bitmap]::new(1024,1024)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    if (!$transparent) { $graphics.Clear([System.Drawing.Color]::FromArgb(28,28,30)) }
    $height = if ($transparent) { 960.0 } else { 614.4 }
    $scale = $height / 269.0
    $graphics.TranslateTransform([single]((1024-168*$scale)/2), [single]((1024-$height)/2))
    $graphics.ScaleTransform([single]$scale,[single]$scale)
    $graphics.FillPath($brush,$mark)
    $output = [System.Drawing.Bitmap]::new($size,$size)
    $resizer = [System.Drawing.Graphics]::FromImage($output)
    $resizer.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $resizer.DrawImage($bitmap,0,0,$size,$size)
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($file)) | Out-Null
    $output.Save($file,[System.Drawing.Imaging.ImageFormat]::Png)
    $resizer.Dispose(); $output.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
    $check = [System.Drawing.Image]::FromFile($file)
    if ($check.Width -ne $size -or $check.Height -ne $size) { throw "Wrong icon size: $file" }
    $check.Dispose()
}

Write-Icon "$app/assets/branding/liftly-mark.png" 512 $true
Write-Icon "$PSScriptRoot/liftly-app-icon.png" 1024
Write-Icon "$app/web/favicon.png" 32
foreach ($size in 192,512) {
    Write-Icon "$app/web/icons/Icon-$size.png" $size
    Write-Icon "$app/web/icons/Icon-maskable-$size.png" $size
}
$densities = @{mdpi=48; hdpi=72; xhdpi=96; xxhdpi=144; xxxhdpi=192}
foreach ($density in $densities.Keys) {
    Write-Icon "$app/android/app/src/main/res/mipmap-$density/ic_launcher.png" $densities[$density]
}
$catalog = Get-Content "$app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json" -Raw | ConvertFrom-Json
foreach ($icon in $catalog.images) {
    $size = [int]([double]($icon.size.Split('x')[0]) * [double]($icon.scale.TrimEnd('x')))
    Write-Icon "$app/ios/Runner/Assets.xcassets/AppIcon.appiconset/$($icon.filename)" $size
}
$brush.Dispose(); $mark.Dispose()
Write-Output 'Liftly icons generated and dimensions checked.'
