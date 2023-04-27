REM Created in 2021 by George King
@ECHO OFF
TITLE Windows Setup Launcher
CLS

REM Revert registry for next boot
REG ADD "HKLM\SYSTEM\Setup" /v "CmdLine" /t REG_SZ /d "%WinDir%\system32\oobe\windeploy.exe" /f >nul

REM Run original setup
start /wait "WinDeploy" "%WinDir%\system32\oobe\windeploy.exe"


REM OEM Branding and activation
if exist "%WinDir%\setup\scripts\OEM.cmd" start /wait "MRP" %WinDir%\system32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WinDir%\setup\scripts\OEM.cmd
rem if exist "%WinDir%\setup\scripts\OEM.cmd" call "%WinDir%\setup\scripts\OEM.cmd"

REM Add RunOnceEx 
if exist "%WinDir%\setup\scripts\RunOnceEx.cmd" call "%WinDir%\setup\scripts\RunOnceEx.cmd"


REM SDI Execution
IF EXIST "%WINDIR%\SysWOW64" (
	SET ARCH=x64
) ElSE (
	SET ARCH=x86
)


FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.esd SET DRIVE=%%I:
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.wim SET DRIVE=%%I:
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.swm SET DRIVE=%%I:


if not exist "%WinDir%\Logs" md "%WinDir%\Logs" >nul


REM Run Snappy Driver Installer if exist DriverPacks on setup media
set /a DriverPacksCount=0
for /f "delims=" %%I in ('dir /b /os "%DRIVE%\driverpacks\*.7z" 2^>nul') do set /a DriverPacksCount+=1

if %DriverPacksCount% GEQ 1 (
	if exist "%DRIVE%\support\SDI\Launch.cmd" (
		call "%DRIVE%\support\SDI\Launch.cmd"
	)
)

exit