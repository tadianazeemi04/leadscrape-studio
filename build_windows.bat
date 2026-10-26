@echo off
echo ========================================================
echo   Building LeadScrape Studio for Windows (Release)
echo ========================================================
echo.

call flutter config --enable-windows-desktop
echo [1/3] Getting dependencies...
call flutter pub get

echo.
echo [2/3] Compiling Windows Executable...
call flutter build windows --release

echo.
echo [3/3] Checking for Inno Setup compiler...
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    echo Building single-file installer: dist\LeadScrapeStudio_Setup.exe...
    if not exist dist mkdir dist
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" windows_installer.iss
    echo Installer built successfully in dist\LeadScrapeStudio_Setup.exe!
) else (
    echo To create a single Setup.exe installer, install Inno Setup 6.
    echo Otherwise, your release folder is ready at:
    echo build\windows\x64\runner\Release\
)

echo.
pause
