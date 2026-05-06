@echo off
setlocal enabledelayedexpansion

:: ========== 設定 ==========
set DEBUG=1
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

:: src_dir の末尾に \ を付与（なければ）
if not "%src_dir:~-1%"=="\" set "src_dir=%src_dir%\"

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
for %%f in ("%src_dir:~0,-1%") do (
    set "parent_dir=%%~dpf"
    set "folder_name=%%~nxf"
)

:: 新しい出力フォルダ名（例：Videos_20250429）
set "dst_root=%parent_dir%%folder_name%_%today%"

:: 出力先フォルダ作成
mkdir "%dst_root%" 2>nul

echo 変換開始...
echo 元フォルダ: %src_dir%
echo 出力先フォルダ: %dst_root%

:: mp4ファイルを再帰的に探して変換
for /r "%src_dir%" %%F in (*.mp4) do (
    set "full_input=%%F"

    :: 相対パスを作成
    set "relpath=%%F"
    set "relpath=!relpath:%src_dir%=!"

    :: 先頭に\が残ったら削除
    if "!relpath:~0,1!"=="\" set "relpath=!relpath:~1!"

    :: 拡張子をmp3に変更
    set "relpath_mp3=!relpath:.mp4=.mp3!"
    set "relpath_mp3=!relpath_mp3:.MP4=.mp3!"

    :: 出力ファイルの絶対パス作成
    set "full_output=%dst_root%\!relpath_mp3!"

    :: 出力先ディレクトリが無ければ作成
    for %%P in ("!full_output!") do (
        if not exist "%%~dpP" mkdir "%%~dpP"
    )

    :: デバッグ情報表示
    if "%DEBUG%"=="1" (
        echo.
        echo [DEBUG] full_input = !full_input!
        echo [DEBUG] src_dir    = %src_dir%
        echo [DEBUG] relpath    = !relpath!
        echo [DEBUG] relpath_mp3= !relpath_mp3!
        echo [DEBUG] full_output= !full_output!
    )

    :: 実行コマンド表示
    echo [CMD] ffmpeg -y -i "!full_input!" -vn -b:a 256k "!full_output!"

    :: 変換実行（出力表示あり）
    ffmpeg -y -i "!full_input!" -vn -b:a 256k "!full_output!"
    
    :: エラーハンドリング
    if errorlevel 1 (
        echo 変換失敗: !full_input! >> "%error_log_path%"
    )
)

echo.
echo 完了しました！
if exist "%error_log_path%" (
    echo エラーが発生しました。エラーログ: %error_log_path%
)
pause
