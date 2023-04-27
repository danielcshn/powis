REM Created in 2021 by George King
@echo off
title POWIS - Powerful Windows Setup
cls

setlocal EnableExtensions EnableDelayedExpansion

call :ReadINI WINRE WINRE
call :ReadINI BUILDISO BUILDISO
call :ReadINI ISOLABEL ISOLABEL
call :ReadINI ISONAME ISONAME
call :ReadINI SKIPEULAKEY SKIPEULAKEY
call :ReadINI UNATTENDEDTYPE UNATTENDEDTYPE
call :ReadINI UNATTENDEDFILE UNATTENDEDFILE
call :ReadINI ICONPATCH ICONPATCH
call :ReadINI INSTALLRECOMPRESS INSTALLRECOMPRESS
call :ReadINI INSTALLFORMAT INSTALLFORMAT
call :ReadINI ESDSUPPORT ESDSUPPORT


call :ReadINI UPDATES UPDATES
call :ReadINI DYNAMICDRIVERS DYNAMICDRIVERS
call :ReadINI DRIVERPACKS DRIVERPACKS
call :ReadINI THEMES THEMES
call :ReadINI WALLPAPERS WALLPAPERS
call :ReadINI OFFICE OFFICE
call :ReadINI UPDATES UPDATES
call :ReadINI SETUPS SETUPS
call :ReadINI UNATTENDEDS UNATTENDEDS


if "%~1" == "/?" (
	echo.
	echo Welcome in POWIS.cmd help
	echo.
	echo This script is designed to add new features for Windows Vista, 7, 8, 8.1, 10 setup process 
	echo You can enjoy dynamic drivers folder, Multi-Unattended selector, DriverPacks support, RunOnceEx
	echo See documentation for detailed informations
	echo.
	echo.
	echo Usage: 
	echo     POWIS.cmd PathToExtractedISO
	echo     POWIS.cmd PathToISO
	echo     POWIS.cmd PathToBootableUSB
	echo.
	echo Example:
	echo     POWIS.cmd "D:\Win10"
	echo     POWIS.cmd "D:\Win10_20H2_v2_x64.iso"
	echo     POWIS.cmd "G:"
	echo.
	echo.
	echo This tool can ESD support to Windows Vista and 7
	echo Windows Vista require Windows 8.0 for setup engine upgrade
	echo Windows 7 require Windows 8.0 and newer for setup engine upgrade
	echo.
	echo.
	echo Usage: 
	echo     POWIS.cmd PathToExtractedISO PathToExtractedISO
	echo     POWIS.cmd PathToISO PathToISO
	echo.
	echo Example:
	echo     POWIS.cmd "D:\WinVistaSP2" "D:\Win8"
	echo     POWIS.cmd "D:\WinVistaSP2.iso" "D:\Win8.iso"
	echo.
	goto :EOF

)



REM Set host architecture
if exist "%WinDir%\SysWOW64" (
	set ARCH=amd64
) else (
	set ARCH=x86
)

REM Custom DISM
set "Path=%~dp0apps\DISM\%ARCH%;%Path%"


if "%~1" == "" (
 	echo.
	set /p "IMAGE=Drag and drop ISO or extracted Windows Setup location here: "
) else (
 	set "IMAGE=%~1"
)


if "%ESDSUPPORT%" == "Yes" (
	if "%~2" == "" (
		echo.
		set /p "ENGINEIMAGE=Drag and drop ISO or extracted Windows Setup location here: "
	) else (
		"set ENGINEIMAGE=%~2"
	)
)


echo.

REM Get rid of " in file names or path
set IMAGE=%IMAGE:"=%
if defined ENGINEIMAGE set ENGINEIMAGE=%ENGINEIMAGE:"=%


REM Get rid of backslash at the end \
rem if "%IMAGE:~-1,1%" == "\" set IMAGE=%IMAGE:~0,-1%
rem if defined ENGINEIMAGE if "%ENGINEIMAGE:~-1,1%" == "\" set ENGINEIMAGE=%ENGINEIMAGE:~0,-1%


if exist "%~dp0_output" rd /q /s "%~dp0_output"
if exist "%~dp0_engine" rd /q /s "%~dp0_engine"


set /a STEP=0

set ISOCHECK=%IMAGE:~-4,4%

if /i "%ISOCHECK%" == ".iso" (
	
	set /a STEP=1


	echo  [!STEP!] Extracting ISO
	
	"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%" -o"%~dp0_output" -y >nul

)


if defined ENGINEIMAGE (
	set ISOCHECK=%ENGINEIMAGE:~-4,4%
	
	if /i "%ISOCHECK%" == ".iso" (
		
		set /a STEP+=1

		echo  [!STEP!] Extracting setup engine ISO
		
		"%~dp0apps\7z\%ARCH%\7z.exe" x "%ENGINEIMAGE%" -o"%~dp0_engine" -y >nul
	)
)


if exist "%~dp0_output" set "IMAGE=%~dp0_output"
if exist "%~dp0_engine" set "ENGINEIMAGE=%~dp0_engine"



REM Add deployment scripts
if not exist "%IMAGE%\sources\$OEM$\$$\setup\scripts" md "%IMAGE%\sources\$OEM$\$$\setup\scripts"

echo This file is used during setup to tag target for drivers installing > "%IMAGE%\sources\$OEM$\$$\DriversTarget"

copy /y "%~dp0deployment\RunOnceEx.cmd" "%IMAGE%\sources\$OEM$\$$\setup\scripts\RunOnceEx.cmd" >nul
copy /y "%~dp0deployment\RunOnceEx.inf" "%IMAGE%\sources\$OEM$\$$\setup\scripts\RunOnceEx.inf" >nul
copy /y "%~dp0deployment\CleanDriverStore.cmd" "%IMAGE%\sources\$OEM$\$$\setup\scripts\CleanDriverStore.cmd" >nul
copy /y "%~dp0deployment\WinDeploy.cmd" "%IMAGE%\sources\$OEM$\$$\setup\scripts\WinDeploy.cmd" >nul
copy /y "%~dp0deployment\Watcher.cmd" "%IMAGE%\sources\$OEM$\$$\setup\scripts\Watcher.cmd" >nul
copy /y "%~dp0deployment\invisible.vbs" "%IMAGE%\sources\$OEM$\$$\setup\scripts\invisible.vbs" >nul

if not exist "%IMAGE%\support" md "%IMAGE%\support"
copy /y "%~dp0Activate.cmd" "%IMAGE%\support\Activate.cmd" >nul


echo [Settings]>"%IMAGE%\settings.ini"
echo ; Auto - Automatically load setup with defined UnattendedFile>>"%IMAGE%\settings.ini"
echo ; Select - User will be prompted for selection if there exist more .xml files>>"%IMAGE%\settings.ini"
echo UnattendedType=%UNATTENDEDTYPE%>>"%IMAGE%\settings.ini"
echo UnattendedFile=%UNATTENDEDFILE%>>"%IMAGE%\settings.ini"






REM Multi-OEM/Retail Project {MRP}
copy /y "%~dp0plugins\oem\*.*" "%IMAGE%\sources\$OEM$\$$\setup\scripts\" >nul



if exist "%IMAGE%\sources\install.swm" set IFORMAT=swm
if exist "%IMAGE%\sources\install.wim" set IFORMAT=wim
if exist "%IMAGE%\sources\install.esd" set IFORMAT=esd

REM Detect default language
for /f "tokens=1" %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\install.%IFORMAT%" /index:1 ^| find /i "Default"') do set SLLP=%%i

REM Detect setup architecture
for /f "tokens=2 delims=: " %%i in ('dism /english /get-wiminfo /wimfile:"%IMAGE%\sources\install.%IFORMAT%" /index:1 ^| find /i "Architecture"') do set IMGARCH=%%i

REM Detect setup version
for /f "tokens=3 delims= " %%i in ('""%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" info "%IMAGE%\sources\install.%IFORMAT%" 1 | findstr /i /C:"Major""') do set IMGMAVER=%%i
for /f "tokens=3 delims= " %%i in ('""%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" info "%IMAGE%\sources\install.%IFORMAT%" 1 | findstr /i /C:"Minor""') do set IMGMIVER=%%i


REM Detect images
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\install.%IFORMAT%" ^| findstr "Index"') do set IIMGCNT=%%i

if %IIMGCNT% GTR 1 (
	set "EPATH=%IIMGCNT%\Windows
) else (
	set "EPATH=Windows

)


if "%IMGMAVER%.%IMGMIVER%" == "6.0" (
	set "IMGVER=Vista"
) else if "%IMGMAVER%.%IMGMIVER%" == "6.1" (
	set "IMGVER=7"
) else if "%IMGMAVER%.%IMGMIVER%" == "6.2" (
	set "IMGVER=8.0"
) else if "%IMGMAVER%.%IMGMIVER%" == "6.3" (
	set "IMGVER=8.1"
) else if "%IMGMAVER%" == "10" (
	set "IMGVER=10"
) else (
	REM Unmapped Windows build
	set "IMGVER=%IMGMAVER%.%IMGMIVER%"
)



REM RunOnceEx check
REM if not present in image, add it from repository

"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\System32\iernonce.dll" -aos -o"%~dp0temp" >nul
move /y "%~dp0temp\%EPATH%\System32\iernonce.dll" "%~dp0temp\iernonce.dll" >nul 2>nul

rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 /Windows/System32/iernonce.dll --dest-dir="%~dp0temp" --nullglob >nul 2>nul


if not exist "%~dp0temp\iernonce.dll" (

	if not exist "%IMAGE%\sources\$OEM$\$$\system32" md "%IMAGE%\sources\$OEM$\$$\system32"
	copy /y "%~dp0apps\RunOnceEx\%IMGVER%\%IMGARCH%\iernonce.dll" "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" >nul
	

	if not exist "%~dp0apps\RunOnceEx\%IMGVER%\%IMGARCH%\%SLLP%" (
	
		if not exist "%IMAGE%\sources\$OEM$\$$\system32\en-US" md "%IMAGE%\sources\$OEM$\$$\system32\en-US"
		copy /y "%~dp0apps\RunOnceEx\%IMGVER%\%IMGARCH%\en-US\iernonce.dll.mui" "%IMAGE%\sources\$OEM$\$$\system32\en-US\iernonce.dll.mui" >nul		
		
	) else (
	
		if not exist "%IMAGE%\sources\$OEM$\$$\system32\%SLLP%" md "%IMAGE%\sources\$OEM$\$$\system32\%SLLP%"
		copy /y "%~dp0apps\RunOnceEx\%IMGVER%\%IMGARCH%\%SLLP%\iernonce.dll.mui" "%IMAGE%\sources\$OEM$\$$\system32\%SLLP%\iernonce.dll.mui" >nul
		
	)
)

"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\System32\IEAdvpack.dll" -aos -o"%~dp0temp" >nul
move /y "%~dp0temp\%EPATH%\System32\IEAdvpack.dll" "%~dp0temp\IEAdvpack.dll" >nul 2>nul



rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 /Windows/System32/IEAdvpack.dll --dest-dir="%~dp0temp" --nullglob >nul 2>nul

if not exist "%~dp0temp\IEAdvpack.dll" (
	if exist "%~dp0apps\RunOnceEx\%IMGVER%\%IMGARCH%\IEAdvpack.dll" (
		if not exist "%IMAGE%\sources\$OEM$\$$\system32" md "%IMAGE%\sources\$OEM$\$$\system32"
		copy /y "%~dp0apps\RunOnceEx\%IMGVER%\%IMGARCH%\IEAdvpack.dll" "%IMAGE%\sources\$OEM$\$$\system32\IEAdvpack.dll" >nul 2>nul
	)

)


if exist "%~dp0temp"  rd /q /s "%~dp0temp" >nul





if "%SKIPEULAKEY%" == "Yes" (
	set /a STEP+=1
	echo  [!STEP!] Creating autounattend.xml


	rem if exist "%IMAGE%\autounattend.xml" del /q /s "%IMAGE%\autounattend.xml" >nul
	if exist "%IMAGE%\autounattend.xml" ren "%IMAGE%\autounattend.xml" "Autounattend-Original.xml" >nul
	
	REM Skip Product Key + Eula
	echo ^<?xml version="1.0" encoding="utf-8"?^> >>"%IMAGE%\autounattend.xml"
	echo ^<unattend xmlns="urn:schemas-microsoft-com:unattend"^> >>"%IMAGE%\autounattend.xml"
	echo 	^<settings pass="windowsPE"^> >>"%IMAGE%\autounattend.xml"
	echo 		^<component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"^> >>"%IMAGE%\autounattend.xml"
	echo 			^<SystemLocale^>%SLLP%^</SystemLocale^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UILanguage^>%SLLP%^</UILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UILanguageFallback^>%SLLP%^</UILanguageFallback^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UserLocale^>%SLLP%^</UserLocale^> >>"%IMAGE%\autounattend.xml"
	echo 			^<SetupUILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 				^<UILanguage^>%SLLP%^</UILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 			^</SetupUILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 		^</component^> >>"%IMAGE%\autounattend.xml"
	echo 		^<component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"^> >>"%IMAGE%\autounattend.xml"
	echo 			^<SystemLocale^>%SLLP%^</SystemLocale^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UILanguage^>%SLLP%^</UILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UILanguageFallback^>%SLLP%^</UILanguageFallback^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UserLocale^>%SLLP%^</UserLocale^> >>"%IMAGE%\autounattend.xml"
	echo 			^<SetupUILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 				^<UILanguage^>%SLLP%^</UILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 			^</SetupUILanguage^> >>"%IMAGE%\autounattend.xml"
	echo 		^</component^> >>"%IMAGE%\autounattend.xml"
	echo 		^<component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"^> >>"%IMAGE%\autounattend.xml"
	echo 			^<Diagnostics^> >>"%IMAGE%\autounattend.xml"
	echo 				^<OptIn^>false^</OptIn^> >>"%IMAGE%\autounattend.xml"
	echo 			^</Diagnostics^> >>"%IMAGE%\autounattend.xml"
	echo 			^<DynamicUpdate^> >>"%IMAGE%\autounattend.xml"
	echo 				^<Enable^>false^</Enable^> >>"%IMAGE%\autounattend.xml"
	echo 				^<WillShowUI^>OnError^</WillShowUI^> >>"%IMAGE%\autounattend.xml"
	echo 			^</DynamicUpdate^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UserData^> >>"%IMAGE%\autounattend.xml"
	echo 				^<AcceptEula^>true^</AcceptEula^> >>"%IMAGE%\autounattend.xml"
	echo 				^<ProductKey^> >>"%IMAGE%\autounattend.xml"
	echo 					^<Key^>^</Key^> >>"%IMAGE%\autounattend.xml"
	echo 				^</ProductKey^> >>"%IMAGE%\autounattend.xml"
	echo 			^</UserData^> >>"%IMAGE%\autounattend.xml"
	echo 		^</component^> >>"%IMAGE%\autounattend.xml"
	echo 		^<component name="Microsoft-Windows-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"^> >>"%IMAGE%\autounattend.xml"
	echo 			^<Diagnostics^> >>"%IMAGE%\autounattend.xml"
	echo 				^<OptIn^>false^</OptIn^> >>"%IMAGE%\autounattend.xml"
	echo 			^</Diagnostics^> >>"%IMAGE%\autounattend.xml"
	echo 			^<DynamicUpdate^> >>"%IMAGE%\autounattend.xml"
	echo 				^<Enable^>false^</Enable^> >>"%IMAGE%\autounattend.xml"
	echo 				^<WillShowUI^>OnError^</WillShowUI^> >>"%IMAGE%\autounattend.xml"
	echo 			^</DynamicUpdate^> >>"%IMAGE%\autounattend.xml"
	echo 			^<UserData^> >>"%IMAGE%\autounattend.xml"
	echo 				^<AcceptEula^>true^</AcceptEula^> >>"%IMAGE%\autounattend.xml"
	echo 				^<ProductKey^> >>"%IMAGE%\autounattend.xml"
	echo 					^<Key^>^</Key^> >>"%IMAGE%\autounattend.xml"
	echo 				^</ProductKey^> >>"%IMAGE%\autounattend.xml"
	echo 			^</UserData^> >>"%IMAGE%\autounattend.xml"
	echo 		^</component^> >>"%IMAGE%\autounattend.xml"
	echo 	^</settings^> >>"%IMAGE%\autounattend.xml"
	echo ^</unattend^> >>"%IMAGE%\autounattend.xml"
	
)



if "%UNATTENDEDS%" == "Yes" (
	set /a STEP+=1
	echo  [!STEP!] Adding Unattended files
		
	REM Custom unattended files
	copy /y "%~dp0plugins\unattended\*.xml" "%IMAGE%\" >nul 2>nul

)



if "%DYNAMICDRIVERS%" == "Yes" (

	set /a STEP+=1
	echo  [!STEP!] Adding dynamic drivers folder

	if not exist "%IMAGE%\drivers" md "%IMAGE%\drivers" >nul
	if not exist "%IMAGE%\drivers\x86" md "%IMAGE%\drivers\x86" >nul
	if not exist "%IMAGE%\drivers\x64" md "%IMAGE%\drivers\x64" >nul
	if not exist "%IMAGE%\drivers\All" md "%IMAGE%\drivers\All" >nul

	xcopy /s /y /e "%~dp0plugins\drivers" "%IMAGE%\drivers\" >nul

	echo Place folders with x64 ^(64bit^) INF drivers here >"%IMAGE%\drivers\x64\README.txt"
	echo Place folders with x86 ^(32bit^) INF drivers here >"%IMAGE%\drivers\x86\README.txt"
	echo Place folders with architecture independent INF drivers here >"%IMAGE%\drivers\All\README.txt"	

)


if "%DRIVERPACKS%" == "Yes" (

	REM Add Snappy Driver Installer + DriverPacks

	set /a STEP+=1
	echo  [!STEP!] Adding DriverPacks support	

	if not exist "%IMAGE%\support\SDI" md "%IMAGE%\support\SDI"
	if not exist "%IMAGE%\driverpacks" md "%IMAGE%\driverpacks"

	xcopy /s /y /e "%~dp0apps\SDI" "%IMAGE%\support\SDI\" >nul
	copy /y "%~dp0plugins\driverpacks\*.*" "%IMAGE%\driverpacks" >nul 2>nul

)


if "%OFFICE%" == "Yes" (

	set /a STEP+=1
	echo  [%STEP%] Adding Office folder	

	if not exist "%IMAGE%\office" md "%IMAGE%\office"
	xcopy /s /y /e "%~dp0plugins\office" "%IMAGE%\office\" >nul

)



if "%SETUPS%" == "Yes" (

	set /a STEP+=1
	echo  [%STEP%] Adding Setup folder
	REM Copy applications installers
	if not exist "%IMAGE%\setup" md "%IMAGE%\setup"
	copy /y "%~dp0plugins\setup\*.*" "%IMAGE%\setup" >nul 2>nul

)


if "%THEMES%" == "Yes" (

	set /a STEP+=1
	echo  [%STEP%] Adding Themes	
	REM Copy additional themes
	if not exist "%IMAGE%\sources\$OEM$\$$\resources\themes" md "%IMAGE%\sources\$OEM$\$$\resources\themes"
	xcopy /s /y /e "%~dp0plugins\themes" "%IMAGE%\sources\$OEM$\$$\resources\themes\" >nul
)

if "%WALLPAPERS%" == "Yes" (

	set /a STEP+=1
	echo  [%STEP%] Adding Wallpapers
	REM Copy additional wallpapers
	if not exist "%IMAGE%\sources\$OEM$\$$\web\wallpaper" md "%IMAGE%\sources\$OEM$\$$\web\wallpaper"
	xcopy /s /y /e "%~dp0plugins\wallpapers" "%IMAGE%\sources\$OEM$\$$\web\wallpaper\" >nul

)


if "%UPDATES%" == "Yes" (

	set /a STEP+=1
	echo  [%STEP%] Adding Updates folder	

	REM Add updates support
	if not exist "%IMAGE%\updates" md "%IMAGE%\updates"

	copy /y "%~dp0plugins\updates\*.*" "%IMAGE%\updates" >nul 2>nul

	echo Place any MSU / CAB / MSP updates in this folder and they will be silently installed during setup>"%IMAGE%\updates\README.txt"
	echo.>>"%IMAGE%\updates\README.txt"
	echo Just don't forget to keep -x64 or -x86 in file name as this is how they are detected>>"%IMAGE%\updates\README.txt"

)




set /a STEP+=1
echo  [%STEP%] Adding Multi-Unattended support

REM Ability for selection Unattended files
echo [Settings]>"%IMAGE%\settings.ini"
echo ; Auto - Automatically load setup with defined UnattendedFile>>"%IMAGE%\settings.ini"
echo ; Select - User will be prompted for selection if there exist more .xml files>>"%IMAGE%\settings.ini"
echo UnattendedType=%UNATTENDEDTYPE%>>"%IMAGE%\settings.ini"
echo UnattendedFile=%UNATTENDEDFILE%>>"%IMAGE%\settings.ini"


REM Upgrades can be run directly using setup.cmd
copy "%~dp0deployment\setup.cmd" "%IMAGE%\sources\setup.cmd" >nul



set /a STEP+=1
echo  [%STEP%] Modifying bootloader


REM Modify bootloaders

if not exist "%~dp0temp" md "%~dp0temp"

if not exist "%IMAGE%\boot\%SLLP%" md "%IMAGE%\boot\%SLLP%"

"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\Boot\PCAT\%SLLP%" -aos -o"%~dp0temp" >nul
move /y "%~dp0temp\%EPATH%\Boot\PCAT\%SLLP%\*.*" "%IMAGE%\boot\%SLLP%" >nul 2>nul

rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 "Windows\Boot\PCAT\%SLLP%" --dest-dir="%IMAGE%\boot" --no-acls --no-attribute >nul


if "%IMGARCH%" == "x64" (

	if not exist "%IMAGE%\efi\boot" md "%IMAGE%\efi\boot"
	if not exist "%IMAGE%\efi\microsoft\boot" md "%IMAGE%\efi\microsoft\boot"

	if not exist "%IMAGE%\efi\boot\bootx64.efi" (
		
		"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\Boot\EFI\bootmgfw.efi" -aos -o"%~dp0temp" >nul
		move /y "%~dp0temp\%EPATH%\Boot\EFI\bootmgfw.efi" "%IMAGE%\efi\boot\bootx64.efi" >nul
		rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 "Windows\Boot\EFI\bootmgfw.efi" --dest-dir="%IMAGE%\efi\boot" --no-acls --no-attribute >nul
		rem ren "%IMAGE%\efi\boot\bootmgfw.efi" "bootx64.efi"
	)

	rem if not exist "%IMAGE%\efi\microsoft\boot\bootmgfw.efi" (
	rem	"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 "Windows\Boot\EFI\bootmgfw.efi" --dest-dir="%IMAGE%\efi\microsoft\boot" --no-acls --no-attribute >nul
	rem )

	rem if not exist "%IMAGE%\efi\microsoft\boot\bootmgr.efi" (
	rem	"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 "Windows\Boot\EFI\bootmgr.efi" --dest-dir="%IMAGE%" --no-acls --no-attribute >nul
	rem )

	if not exist "%IMAGE%\efi\microsoft\boot\memtest.efi" (
		"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\Boot\EFI\memtest.efi" -aos -o"%~dp0temp" >nul
		move /y "%~dp0temp\%EPATH%\Boot\EFI\memtest.efi" "%IMAGE%\efi\microsoft\boot\memtest.efi" >nul

		rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 "Windows\Boot\EFI\memtest.efi" --dest-dir="%IMAGE%\efi\microsoft\boot" --no-acls --no-attribute >nul
	)

	rem "%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\Boot\EFI\%SLLP%\memtest.efi.mui" -aos -o"%IMAGE%\efi\microsoft\boot\%SLLP%" >nul

	rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 "Windows\Boot\EFI\%SLLP%\memtest.efi.mui" --dest-dir="%IMAGE%\boot\%SLLP%" --no-acls --no-attribute >nul


	if not exist "%IMAGE%\efi\microsoft\boot\%SLLP%" md "%IMAGE%\efi\microsoft\boot\%SLLP%"
	
	"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\Boot\EFI\%SLLP%" -aos -o"%~dp0temp" >nul
	move /y "%~dp0temp\%EPATH%\Boot\EFI\%SLLP%\*.*" "%IMAGE%\efi\microsoft\boot\%SLLP%" >nul 2>nul
	rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" 1 "Windows\Boot\EFI\%SLLP%" --dest-dir="%IMAGE%\efi\microsoft\boot" --no-acls --no-attribute >nul

	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {bootmgr} locale "%SLLP%" >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {memdiag} locale "%SLLP%" >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {default} locale "%SLLP%" >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {default} ems off >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {default} bootmenupolicy legacy >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /timeout 30 >nul
	
	
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /create {memdiag} >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /toolsdisplayorder {memdiag} >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {memdiag} description "Windows Memory Diagnostic" >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {memdiag} locale "%SLLP%" >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {memdiag} path "\efi\microsoft\boot\memtest.efi" >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {memdiag} inherit {globalsettings} >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {memdiag} badmemoryaccess Yes >nul
	bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {memdiag} device boot >nul
	
	
	REM FIX non translated UEFI MUI files
	if not exist "%~dp0temp" md "%~dp0temp"

	
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\boot\%SLLP%\bootmgr.exe.mui" -save "%~dp0temp\langfix.res" -action extract -mask HTML, , -log NUL
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\efi\microsoft\boot\%SLLP%\bootmgr.efi.mui" -save "%IMAGE%\efi\microsoft\boot\%SLLP%\bootmgr.efi.mui" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\efi\microsoft\boot\%SLLP%\bootmgfw.efi.mui" -save "%IMAGE%\efi\microsoft\boot\%SLLP%\bootmgfw.efi.mui" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,

	
	REM Dirty bootloader translation
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%~dp0temp\langfix.res" -save "%~dp0temp\langfix.res" -action changelanguage^(1033^) , , ,
	
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\efi\boot\bootx64.efi" -save "%IMAGE%\efi\boot\bootx64.efi" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,
	rem "%~dp0apps\PEChecksum.exe" -c "%IMAGE%\efi\boot\bootx64.efi" >nul
	rem copy /y "%IMAGE%\efi\boot\bootx64.efi" "%IMAGE%\efi\microsoft\boot\bootmgfw.efi"
	
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\efi\microsoft\boot\bootmgr.efi" -save "%IMAGE%\efi\microsoft\boot\bootmgr.efi" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,
	rem "%~dp0apps\PEChecksum.exe" -c "%IMAGE%\efi\microsoft\boot\bootmgr.efi" >nul
	rem move /y "%IMAGE%\efi\microsoft\boot\bootmgr.efi" "%IMAGE%\bootmgr.efi"
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\efi\microsoft\boot\bootmgfw.efi" -save "%IMAGE%\efi\microsoft\boot\bootmgfw.efi" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,


	rem del /q /s "%~dp0temp\langfix.res" >nul
	
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\boot\%SLLP%\memtest.exe.mui" -save "%~dp0temp\langfix.res" -action extract -mask HTML, , -log NUL
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\efi\microsoft\boot\%SLLP%\memtest.efi.mui" -save "%IMAGE%\efi\microsoft\boot\%SLLP%\memtest.efi.mui" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,

	rem del /q /s "%~dp0temp\langfix.res" >nul
	rd /q /s "%~dp0temp" >nul

)



bcdedit /store "%IMAGE%\boot\bcd" /set {bootmgr} locale "%SLLP%" >nul
bcdedit /store "%IMAGE%\boot\bcd" /set {memdiag} locale "%SLLP%" >nul
bcdedit /store "%IMAGE%\boot\bcd" /set {memdiag} badmemoryaccess Yes >nul
bcdedit /store "%IMAGE%\boot\bcd" /set {default} locale "%SLLP%" >nul
bcdedit /store "%IMAGE%\boot\bcd" /set {default} ems off >nul
bcdedit /store "%IMAGE%\boot\bcd" /set {default} bootmenupolicy legacy >nul
bcdedit /store "%IMAGE%\boot\bcd" /timeout 30 >nul






set /a STEP+=1
echo  [%STEP%] Modifying setup launch in boot.wim


REM Get number of images
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\boot.wim" ^| findstr "Index"') do set IMGCNT=%%i

REM Modify setup launch method
md "%TEMP%\boot"
dism /Mount-Wim /WimFile:"%IMAGE%\sources\boot.wim" /index:%IMGCNT% /mountdir:"%TEMP%\boot" >nul


REM Localize bootloader

takeown /F "%TEMP%\boot\Windows\Boot\DVD\PCAT\bcd" /A >nul 2>nul
icacls "%TEMP%\boot\Windows\Boot\DVD\PCAT\bcd" /grant *S-1-5-32-544:F >nul 2>nul

bcdedit /store "%TEMP%\boot\Windows\Boot\DVD\PCAT\bcd" /set {bootmgr} locale "%SLLP%" >nul
bcdedit /store "%TEMP%\boot\Windows\Boot\DVD\PCAT\bcd" /set {default} locale "%SLLP%" >nul

del /q /s /a "%TEMP%\boot\Windows\Boot\DVD\PCAT\bcd.log*" >nul 2>nul



if exist "%TEMP%\boot\Windows\Boot\DVD\EFI\bcd" (

	takeown /F "%TEMP%\boot\Windows\Boot\DVD\EFI\bcd" /A >nul 2>nul
	icacls "%TEMP%\boot\Windows\Boot\DVD\EFI\bcd" /grant *S-1-5-32-544:F >nul 2>nul
	
	bcdedit /store "%TEMP%\boot\Windows\Boot\DVD\EFI\bcd" /set {bootmgr} locale "%SLLP%" >nul
	bcdedit /store "%TEMP%\boot\Windows\Boot\DVD\EFI\bcd" /set {default} locale "%SLLP%" >nul


	del /q /s /a "%TEMP%\boot\Windows\Boot\DVD\EFI\bcd.log*" >nul 2>nul



	REM REM FIX non translated UEFI MUI files
	if not exist "%~dp0temp" md "%~dp0temp"

	
	REM Dirty bootloader translation
	REM "%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\Boot\EFI\%SLLP%\bootmgfw.efi.mui" -save "%~dp0temp\langfix.res" -action extract -mask HTML, , -log NUL
	REM "%~dp0apps\ResHack\ResourceHacker.exe" -open "%~dp0temp\langfix.res" -save "%~dp0temp\langfix.res" -action changelanguage^(1033^) , , , -log NUL
	
	if "1" == "2" ( 
		REM HTML
		FOR /f "delims=" %%I IN ('dir /s /b /o:n "%IMAGE%" ^| findstr /e "bootmgfw.efi bootmgr.efi"') DO (
			takeown /F "%%I" >nul
			icacls "%%I" /grant *S-1-5-32-544:F >nul
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%%I" -save "%%I" -action addoverwrite -resource "%~dp0temp\langfix.res" , , , -log NUL
			echo %%I
		)

		
		del /q /s "%~dp0temp\langfix.res" >nul


		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\Boot\EFI\%SLLP%\bootmgfw.efi.mui" -save "%~dp0temp\langfix.res" -action extract -mask MESSAGETABLE, , -log NUL
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%~dp0temp\langfix.res" -save "%~dp0temp\langfix.res" -action changelanguage^(1033^) , , , -log NUL
		
		REM MESSAGETABLE
		FOR /f "delims=" %%I IN ('dir /s /b /o:n "%IMAGE%" ^| findstr /e "bootmgfw.efi bootmgr.efi"') DO (
			takeown /F "%%I" >nul
			icacls "%%I" /grant *S-1-5-32-544:F >nul
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%%I" -save "%%I" -action addoverwrite -resource "%~dp0temp\langfix.res" , , , -log NUL
			echo %%I
		)

		
		del /q /s "%~dp0temp\langfix.res" >nul
	)
	rem pause
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\Boot\EFI\bootmgr.efi" -save "%TEMP%\boot\Windows\Boot\EFI\bootmgr.efi" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,
	rem "%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\Boot\EFI\bootmgfw.efi" -save "%TEMP%\boot\Windows\Boot\EFI\bootmgfw.efi" -action addoverwrite -resource "%~dp0temp\langfix.res" , , ,
	rem del /q /s "%~dp0temp\langfix.res" >nul


	rem rd /q /s "%TEMP%\boot\Windows\System32\Boot\en-US"
	
	REM In rare cases are EFI MUI files non translated
	if exist "%TEMP%\boot\Windows\System32\Boot\%SLLP%\winload.exe.mui" (
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\Boot\%SLLP%\winload.exe.mui" -save "%~dp0temp\langfix.res" -action extract -mask HTML, , -log NUL
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\Boot\%SLLP%\winload.efi.mui" -save "%TEMP%\boot\Windows\System32\Boot\%SLLP%\winload.efi.mui" -action addoverwrite -resource "%~dp0temp\langfix.res" , , , -log NUL
		del /q /s "%~dp0temp\langfix.res" >nul

		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\Boot\%SLLP%\winresume.exe.mui" -save "%~dp0temp\langfix.res" -action extract -mask HTML, , -log NUL
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\Boot\%SLLP%\winresume.efi.mui" -save "%TEMP%\boot\Windows\System32\Boot\%SLLP%\winresume.efi.mui" -action addoverwrite -resource "%~dp0temp\langfix.res" , , , -log NUL
		del /q /s "%~dp0temp\langfix.res" >nul
		
	)
	
	if exist "%TEMP%\boot\Windows\System32\%SLLP%\winload.exe.mui" (
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\%SLLP%\winload.exe.mui" -save "%~dp0temp\langfix.res" -action extract -mask HTML, , -log NUL
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\%SLLP%\winload.efi.mui" -save "%TEMP%\boot\Windows\System32\%SLLP%\winload.efi.mui" -action addoverwrite -resource "%~dp0temp\langfix.res" , , , -log NUL
		del /q /s "%~dp0temp\langfix.res" >nul
		
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\%SLLP%\winresume.exe.mui" -save "%~dp0temp\langfix.res" -action extract -mask HTML, , -log NUL
		"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\Windows\System32\%SLLP%\winresume.efi.mui" -save "%TEMP%\boot\Windows\System32\%SLLP%\winresume.efi.mui" -action addoverwrite -resource "%~dp0temp\langfix.res" , , , -log NUL
		del /q /s "%~dp0temp\langfix.res" >nul	
	)
	
	rd /q /s "%~dp0temp" >nul

)








REM [LaunchApps]
REM %%SYSTEMDRIVE%%\Windows\system32\wscript.exe, "//nologo %%SYSTEMDRIVE%%\Windows\system32\invisible.vbs %%SYSTEMDRIVE%%\sources\setup.cmd"

echo [LaunchApps]> "%TEMP%\boot\Windows\System32\Winpeshl.ini"
echo %%SYSTEMDRIVE%%\sources\setup.cmd>> "%TEMP%\boot\Windows\System32\Winpeshl.ini"


REM Set Numlock to ON in WinPE
rem reg load HKLM\TempDefault "%TEMP%\boot\Users\Default\ntuser.dat" >nul
reg load HKLM\TempDefault "%TEMP%\boot\Windows\system32\config\DEFAULT" >nul
reg add "HKLM\TempDefault\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul
REM reg add "HKLM\TempDefault\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2147483650" /f >nul
reg unload HKLM\TempDefault >nul 




REM ESD SUPPORT
if "%ESDSUPPORT%" == "Yes" (

	if exist "%ENGINEIMAGE%\sources\boot.wim" (
	
		set /a STEP+=1

		echo  [!STEP!] Upgrading setup engine

		REM Get number of images
		for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%ENGINEIMAGE%\sources\boot.wim" ^| findstr "Index"') do set IMGCNT=%%i
		
		md "%TEMP%\bootengine"
		dism /Mount-Wim /WimFile:"%ENGINEIMAGE%\sources\boot.wim" /index:!IMGCNT! /mountdir:"%TEMP%\bootengine" >nul

		takeown /F "%TEMP%\boot\sources\*.*" >nul 2>nul
		icacls "%TEMP%\boot\sources\*.*" /grant *S-1-5-32-544:F >nul 2>nul
		rd /q /s "%TEMP%\boot\sources" >nul

		xcopy /s /y "%TEMP%\bootengine\sources" "%TEMP%\boot\sources\" >nul

		takeown /F "%TEMP%\boot\sources\recovery\*.*" >nul 2>nul
		icacls "%TEMP%\boot\sources\recovery\*.*" /grant *S-1-5-32-544:F >nul 2>nul
		rd /q /s "%TEMP%\boot\sources\recovery" >nul

		copy /y "%TEMP%\bootengine\setup.exe" "%TEMP%\boot\setup.exe" >nul


		REM AutoUnattented support
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-com-l1-1-0.dll" "%TEMP%\boot\sources\api-ms-win-core-com-l1-1-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\API-MS-Win-Core-Heap-Obsolete-L1-1-0.dll" "%TEMP%\boot\sources\API-MS-Win-Core-Heap-Obsolete-L1-1-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-kernel32-legacy-l1-1-0.dll" "%TEMP%\boot\sources\api-ms-win-core-kernel32-legacy-l1-1-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-localization-l1-2-0.dll" "%TEMP%\boot\sources\api-ms-win-core-localization-l1-2-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-privateprofile-l1-1-0.dll" "%TEMP%\boot\sources\api-ms-win-core-privateprofile-l1-1-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-registry-l1-1-0.dll" "%TEMP%\boot\sources\api-ms-win-core-registry-l1-1-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-stringansi-l1-1-0.dll" "%TEMP%\boot\sources\api-ms-win-core-stringansi-l1-1-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-stringloader-l1-1-1.dll" "%TEMP%\boot\sources\api-ms-win-core-stringloader-l1-1-1.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\API-MS-Win-core-string-obsolete-l1-1-0.dll" "%TEMP%\boot\sources\API-MS-Win-core-string-obsolete-l1-1-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\api-ms-win-core-synch-l1-2-0.dll" "%TEMP%\boot\sources\api-ms-win-core-synch-l1-2-0.dll" >nul
		copy /y "%TEMP%\bootengine\Windows\System32\downlevel\API-MS-Win-Security-Lsalookup-L2-1-0.dll" "%TEMP%\boot\sources\API-MS-Win-Security-Lsalookup-L2-1-0.dll" >nul

		dism /unmount-wim /MountDir:"%TEMP%\bootengine" /discard >nul
		rd /q /s "%TEMP%\bootengine"
		
		
		if exist "%TEMP%\boot\Windows\servicing\Version\6.0.*" (

			REM Apply original setup design patch
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\ARUNIMG.dll" -save "%TEMP%\boot\sources\ARUNIMG.dll" -action addoverwrite -resource "%~dp0resources\Vista\ARUNIMG.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\arunres.dll" -save "%TEMP%\boot\sources\arunres.dll" -action addoverwrite -resource "%~dp0resources\Vista\arunres.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\spwizimg.dll" -save "%TEMP%\boot\sources\spwizimg.dll" -action addoverwrite -resource "%~dp0resources\Vista\spwizimg.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\spwizres.dll" -save "%TEMP%\boot\sources\spwizres.dll" -action addoverwrite -resource "%~dp0resources\Vista\spwizres.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\w32uiimg.dll" -save "%TEMP%\boot\sources\w32uiimg.dll" -action addoverwrite -resource "%~dp0resources\Vista\w32uiimg.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\w32uires.dll" -save "%TEMP%\boot\sources\w32uires.dll" -action addoverwrite -resource "%~dp0resources\Vista\w32uires.res" , , , -log NUL
			
			copy /y "%~dp0resources\Vista\background.bmp" "%TEMP%\boot\sources\background.bmp" >nul
			copy /y "%~dp0resources\Vista\background.bmp" "%TEMP%\boot\Windows\system32\winpe.bmp" >nul
			
			REM Without these files Windows Vista setup can't start after first reboot
			md "%TEMP%\boot\sources\engine"
			copy /y "%~dp0apps\engine\*.*" "%TEMP%\boot\sources\engine" >nul
		
		) else (
		
			REM Apply original setup design patch
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\ARUNIMG.dll" -save "%TEMP%\boot\sources\ARUNIMG.dll" -action addoverwrite -resource "%~dp0resources\7\ARUNIMG.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\arunres.dll" -save "%TEMP%\boot\sources\arunres.dll" -action addoverwrite -resource "%~dp0resources\7\arunres.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\spwizimg.dll" -save "%TEMP%\boot\sources\spwizimg.dll" -action addoverwrite -resource "%~dp0resources\7\spwizimg.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\spwizres.dll" -save "%TEMP%\boot\sources\spwizres.dll" -action addoverwrite -resource "%~dp0resources\7\spwizres.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\w32uiimg.dll" -save "%TEMP%\boot\sources\w32uiimg.dll" -action addoverwrite -resource "%~dp0resources\7\w32uiimg.res" , , , -log NUL
			"%~dp0apps\ResHack\ResourceHacker.exe" -open "%TEMP%\boot\sources\w32uires.dll" -save "%TEMP%\boot\sources\w32uires.dll" -action addoverwrite -resource "%~dp0resources\7\w32uires.res" , , , -log NUL
				
			copy /y "%~dp0resources\7\background.bmp" "%TEMP%\boot\sources\background.bmp" >nul
		
		)

	)
)





REM Ability to run setup.cmd using Winpeshl.ini
copy "%~dp0deployment\setup.cmd" "%TEMP%\boot\sources\setup.cmd" >nul

takeown /F "%TEMP%\boot\sources\setup.exe" /A >nul 2>nul
icacls "%TEMP%\boot\sources\setup.exe" /grant *S-1-5-32-544:F >nul 2>nul

ren "%TEMP%\boot\sources\setup.exe" "launcher.exe" >nul 2>nul


dism /unmount-wim /MountDir:"%TEMP%\boot" /commit >nul
rd /s /q "%TEMP%\boot"





if "%ICONPATCH%" == "Yes" (

	set /a STEP+=1
	echo  [!STEP!] Applying RunOnceEx icon patch

	REM Get number of images
	for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\install.%IFORMAT%" ^| findstr "Index"') do set IMGCNT=%%i

	if not exist "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" (
		if not exist "%~dp0temp" md "%~dp0temp"
		
		"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\system32\iernonce.dll" -aos -o"%~dp0temp" >nul
		if not exist "%IMAGE%\sources\$OEM$\$$\system32" md "%IMAGE%\sources\$OEM$\$$\system32"
		move /y "%~dp0temp\%EPATH%\system32\iernonce.dll" "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" >nul
		rd /q /s "%~dp0temp" >nul
		rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.wim" !IMGCNT! /Windows/System32/iernonce.dll --dest-dir="%IMAGE%\sources\$OEM$\$$\system32" --nullglob >nul 2>nul
	)

	takeown /F "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" /A >nul
	icacls "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" /grant *S-1-5-32-544:F >nul

	"%~dp0apps\ResHack\ResourceHacker.exe" -open "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" -save "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" -action addoverwrite -resource "%~dp0resources\iernonce.dll.res" , , , -log NUL
	"%~dp0apps\PEChecksum.exe" -c "%IMAGE%\sources\$OEM$\$$\system32\iernonce.dll" >nul

)





if "%WINRE%" == "Yes" (

	set /a STEP+=1
	echo  [!STEP!] Adding Windows Recovery Environment
	
	
	if exist "%IMAGE%\sources\6.0.*" (
		REM Vista
		
		dism /Export-Image /SourceImageFile:"%IMAGE%\sources\boot.wim" /SourceIndex:2 /DestinationImageFile:"%IMAGE%\sources\winre.wim" /Compress:None >nul
	
		md "%TEMP%\boot"
		dism /Mount-Wim /WimFile:"%IMAGE%\sources\winre.wim" /index:1 /mountdir:"%TEMP%\boot" >nul

		echo [LaunchApps]> "%TEMP%\boot\Windows\System32\Winpeshl.ini"
		echo AppPath=X:\sources\recovery\recenv.exe>> "%TEMP%\boot\Windows\System32\Winpeshl.ini"

		dism /unmount-wim /MountDir:"%TEMP%\boot" /commit >nul
		rd /s /q "%TEMP%\boot"
		
		"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" info "%IMAGE%\sources\winre.wim" 1 --image-property NAME="Microsoft Windows Recovery Environment ^(%IMGARCH%^)"
		"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" info "%IMAGE%\sources\winre.wim" 1 --image-property DESCRIPTION="Microsoft Windows Recovery Environment ^(%IMGARCH%^)"
		
	) else (
		REM Windows 7 and newer
		
		if not exist "%~dp0temp" md "%~dp0temp"
		
		REM Get number of images
		for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\install.%IFORMAT%" ^| findstr "Index"') do set IMGCNT=%%i

		"%~dp0apps\7z\%ARCH%\7z.exe" x "%IMAGE%\sources\install.%IFORMAT%" "%EPATH%\System32\recovery\Winre.wim" -aos -o"%~dp0temp" >nul
		
		move /y "%~dp0temp\%EPATH%\System32\recovery\winre.wim" "%IMAGE%\sources\winre.wim" >nul
		rd /q /s "%~dp0temp"
		rem "%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" extract "%IMAGE%\sources\install.%IFORMAT%" !IMGCNT! /Windows/System32/recovery/winre.wim --dest-dir="%IMAGE%\sources" --nullglob >nul 2>nul
	)
	
	
	if exist "%IMAGE%\sources\winre.wim" (
		attrib -r -h -s -a "%IMAGE%\sources\winre.wim"

		REM Duplicate default boot entry
		FOR /F "delims={} tokens=2" %%I IN ('bcdedit /store "%IMAGE%\boot\bcd" /copy {default} /d "Windows Recovery Environment"') DO SET GUID=%%I
		bcdedit /store "%IMAGE%\boot\bcd" /set {!GUID!} device "ramdisk=[boot]\sources\winre.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}" >nul
		bcdedit /store "%IMAGE%\boot\bcd" /set {!GUID!} osdevice "ramdisk=[boot]\sources\winre.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}" >nul
		bcdedit /store "%IMAGE%\boot\bcd" /displayorder {!GUID!} /addlast >nul


		REM Duplicate UEFI default boot entry
		FOR /F "delims={} tokens=2" %%I IN ('bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /copy {default} /d "Windows Recovery Environment"') DO SET GUID=%%I
		bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {!GUID!} device "ramdisk=[boot]\sources\winre.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}" >nul
		bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /set {!GUID!} osdevice "ramdisk=[boot]\sources\winre.wim,{7619dcc8-fafe-11d9-b411-000476eba25f}" >nul
		bcdedit /store "%IMAGE%\efi\microsoft\boot\bcd" /displayorder {!GUID!} /addlast >nul
	)
	
)



attrib -r -h -s -a "%IMAGE%\boot\bcd.log*"
attrib -r -h -s -a "%IMAGE%\efi\microsoft\boot\bcd.log*"

del /q /s /a "%IMAGE%\boot\bcd.log*" >nul 2>nul
del /q /s /a "%IMAGE%\efi\microsoft\boot\bcd.log*" >nul 2>nul




set /a STEP+=1
echo  [%STEP%] Exporting boot.wim

REM Get number of images
for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\boot.wim" ^| findstr "Index"') do set IMGCNT=%%i


FOR /L %%i IN (1,1,%IMGCNT%) DO (
	dism /Export-Image /SourceImageFile:"%IMAGE%\sources\boot.wim" /SourceIndex:%%i /DestinationImageFile:"%IMAGE%\sources\boot2.wim" /Compress:None >nul
)

del /q /s "%IMAGE%\sources\boot.wim" >nul
ren "%IMAGE%\sources\boot2.wim" "boot.wim"


if exist "%IMAGE%\sources\winre.wim" (

	set /a STEP+=1
	echo  [!STEP!] Exporting winre.wim

	REM Get number of images
	for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\winre.wim" ^| findstr "Index"') do set IMGCNT=%%i


	FOR /L %%i IN (1,1,!IMGCNT!) DO (
		dism /Export-Image /SourceImageFile:"%IMAGE%\sources\winre.wim" /SourceIndex:%%i /DestinationImageFile:"%IMAGE%\sources\winre2.wim" /Compress:None >nul
	)

	del /q /s "%IMAGE%\sources\winre.wim" >nul
	ren "%IMAGE%\sources\winre2.wim" "winre.wim"
	
)


set /a STEP+=1
echo  [%STEP%] Recompressing boot.wim
echo.
"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" optimize "%IMAGE%\sources\boot.wim" --compress=LZX:100

if exist "%IMAGE%\sources\winre.wim" (
	echo.
	set /a STEP+=1
	echo  [!STEP!] Recompressing winre.wim
	echo.
	"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" optimize "%IMAGE%\sources\winre.wim" --compress=LZX:100
)



if "%INSTALLRECOMPRESS%" == "Yes" (

	set /a STEP+=1
	echo.
	echo  [!STEP!] Exporting install.wim

	REM Get number of images
	for /f "tokens=2 delims=: " %%i in ('dism.exe /english /get-wiminfo /wimfile:"%IMAGE%\sources\install.%IFORMAT%" ^| findstr "Index"') do set IMGCNT=%%i


	FOR /L %%i IN (1,1,!IMGCNT!) DO (
		dism /Export-Image /SourceImageFile:"%IMAGE%\sources\install.%IFORMAT%" /SourceIndex:%%i /DestinationImageFile:"%IMAGE%\sources\install2.wim" /Compress:None >nul
	)

	del /q /s "%IMAGE%\sources\install.%IFORMAT%" >nul
	ren "%IMAGE%\sources\install2.wim" "install.wim"


	if "%INSTALLFORMAT%" == "ESD" (

		set /a STEP+=1
		echo  [!STEP!] Compressing install.esd
		echo.
		"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" export "%IMAGE%\sources\install.wim" all "%IMAGE%\sources\install.esd" --compress=LZMS --solid
		del /q /s "%IMAGE%\sources\install.wim" >nul

	) else (

		set /a STEP+=1
		echo  [!STEP!] Recompressing install.wim
		echo.
		"%~dp0apps\WimLib\%ARCH%\wimlib-imagex.exe" optimize "%IMAGE%\sources\install.wim" --compress=LZX:100

	) 

)






if "%BUILDISO%" == "Yes" (
	echo.
	set /a STEP+=1
	echo  [!STEP!] Building ISO
	
	if exist "%IMAGE%\efi\microsoft\boot\efisys.bin" (
		"%~dp0apps\oscdimg.exe" -l"%ISOLABEL%" -m -oc -u2 -udfver102 -bootdata:2#p0,e,b"%IMAGE%\boot\etfsboot.com"#pEF,e,b"%IMAGE%\efi\microsoft\boot\efisys.bin" "%IMAGE%" "%~dp0%ISONAME%.iso"
	) else (
		"%~dp0apps\oscdimg.exe" -l"%ISOLABEL%" -m -oc -u2 -udfver102 -b"%IMAGE%\boot\etfsboot.com" "%IMAGE%" "%~dp0%ISONAME%.iso"
	)
)




if exist "%~dp0_output" rd /q /s "%~dp0_output"
if exist "%~dp0_engine" rd /q /s "%~dp0_engine"


endlocal


if "%~1" == "" (
	echo.
	echo Process finished, press any key to exit...
	pause >nul
	goto :EOF
) else (
	goto :EOF
)


:ReadINI
for /f "tokens=1* delims==" %%A in ('findstr /b /i "%1" "%~dp0Config.ini" 2^>nul') do set "%2=%%~B"
goto :EOF