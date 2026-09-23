@echo off
setlocal EnableExtensions

set "APK=%~1"
if not defined APK set "APK=C:\SAVRBuild\runs\latest\out\base.apk"
if not exist "%APK%" (
  echo ERROR: APK not found: %APK%
  exit /b 1
)

set "SDK=C:\SAVRBuild\.android-sdk"
set "BUILD_TOOLS=%SDK%\build-tools\35.0.0"
set "JAVA_HOME=C:\SAVRBuild\.tools\temurin-jdk-21.0.11+10"
set "PATH=%JAVA_HOME%\bin;%PATH%"

if not exist "%BUILD_TOOLS%\zipalign.exe" (
  echo ERROR: Missing zipalign: %BUILD_TOOLS%\zipalign.exe
  exit /b 1
)
if not exist "%BUILD_TOOLS%\apksigner.bat" (
  echo ERROR: Missing apksigner: %BUILD_TOOLS%\apksigner.bat
  exit /b 1
)

echo Verifying: %APK%
"%BUILD_TOOLS%\zipalign.exe" -c -P 16 4 "%APK%"
if errorlevel 1 exit /b %errorlevel%

call "%BUILD_TOOLS%\apksigner.bat" verify --verbose "%APK%"
if errorlevel 1 exit /b %errorlevel%

echo SUCCESS: alignment and Android signature verification passed.
exit /b 0