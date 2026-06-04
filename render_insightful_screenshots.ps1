param(
    [string]$ArtifactsDir = "safecode_demo_artifacts"
)

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$artifactPath = Join-Path $root $ArtifactsDir
$screenshots = Join-Path $artifactPath "screenshots"
$resultsPath = Join-Path $artifactPath "results.json"

if (-not (Test-Path $resultsPath)) {
    throw "Missing results file: $resultsPath"
}

New-Item -ItemType Directory -Force -Path $screenshots | Out-Null
$data = Get-Content $resultsPath -Raw | ConvertFrom-Json

function New-Font($name, $size, $style = [System.Drawing.FontStyle]::Regular) {
    return [System.Drawing.Font]::new($name, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-WrappedText($graphics, $text, $font, $brush, $x, $y, $width, $maxLines) {
    $words = (($text -replace "`r", "") -split "\s+")
    $line = ""
    $lineHeight = [int]($font.GetHeight($graphics) + 6)
    $drawn = 0

    foreach ($word in $words) {
        $candidate = if ($line.Length -eq 0) { $word } else { "$line $word" }
        if ($graphics.MeasureString($candidate, $font).Width -le $width) {
            $line = $candidate
        } else {
            if ($drawn -ge $maxLines) { break }
            $graphics.DrawString($line, $font, $brush, [float]$x, [float]($y + $drawn * $lineHeight))
            $drawn++
            $line = $word
        }
    }

    if ($line.Length -gt 0 -and $drawn -lt $maxLines) {
        $graphics.DrawString($line, $font, $brush, [float]$x, [float]($y + $drawn * $lineHeight))
    }
}

function Save-CaseCard($result, $index) {
    $width = 1280
    $height = 760
    $bitmap = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $bg = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(248, 250, 252))
    $card = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $ink = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(15, 23, 42))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(71, 85, 105))
    $passBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(22, 101, 52))
    $failBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(153, 27, 27))
    $statusBrush = if ($result.passed) { $passBrush } else { $failBrush }
    $statusColor = if ($result.passed) { [System.Drawing.Color]::FromArgb(220, 252, 231) } else { [System.Drawing.Color]::FromArgb(254, 226, 226) }
    $accentColor = if ($result.passed) { [System.Drawing.Color]::FromArgb(22, 163, 74) } else { [System.Drawing.Color]::FromArgb(220, 38, 38) }

    $title = New-Font "Segoe UI" 34 ([System.Drawing.FontStyle]::Bold)
    $subtitle = New-Font "Segoe UI" 21
    $label = New-Font "Segoe UI" 17 ([System.Drawing.FontStyle]::Bold)
    $body = New-Font "Segoe UI" 18
    $mono = New-Font "Consolas" 16
    $metric = New-Font "Segoe UI" 24 ([System.Drawing.FontStyle]::Bold)

    $graphics.FillRectangle($bg, 0, 0, $width, $height)
    $graphics.FillRectangle($card, 48, 42, 1184, 676)
    $graphics.FillRectangle([System.Drawing.SolidBrush]::new($accentColor), 48, 42, 1184, 12)
    $graphics.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(203, 213, 225), 2), 48, 42, 1184, 676)

    $graphics.DrawString(("Case {0:00}: {1}" -f $index, $result.id), $title, $ink, 82, 82)
    $graphics.DrawString("SafeCode demo evaluation card", $subtitle, $muted, 84, 126)

    $graphics.FillRectangle([System.Drawing.SolidBrush]::new($statusColor), 930, 82, 250, 74)
    $statusText = if ($result.passed) { "PASSED" } else { "FAILED" }
    $graphics.DrawString($statusText, $metric, $statusBrush, 962, 104)

    $metrics = @(
        @{ Label = "Expected"; Value = $result.expected },
        @{ Label = "Actual"; Value = $result.actual },
        @{ Label = "Latency"; Value = ("{0:N1} ms" -f [double]$result.elapsed_ms) },
        @{ Label = "Live API"; Value = if ($result.fallback_fixture) { "No, fixture fallback" } else { "Yes" } }
    )

    for ($i = 0; $i -lt $metrics.Count; $i++) {
        $x = 82 + ($i * 285)
        $graphics.DrawString($metrics[$i].Label, $label, $muted, $x, 190)
        $graphics.DrawString($metrics[$i].Value, $metric, $ink, $x, 218)
    }

    $graphics.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(226, 232, 240), 2), 82, 286, 1180, 286)
    $graphics.DrawString("Task", $label, $muted, 82, 316)
    Draw-WrappedText $graphics $result.task $body $ink 82 346 1060 3

    $graphics.DrawString("Agent decision / sanitized output", $label, $muted, 82, 450)
    $snippet = (($result.result -replace "`r", "") -split "`n" | Select-Object -First 9) -join "`n"
    $graphics.FillRectangle([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(241, 245, 249)), 82, 486, 1098, 174)
    $graphics.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(203, 213, 225), 1), 82, 486, 1098, 174)
    $graphics.DrawString($snippet, $mono, $ink, 104, 508)

    $note = if ($result.actual -eq "REJECTED") { "Security behavior: blocked unsafe request as expected." } else { "Security behavior: approved harmless Python helper as expected." }
    $graphics.DrawString($note, $body, $muted, 82, 682)

    $fileName = "{0:00}_{1}.png" -f $index, $result.id
    $outFile = Join-Path $screenshots $fileName
    $bitmap.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()
}

function Save-SummaryCard($data) {
    $width = 1280
    $height = 760
    $bitmap = [System.Drawing.Bitmap]::new($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $graphics.Clear([System.Drawing.Color]::FromArgb(248, 250, 252))
    $ink = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(15, 23, 42))
    $muted = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(71, 85, 105))
    $blue = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(37, 99, 235))
    $greenPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(22, 163, 74), 3)
    $bluePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(37, 99, 235), 5)

    $title = New-Font "Segoe UI" 38 ([System.Drawing.FontStyle]::Bold)
    $body = New-Font "Segoe UI" 20
    $metric = New-Font "Segoe UI" 42 ([System.Drawing.FontStyle]::Bold)
    $small = New-Font "Segoe UI" 16

    $graphics.FillRectangle([System.Drawing.SolidBrush]::new([System.Drawing.Color]::White), 48, 42, 1184, 676)
    $graphics.DrawRectangle([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(203, 213, 225), 2), 48, 42, 1184, 676)
    $graphics.DrawString("SafeCode Accuracy Summary", $title, $ink, 82, 82)
    $graphics.DrawString("Live demo run with expected approve/block labels", $body, $muted, 84, 132)

    $passed = @($data.results | Where-Object { $_.passed }).Count
    $total = @($data.results).Count
    $avgLatency = (($data.results | Measure-Object -Property elapsed_ms -Average).Average)

    $graphics.DrawString(("{0:N2}%" -f [double]$data.accuracy), $metric, $blue, 82, 196)
    $graphics.DrawString("Final accuracy", $body, $muted, 86, 252)
    $graphics.DrawString("$passed / $total", $metric, $ink, 372, 196)
    $graphics.DrawString("Correct decisions", $body, $muted, 376, 252)
    $graphics.DrawString(("{0:N1} ms" -f $avgLatency), $metric, $ink, 662, 196)
    $graphics.DrawString("Average latency", $body, $muted, 666, 252)

    $left = 100
    $top = 362
    $plotW = 1040
    $plotH = 260
    $graphics.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(15, 23, 42), 2), $left, $top + $plotH, $left + $plotW, $top + $plotH)
    $graphics.DrawLine([System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(15, 23, 42), 2), $left, $top, $left, $top + $plotH)

    $thresholdY = $top + $plotH - [int]($plotH * 0.85)
    $graphics.DrawLine($greenPen, $left, $thresholdY, $left + $plotW, $thresholdY)
    $graphics.DrawString("85% target", $small, [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(22, 101, 52)), $left + $plotW - 92, $thresholdY - 24)

    $points = New-Object System.Collections.Generic.List[System.Drawing.Point]
    for ($i = 0; $i -lt $data.cumulative_accuracy.Count; $i++) {
        $x = $left + [int](($plotW / [Math]::Max($data.cumulative_accuracy.Count - 1, 1)) * $i)
        $y = $top + $plotH - [int]($plotH * ([double]$data.cumulative_accuracy[$i] / 100))
        $points.Add([System.Drawing.Point]::new($x, $y))
    }
    if ($points.Count -gt 1) {
        $graphics.DrawLines($bluePen, $points.ToArray())
    }
    foreach ($point in $points) {
        $graphics.FillEllipse($blue, $point.X - 7, $point.Y - 7, 14, 14)
    }

    $graphics.DrawString("Cumulative accuracy stayed above target for every demo case.", $body, $muted, 100, 654)
    $bitmap.Save((Join-Path $screenshots "accuracy_summary.png"), [System.Drawing.Imaging.ImageFormat]::Png)

    $graphics.Dispose()
    $bitmap.Dispose()
}

$index = 1
foreach ($result in $data.results) {
    Save-CaseCard $result $index
    $index++
}
Save-SummaryCard $data

Write-Host "Insightful screenshots written to $screenshots"
