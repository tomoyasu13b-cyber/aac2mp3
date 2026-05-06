@echo off
setlocal enabledelayedexpansion

:: ========== 設定 ==========
set MAX_PARALLEL=4
:: ==========================

:: 引数チェック
if "%~1"=="" (
    echo フォルダを引数に指定してください
    exit /b
)

:: 元フォルダを絶対パスに変換
pushd "%~1"
set "src_dir=%CD%"
popd

:: ffmpegが存在するか確認
where ffmpeg >nul 2>nul
if errorlevel 1 (
    echo [エラー] ffmpegが見つかりません。パスを通すか同じフォルダに配置してください。
    exit /b
)

:: 日付と時刻取得
for /f "tokens=2 delims==" %%I in ('"wmic os get localdatetime /value"') do set datetime=%%I
set today=%datetime:~0,8%
set now=%datetime:~8,6%

:: エラーログファイル名
set "error_log=error_%today%%now%.txt"
set "error_log_path=%~dp0%error_log%"

:: 元フォルダ名と親パスを取得
for %%f in ("%src_dir%") do (
    set "parent_dir=%%~dpf"
    set "folder_name=%%~nxf"
)

:: 新しい出力フォルダ名（例：Videos_20250429）
set "dst_root=%parent_dir%%folder_name%_%today%"

:: 出力先フォルダ作成
mkdir "%dst_root%" 2>nul

:: PowerShell スクリプトを実行
set "ps_script=%~dp0convert_parallel.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps_script%" -SourceDir "%src_dir%" -DestDir "%dst_root%" -ErrorLog "%error_log_path%" -MaxParallel %MAX_PARALLEL%

echo.
if exist "%error_log_path%" (
    echo エラーログ: %error_log_path%
)
