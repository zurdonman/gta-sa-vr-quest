@echo off
setlocal EnableExtensions

title GTA San Andreas VR - University Monolithic Alpha v5
set "PROJECT=%~dp0"
set "MASTER=%PROJECT%tools\build-and-install.ps1"

if not exist "%MASTER%" (
  echo ERROR: Missing source-kit build script:
  echo   %MASTER%
  exit /b 1
)

set "GAME=%~1"
set "AUDIO=%~2"
if not defined GAME set /p "GAME=Path to your monolithic GTA SA 2.11.311 APK: "
if not defined AUDIO set /p "AUDIO=Path to the supported audio .7z or extracted audio folder: "

if not exist "%GAME%" (
  echo ERROR: Game APK not found: %GAME%
  exit /b 1
)
if not exist "%AUDIO%" (
  echo ERROR: Audio source not found: %AUDIO%
  exit /b 1
)

echo.
echo Building Alpha v5 from the supplied personal monolithic APK...
echo The APK and audio remain local inputs and are not redistributed.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%MASTER%" ^
  -GamePackage "%GAME%" ^
  -AudioSource "%AUDIO%" ^
  -AllowUnofficialSource %3
set "RESULT=%ERRORLEVEL%"

echo.
if "%RESULT%"=="0" (
  echo SUCCESS: Alpha v5 was built and installed or staged by the PowerShell master.
  echo Build outputs are under C:\SAVRBuild\runs.
) else (
  echo FAILED: See the diagnostic output and C:\SAVRBuild\logs.
)
pause
exit /b %RESULT%