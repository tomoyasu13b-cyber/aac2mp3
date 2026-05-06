param(
    [string]$SourceDir,
    [string]$DestDir,
    [string]$ErrorLog,
    [int]$MaxParallel = 4
)

Write-Host "変換開始..."
Write-Host "元フォルダ: $SourceDir"
Write-Host "出力先フォルダ: $DestDir"
Write-Host ""

$jobs = @()
$fileCount = 0

# ファイルを列挙
$files = @(Get-ChildItem -Path $SourceDir -Filter "*.mp4" -Recurse -ErrorAction SilentlyContinue)
$fileCount = $files.Count

Write-Host "検出されたファイル数: $fileCount"
Write-Host ""

foreach ($file in $files) {
    $inFile = $file.FullName
    $relPath = $inFile.Substring($SourceDir.Length).TrimStart('\')
    $outFile = Join-Path $DestDir ($relPath -replace '\.mp4$|\.MP4$', '.mp3')
    $outDir = Split-Path $outFile
    
    if (!(Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }
    
    # 同時実行数をチェック
    while (($jobs | Where-Object { $_.State -eq 'Running' }).Count -ge $MaxParallel) {
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "[Converting] $($file.Name)"
    
    $job = Start-Job -ScriptBlock {
        param($in, $out, $log)
        ffmpeg -y -i "$in" -vn -c:a libmp3lame -b:a 256k -map_metadata 0 -id3v2_version 3 "$out" >> $log 2>&1
    } -ArgumentList $inFile, $outFile, $ErrorLog
    
    $jobs += $job
}

Write-Host ""
Write-Host "全ての変換プロセスの完了を待機中..."
$jobs | Wait-Job | Out-Null
Write-Host "Completed!"

if ((Test-Path $ErrorLog -ErrorAction SilentlyContinue) -and ((Get-Item $ErrorLog).Length -gt 0)) {
    Write-Host "Error log: $ErrorLog"
}
