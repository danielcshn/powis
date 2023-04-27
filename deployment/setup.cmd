REM Created in 2021 by George King
@ECHO OFF
TITLE Windows Setup Launcher
CLS


REM Get DVD / USB drive
FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%I:\sources\install.esd" SET DRIVE=%%I:&&SET INSTALL=install.esd
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%I:\sources\install.wim" SET DRIVE=%%I:&&SET INSTALL=install.wim
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%I:\sources\install.swm" SET DRIVE=%%I:&&SET INSTALL=install.swm


REM Unattended detection
IF EXIST "%DRIVE%\settings.ini" (
	CALL :ReadINI UnattendedType UNATTENDEDTYPE
	CALL :ReadINI UnattendedFile UNATTENDEDFILE
) ELSE (
	SET UNATTENDEDFILE=autounattend.xml
)


SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

IF "%UNATTENDEDTYPE%" == "Select" (

	SET /A XMLCOUNT=0

	FOR /f "delims=" %%I IN ('dir /b /o:gn "%DRIVE%\*.xml"') DO (
	 	IF NOT "%%I" == "skiprecovery.xml" (
			SET FileName=%%I
			SET FileName=!FileName:~0,10!
			IF NOT "!FileName!" == "Auto-saved" SET /a XMLCOUNT+=1
		)
	)
	
	IF !XMLCOUNT! LEQ 1 (
		SET UNATTENDEDFILE=%UNATTENDEDFILE%
	) ELSE (
		
		ECHO.
		ECHO Which unattended file would you like to use?
		ECHO.
		
		SET /A XMLCOUNT=0
		FOR /F "delims=" %%I IN ('dir /b /o:gn "%DRIVE%\*.xml"') DO (
		
			IF NOT "%%I" == "skiprecovery.xml" (
				SET FileName=%%I
				SET FileName=!FileName:~0,10!
				IF NOT "!FileName!" == "Auto-saved" (
					SET /a XMLCOUNT+=1
					ECHO  [!XMLCOUNT!] %%~nI%%~xI
				)
			)

		)
		
		ECHO.
		SET /P FILEID=Enter your choice: 

		
		SET /A XMLCOUNT=0
		FOR /F "delims=" %%I IN ('dir /b /o:gn "%DRIVE%\*.xml"') DO (

		
			IF NOT "%%I" == "skiprecovery.xml" (
				SET "FileName=%%I"
				SET "FileName=!FileName:~0,10!"
				IF NOT "!FileName!" == "Auto-saved" (
					SET /a XMLCOUNT+=1
					IF "!XMLCOUNT!" == "!FILEID!" (
						SET "SELECTEDFILE=%%I"
						REM echo %%I
						REM echo !FILEID!
						REM echo !XMLCOUNT!
					)
				)
			)
		)

	)
	
) ELSE IF "%UNATTENDEDTYPE%" == "Auto" (
	SET UNATTENDEDFILE=%UNATTENDEDFILE%
)


IF DEFINED SELECTEDFILE SET UNATTENDEDFILE=!SELECTEDFILE!



REM Run original setup.exe
IF EXIST "%DRIVE%\%UNATTENDEDFILE%" (
	IF EXIST "X:\sources\launcher.exe" (
		IF EXIST "%DRIVE%\sources\$OEM$" (
			"X:\sources\launcher.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /m:"%DRIVE%\sources\$OEM$" /unattend:"%DRIVE%\%UNATTENDEDFILE%" /noreboot
		) ELSE (
			"X:\sources\launcher.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /unattend:"%DRIVE%\%UNATTENDEDFILE%" /noreboot
		)		
	) ELSE (
		IF EXIST "%DRIVE%\sources\$OEM$" (
			"%~dp0setup.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /m:"%DRIVE%\sources\$OEM$" /unattend:"%DRIVE%\%UNATTENDEDFILE%" /noreboot
		) ELSE (
			"%~dp0setup.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /unattend:"%DRIVE%\%UNATTENDEDFILE%" /noreboot
		)
	)
) ELSE (
	IF EXIST "X:\sources\launcher.exe" (
		IF EXIST "%DRIVE%\sources\$OEM$" (
			"X:\sources\launcher.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /m:"%DRIVE%\sources\$OEM$" /noreboot
		) ELSE (
			"X:\sources\launcher.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /noreboot
		)
	) ELSE (
		IF EXIST "%DRIVE%\sources\$OEM$" (
			"%~dp0setup.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /m:"%DRIVE%\sources\$OEM$" /noreboot
		) ELSE (
			"%~dp0setup.exe" /installfrom:"%DRIVE%\sources\%INSTALL%" /noreboot
		)
	)
)



ENDLOCAL

REM Inject drivers from %DRIVE%\drivers folder
FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\Windows\DriversTarget SET TARGET=%%I:



IF EXIST "%TARGET%\Windows\SysWOW64" (
	SET TARGETARCH=amd64
) ELSE (
	SET TARGETARCH=x86
)



set /A DRIVERS64COUNT=0
set /A DRIVERS32COUNT=0
set /A DRIVERSALLCOUNT=0

FOR /F "delims=" %%I IN ('dir /s /b /o:gn "%DRIVE%\drivers\x64\*.inf" 2^>nul') DO CALL SET /A DRIVERS64COUNT+=1
FOR /F "delims=" %%I IN ('dir /s /b /o:gn "%DRIVE%\drivers\x86\*.inf" 2^>nul') DO CALL SET /A DRIVERS32COUNT+=1
FOR /F "delims=" %%I IN ('dir /s /b /o:gn "%DRIVE%\drivers\all\*.inf" 2^>nul') DO CALL SET /A DRIVERSALLCOUNT+=1


REM Apply custom steps only when setup sucessfully finished
IF EXIST "%TARGET%" (


	REM Windows Vista with Windows 8.0 setup engine fix
	if exist "%TARGET%\Windows\servicing\Version\6.0.*" (

		if exist "X:\sources\dism.exe" (
					
			copy /y "X:\sources\engine\*.*" "%TARGET%\Windows\Panther" >nul
			
			REM Correct all registry entries touched by new setup engine
			reg load HKLM\TEMPSOFTWARE "%TARGET%\Windows\System32\config\SOFTWARE" >nul
			reg delete "HKLM\TEMPSOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /f >nul
			reg delete "HKLM\TEMPSOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE" /v "RetailInstall" /f >nul
			reg add "HKLM\TEMPSOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE" /v "MediaBootInstall" /t REG_DWORD /d "1" /f >nul
			reg add "HKLM\TEMPSOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE" /v "SetupDisplayedProductKey" /t REG_DWORD /d "1" /f >nul
			reg add "HKLM\TEMPSOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOrganization" /t REG_SZ /d "Microsoft" /f >nul
			reg add "HKLM\TEMPSOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOwner" /t REG_SZ /d "Microsoft" /f >nul
			reg unload HKLM\TEMPSOFTWARE >nul

			reg load HKLM\TEMPSYSTEM "%TARGET%\Windows\System32\config\SYSTEM" >nul
			reg delete "HKLM\TEMPSYSTEM\Setup\SetupCL\PendingRequest" /f >nul
			reg delete "HKLM\TEMPSYSTEM\Setup\SetupCL" /v "BlockOperations" /f >nul
			reg delete "HKLM\TEMPSYSTEM\Setup\SetupCL" /v "ExecutionSuccessful" /f >nul
			reg delete "HKLM\TEMPSYSTEM\Setup\SetupCL" /v "NTSTATUS" /f >nul
			reg delete "HKLM\TEMPSYSTEM\RNG" /v "ExternalEntropy" /f >nul
			reg unload HKLM\TEMPSYSTEM >nul

			reg load HKLM\TEMPDEFAULT "%TARGET%\Windows\System32\config\DEFAULT" >nul
			reg delete "HKLM\TEMPDEFAULT\Control Panel\International" /v "sShortTime" /f >nul
			reg unload HKLM\TEMPDEFAULT >nul

			rem X:\sources\dism.exe /image:%TARGET% /Apply-Unattend:%DRIVE%\ultimate.xml

			rd /q /s "%TARGET%\$WINDOWS.~BT" >nul
			rd /q /s "%TARGET%\$WINDOWS.~LS" >nul
			
		)
	)



	IF EXIST "%TARGET%\Windows\SysWOW64" (
		IF %DRIVERS64COUNT% GEQ 1 (

			TITLE Windows Setup Launcher :: Adding 64-bit drivers >nul
			
			IF EXIST "%TARGET%\Windows\servicing\Version\6.0.*" (

				IF EXIST "X:\sources\dism.exe" (
					REM Windows Vista with Windows 8.0 setup engine
					(
						echo	^<?xml version="1.0" ?^>
						echo	^<unattend xmlns="urn:schemas-microsoft-com:asm.v3" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
						echo	   ^<settings pass="offlineServicing"^>
						echo		  ^<component name="Microsoft-Windows-PnpCustomizationsNonWinPE" processorArchitecture="%TARGETARCH%" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"^>
						echo			 ^<DriverPaths^>
						echo				^<PathAndCredentials wcm:keyValue="1"^>
						echo				   ^<Path^>%DRIVE%\drivers\x64^</Path^>
						echo				^</PathAndCredentials^>
						echo			 ^</DriverPaths^>
						echo		  ^</component^>
						echo	   ^</settings^>
						echo	^</unattend^>
					)>%TEMP%\Drivers.xml
					
					X:\sources\dism.exe /image:%TARGET% /Apply-Unattend:%TEMP%\Drivers.xml /LogPath:"%TARGET%\Windows\inf\OfflineDrivers.log"
					
				)
			) ELSE (
				REM Windows 7 and newer
				"%WinDir%\system32\dism.exe" /image:%TARGET% /Add-Driver /Driver:"%DRIVE%\drivers\x64" /Recurse /ForceUnsigned /LogPath:"%TARGET%\Windows\inf\OfflineDrivers.log"		
			)	
		)
	) ElSE (
		IF %DRIVERS32COUNT% GEQ 1 (
			TITLE Windows Setup Launcher :: Adding 32-bit drivers >nul
			
			IF EXIST "%TARGET%\Windows\servicing\Version\6.0.*" (

				IF EXIST "X:\sources\dism.exe" (
					REM Windows Vista with Windows 8.0 setup engine
					(
						echo	^<?xml version="1.0" ?^>
						echo	^<unattend xmlns="urn:schemas-microsoft-com:asm.v3" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
						echo	   ^<settings pass="offlineServicing"^>
						echo		  ^<component name="Microsoft-Windows-PnpCustomizationsNonWinPE" processorArchitecture="%TARGETARCH%" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"^>
						echo			 ^<DriverPaths^>
						echo				^<PathAndCredentials wcm:keyValue="1"^>
						echo				   ^<Path^>%DRIVE%\drivers\x86^</Path^>
						echo				^</PathAndCredentials^>
						echo			 ^</DriverPaths^>
						echo		  ^</component^>
						echo	   ^</settings^>
						echo	^</unattend^>
					)>%TEMP%\Drivers.xml
					
					X:\sources\dism.exe /image:%TARGET% /Apply-Unattend:%TEMP%\Drivers.xml /LogPath:"%TARGET%\Windows\inf\OfflineDrivers.log"
					
				)
			) ELSE (
				REM Windows 7 and newer
				"%WinDir%\system32\dism.exe" /image:%TARGET% /Add-Driver /Driver:"%DRIVE%\drivers\x86" /Recurse /ForceUnsigned /LogPath:"%TARGET%\Windows\inf\OfflineDrivers.log"		
			)	
		)
	)
	
	IF %DRIVERSALLCOUNT% GEQ 1 (

		TITLE Windows Setup Launcher :: Adding achitecture independent drivers >nul
		
		IF EXIST "%TARGET%\Windows\servicing\Version\6.0.*" (

			IF EXIST "X:\sources\dism.exe" (
				REM Windows Vista with Windows 8.0 setup engine
				(
					echo	^<?xml version="1.0" ?^>
					echo	^<unattend xmlns="urn:schemas-microsoft-com:asm.v3" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"^>
					echo	   ^<settings pass="offlineServicing"^>
					echo		  ^<component name="Microsoft-Windows-PnpCustomizationsNonWinPE" processorArchitecture="%TARGETARCH%" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"^>
					echo			 ^<DriverPaths^>
					echo				^<PathAndCredentials wcm:keyValue="1"^>
					echo				   ^<Path^>%DRIVE%\drivers\all^</Path^>
					echo				^</PathAndCredentials^>
					echo			 ^</DriverPaths^>
					echo		  ^</component^>
					echo	   ^</settings^>
					echo	^</unattend^>
				)>%TEMP%\Drivers.xml
				
				X:\sources\dism.exe /image:%TARGET% /Apply-Unattend:%TEMP%\Drivers.xml /LogPath:"%TARGET%\Windows\inf\OfflineDrivers.log"
				
			)
		) ELSE (
			REM Windows 7 and newer
			"%WinDir%\system32\dism.exe" /image:%TARGET% /Add-Driver /Driver:"%DRIVE%\drivers\all" /Recurse /ForceUnsigned /LogPath:"%TARGET%\Windows\inf\OfflineDrivers.log"		
		)	
	)

	
	if exist %TEMP%\Drivers.xml del /q /s %TEMP%\Drivers.xml >nul

	REM Ability for custom scripting after first reboot
	reg load HKLM\TEMPSYSTEM "%TARGET%\Windows\System32\config\SYSTEM" >nul
	REG ADD "HKLM\TEMPSYSTEM\Setup" /v "CmdLine" /t REG_SZ /d "C:\Windows\System32\wscript.exe //nologo C:\Windows\setup\scripts\invisible.vbs C:\Windows\setup\scripts\WinDeploy.cmd" /f >nul
	reg unload HKLM\TEMPSYSTEM >nul


	REM Windows 8 and newer need this tweak to avoid insane long Login screen before RunOnceEx
	reg load HKLM\TEMPSOFTWARE "%TARGET%\Windows\System32\config\SOFTWARE" >nul
	reg add "HKLM\TEMPSOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DelayedDesktopSwitchTimeout"  /t REG_DWORD /d "5" /f >nul
	reg unload HKLM\TEMPSOFTWARE >nul
		

)



REM Perform reboot
IF EXIST "X:\sources\launcher.exe" (
	IF NOT EXIST "%DRIVE%\skiprecovery.xml" (
		%WINDIR%\System32\wpeutil.exe reboot
		EXIT
	) ELSE (
		EXIT
	)
) ELSE (
	IF EXIST "%TARGET%" (
		%WINDIR%\System32\shutdown.exe -r -f -t 0
		EXIT
	)
)



:ReadINI
FOR /F "tokens=1* delims==" %%A IN ('find /i "%1" "%DRIVE%\settings.ini" 2^>nul') DO SET "%2=%%~B"
goto :EOF