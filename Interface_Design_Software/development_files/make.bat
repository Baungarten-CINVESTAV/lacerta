@echo off
setlocal

set APP_NAME=LacertaHMIDesigner
set ENTRY_POINT=gui\main.py

set TARGET=%~1
if "%TARGET%"=="" set TARGET=help

if /i "%TARGET%"=="help"         goto :help
if /i "%TARGET%"=="build"        goto :build
if /i "%TARGET%"=="build-dir"    goto :build_dir
if /i "%TARGET%"=="install-deps" goto :install_deps
if /i "%TARGET%"=="clean"        goto :clean

echo Unknown target: %TARGET%
echo Run  make.bat  for a list of available targets.
exit /b 1

:: ─────────────────────────────────────────────────────────────────────────
:help
echo.
echo ===== Lacerta-HMI Designer - build targets =====
echo.
echo   make.bat build         Single-file Windows .exe  (dist\%APP_NAME%.exe)
echo   make.bat build-dir     One-directory bundle       (dist\%APP_NAME%\)
echo   make.bat clean         Remove build\ and dist\
echo   make.bat install-deps  Install Python packages + PyInstaller
echo.
echo   The RISC-V toolchain is NOT bundled.
echo   Set its path at runtime: Settings ^> Set Tool Paths
echo.
goto :eof

:: ─────────────────────────────────────────────────────────────────────────
:build
set BUILD_OUT=%TEMP%\lacerta_build
pyinstaller --onefile --windowed ^
    --noconfirm ^
    --name "%APP_NAME%" ^
    --distpath "%BUILD_OUT%\dist" ^
    --workpath "%BUILD_OUT%\build" ^
    --add-data "tools\masks;tools/masks" ^
    --add-data "tools\scripts\python;tools/scripts/python" ^
    --hidden-import PIL ^
    --hidden-import serial ^
    --hidden-import serial.tools.list_ports ^
    --hidden-import numpy ^
    %ENTRY_POINT%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
copy /y "%BUILD_OUT%\dist\%APP_NAME%.exe" "dist\%APP_NAME%.exe"
echo.
echo ^>^>^> Built: dist\%APP_NAME%.exe
echo     Copy scenes\ and output\ next to the exe before running,
echo     or let the application create them on first use.
echo.
goto :eof

:: ─────────────────────────────────────────────────────────────────────────
:build_dir
set BUILD_OUT=%TEMP%\lacerta_build
pyinstaller --onedir --windowed ^
    --noconfirm ^
    --name "%APP_NAME%" ^
    --distpath "%BUILD_OUT%\dist" ^
    --workpath "%BUILD_OUT%\build" ^
    --add-data "tools\masks;tools/masks" ^
    --add-data "tools\scripts\python;tools/scripts/python" ^
    --hidden-import PIL ^
    --hidden-import serial ^
    --hidden-import serial.tools.list_ports ^
    --hidden-import numpy ^
    %ENTRY_POINT%
if %ERRORLEVEL% NEQ 0 exit /b %ERRORLEVEL%
if not exist dist mkdir dist
xcopy /e /i /y "%BUILD_OUT%\dist\%APP_NAME%" "dist\%APP_NAME%"
echo.
echo ^>^>^> Built: dist\%APP_NAME%\
echo.
goto :eof

:: ─────────────────────────────────────────────────────────────────────────
:install_deps
pip install PySide6 Pillow pyserial numpy pyinstaller
goto :eof

:: ─────────────────────────────────────────────────────────────────────────
:clean
if exist dist        rmdir /s /q dist
if exist "%APP_NAME%.spec" del /q "%APP_NAME%.spec"
if exist "%TEMP%\lacerta_build" rmdir /s /q "%TEMP%\lacerta_build"
echo Cleaned dist\, %APP_NAME%.spec, and temp build cache
goto :eof
