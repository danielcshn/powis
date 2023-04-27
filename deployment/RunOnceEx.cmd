@echo off
REM TITLE Setting-up RunOnceEx
cls

IF EXIST "%WINDIR%\SysWOW64" (
	SET ARCH=x64
) ElSE (
	SET ARCH=x86
)


REM Default RunOnceEx header names

SET FINTEXT="Windows Post-Setup"
SET CERTEXT="Installing certificates"
SET SCRIPTTEXT="Executing scripts"
SET OFFTEXT="Installing Microsoft Office"
SET MSITEXT="Installing MSI packages"
SET ACTTEXT="Activating products"
SET UPDTEXT="Installing updates"
SET SILTEXT="Installing applications"
SET TWKTEXT="Applying personal settings"
SET DRVCLNTEXT="Removing unused drivers"
SET RBTTEXT="Reboot"


FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.esd SET DRIVE=%%I:
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.wim SET DRIVE=%%I:
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.swm SET DRIVE=%%I:

SET ROE=HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnceEx

IF EXIST "%WINDIR%\System32\iernonce.dll" (

	REG ADD %ROE% /v Title /d %FINTEXT% /f
	REG ADD %ROE% /v Flags /t REG_DWORD /d "00000014" /f

	REM Kill sysprep.exe
	REG ADD %ROE%\000 /ve /d " " /f
	REG ADD %ROE%\000 /v "00_KillSysprep" /d "%WINDIR%\System32\cmd.exe /min /c \"start \"Watcher\" %WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WINDIR%\setup\scripts\Watcher.cmd sysprep.exe\"" /f

    REM Kill explorer.exe on Windows 8 and up
    IF NOT EXIST "%WINDIR%\Servicing\Version\6.1.*" (
        REG ADD %ROE%\000 /ve /d " " /f
        REG ADD %ROE%\000 /v "01_KillExplorer" /d "%WINDIR%\System32\cmd.exe /min /c \"start \"Watcher\" %WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WINDIR%\setup\scripts\Watcher.cmd explorer.exe\"" /f
    )



    REM Install certificates into My / Root / CA store
    IF EXIST "%DRIVE%\setup\*.cer" (
        REG ADD %ROE%\001 /ve /d %CERTEXT% /f
        FOR %%U IN ("%DRIVE%\setup\*.cer") DO (
            REG ADD %ROE%\001 /v "%%~nU_TrustedPublisher" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WINDIR%\System32\certutil.exe -addstore TrustedPublisher %%U" /f
            REG ADD %ROE%\001 /v "%%~nU_My" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WINDIR%\System32\certutil.exe -addstore My %%U" /f
            REG ADD %ROE%\001 /v "%%~nU_CA" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WINDIR%\System32\certutil.exe -addstore CA %%U" /f
            REG ADD %ROE%\001 /v "%%~nU_Root" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WINDIR%\System32\certutil.exe -addstore Root %%U" /f
        )
    )


    REM Auto-install Microsoft Office 2007 - 2016
    IF EXIST "%DRIVE%\office\%ARCH%\setup.exe" (
        REG ADD %ROE%\002 /ve /d %OFFTEXT% /f
        REG ADD %ROE%\002 /v "MSO" /d "%DRIVE%\office\%ARCH%\setup.exe" /f
    ) ELSE IF EXIST "%DRIVE%\office\All\setup.exe" (
        REG ADD %ROE%\002 /ve /d %OFFTEXT% /f
        REG ADD %ROE%\002 /v "MSO" /d "%DRIVE%\office\All\setup.exe" /f
    )


    REM Auto-install Microsoft Office 2019 / 365
    IF EXIST "%DRIVE%\office\YAOCTRI_Installer.cmd" (
        REG ADD %ROE%\002 /ve /d %OFFTEXT% /f
        REG ADD %ROE%\002 /v "MSO" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %DRIVE%\office\YAOCTRI_Installer.cmd" /f
    )
    IF EXIST "%DRIVE%\office\YAOCTRIR_Installer.cmd" (
        REG ADD %ROE%\002 /ve /d %OFFTEXT% /f
        REG ADD %ROE%\002 /v "MSO" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %DRIVE%\office\YAOCTRIR_Installer.cmd" /f
    )


    REM Auto-install %ARCH% depend MSI packages
    IF EXIST "%DRIVE%\setup\*-%ARCH%.msi" (
        REG ADD %ROE%\003 /ve /d %MSITEXT% /f

        FOR %%C IN ("%DRIVE%\setup\*-%ARCH%.msi") DO (
            REM Get Installer
            FOR /F "tokens=1 delims=-" %%G IN ("%%~nC") DO (
                REM Get Switch
                if exist "%DRIVE%\setup\%%G.txt" (
                    for /F "usebackq tokens=*" %%A in ("%DRIVE%\setup\%%G.txt") do (
                        REG ADD %ROE%\003 /v "%%~nC" /d "%%C %%A" /f
                    )
                ) else (
                    REG ADD %ROE%\003 /v "%%~nC" /d "msiexec /i %%C /quiet /norestart" /f
                )
            )
        )
    )


    REM Auto-install %ARCH% independent MSI packages
    IF EXIST "%DRIVE%\setup\*-all.msi" (
        REG ADD %ROE%\003 /ve /d %MSITEXT% /f

        FOR %%C IN ("%DRIVE%\setup\*-all.msi") DO (
            REM Get Installer
            FOR /F "tokens=1 delims=-" %%G IN ("%%~nC") DO (
                REM Get Switch
                if exist "%DRIVE%\setup\%%G.txt" (
                    for /F "usebackq tokens=*" %%A in ("%DRIVE%\setup\%%G.txt") do (
                        REG ADD %ROE%\003 /v "%%~nC" /d "%%C %%A" /f
                    )
                ) else (
                    REG ADD %ROE%\003 /v "%%~nC" /d "msiexec /i %%C /quiet /norestart" /f
                )
            )
        )
    )


    REM Windows + Office activation
    IF EXIST "%DRIVE%\support\Activate.cmd" (
        REG ADD %ROE%\004 /ve /d %ACTTEXT% /f
        REG ADD %ROE%\004 /v "Activation" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %DRIVE%\support\Activate.cmd" /f
    )


    REM Install MSU / CAB / MSP Packages from %DRIVE%\updates
    REG ADD %ROE%\005 /ve /d %UPDTEXT% /f

    IF EXIST "%WinDir%\system32\dism.exe" (
		FOR %%U IN ("%DRIVE%\updates\*%ARCH%*.msu") DO REG ADD %ROE%\005 /v "%%~nU" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WinDir%\System32\dism.exe /Online /Add-Package /PackagePath:%%U /quiet /norestart" /f
		FOR %%U IN ("%DRIVE%\updates\*%ARCH%*.cab") DO REG ADD %ROE%\005 /v "%%~nU" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WinDir%\System32\dism.exe /Online /Add-Package /PackagePath:%%U /quiet /norestart" /f
	) ELSE IF EXIST "%WinDir%\system32\pkgmgr.exe" (
		REM Vista
		FOR %%U IN ("%DRIVE%\updates\*%ARCH%*.msu") DO REG ADD %ROE%\005 /v "%%~nU" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WinDir%\System32\wusa.exe %%U /quiet /norestart" /f
		FOR %%U IN ("%DRIVE%\updates\*%ARCH%*.cab") DO REG ADD %ROE%\005 /v "%%~nU" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WinDir%\System32\pkgmgr.exe /ip /m:%%U" /f
	)
	
	FOR %%U IN ("%DRIVE%\updates\*%ARCH%*.msp") DO REG ADD %ROE%\005 /v "%%~nU" /d "msiexec /i %%U /quiet /norestart" /f


    REM Auto-install %ARCH% depend software with predefined silent switch
    IF EXIST "%DRIVE%\setup\*-%ARCH%.exe" (
        REG ADD %ROE%\006 /ve /d %SILTEXT% /f

        FOR %%C IN ("%DRIVE%\setup\*-%ARCH%.exe") DO (
            REM Get Installer
            FOR /F "tokens=1 delims=-" %%G IN ("%%~nC") DO (
                REM Get Switch
                if exist "%DRIVE%\setup\%%G.txt" (
                    for /F "usebackq tokens=*" %%A in ("%DRIVE%\setup\%%G.txt") do (
                        REG ADD %ROE%\006 /v "%%~nC" /d "%%C %%A" /f
                    )
                ) else (
					REM Execute installer without specified switch - manual install or silent repacks
					REG ADD %ROE%\006 /v "%%~nC" /d "%%C" /f
				)
            )
        )
    )

    REM Auto-install %ARCH% independent software with predefined silent switch
    IF EXIST "%DRIVE%\setup\*-all.exe" (
        REG ADD %ROE%\006 /ve /d %SILTEXT% /f

        FOR %%C IN ("%DRIVE%\setup\*-all.exe") DO (
            REM Get Installer
            FOR /F "tokens=1 delims=-" %%G IN ("%%~nC") DO (
                REM Get Switch
                if exist "%DRIVE%\setup\%%G.txt" (
                    for /F "usebackq tokens=*" %%A in ("%DRIVE%\setup\%%G.txt") do (
                        REG ADD %ROE%\006 /v "%%~nC" /d "%%C %%A" /f
                    )
                ) else (
					REM Execute installer without specified switch - manual install or silent repacks
					REG ADD %ROE%\006 /v "%%~nC" /d "%%C" /f
				)
            )
        )
    )


    REM Apply REG Tweaks from %DRIVE%\setup
    IF EXIST "%DRIVE%\setup\*.reg" (
        REG ADD %ROE%\007 /ve /d %TWKTEXT% /f
        FOR %%U IN ("%DRIVE%\setup\*.reg") DO REG ADD %ROE%\007 /v "%%~nU" /d "%WINDIR%\regedit.exe /s \"%%U\"" /f
    )


    REM Remove unused drivers from DriverStore
    IF EXIST "%WINDIR%\setup\scripts\CleanDriverStore.cmd" (
        REG ADD %ROE%\008 /ve /d %DRVCLNTEXT% /f
        REG ADD %ROE%\008 /v "Driver CleanUp" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %WINDIR%\setup\scripts\CleanDriverStore.cmd /log" /f
    )


    REM Custom PS1 / CMD / BAT scripts execution
    REM PS1
    FOR %%C IN ("%DRIVE%\setup\*.ps1") DO (
		IF EXIST "%WinDir%\system32\WindowsPowerShell\v1.0\powershell.exe" (
			REG ADD %ROE%\009 /ve /d %SCRIPTTEXT% /f
			REM REG ADD %ROE%\009 /v "%%C" /d "%WINDIR%\System32\cmd.exe /min /c \"start /wait \"PowerShell\" powershell -NoLogo -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%%C\"\"" /f
			REG ADD %ROE%\009 /v "%%C" /d "%WinDir%\system32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%%C\"" /f
		)
	)

    REM CMD
    FOR %%C IN ("%DRIVE%\setup\*.cmd") DO (
        REG ADD %ROE%\009 /ve /d %SCRIPTTEXT% /f
        REG ADD %ROE%\009 /v "%%C" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs \"%%C\"" /f
    )

    REM BAT
    FOR %%C IN ("%DRIVE%\setup\*.bat") DO (
        REG ADD %ROE%\009 /ve /d %SCRIPTTEXT% /f
        REG ADD %ROE%\009 /v "%%C" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs \"%%C\"" /f
    )
	
	

	REM Operations before reboot
	REG ADD %ROE%\012 /ve /d %RBTTEXT% /f
	
	REM Perform OOBE boot
	REG ADD %ROE%\012 /v "00_OOBE" /d "%WinDir%\System32\cmd.exe /c \"REG ADD HKLM\SYSTEM\Setup\Status /v AuditBoot /t REG_DWORD /d 0 /f\"" /f

	REM Check activation if still not activated Infinite Trial is installed
    IF EXIST "%DRIVE%\support\Activate.cmd" (
        REM REG ADD %ROE%\012 /ve /d %ACTTEXT% /f
        REM REG ADD %ROE%\012 /v "01_Rearm" /d "%WinDir%\System32\wscript.exe //nologo %WinDir%\setup\scripts\invisible.vbs %DRIVE%\support\Activate.cmd /reamr" /f
    )

	REM Reboot
	REG ADD %ROE%\012 /v "02_Reboot" /d "%WINDIR%\System32\cmd.exe /min /c \"start \"Reboot\" %WinDir%\System32\shutdown.exe -r -f -t 1\"" /f


	REM Enable RunOnceEx processing
	REG ADD %ROE% /d "%WinDir%\System32\rundll32.exe %WINDIR%\System32\iernonce.dll,RunOnceExProcess" /f

	REM Perform audit boot
	REG ADD "HKLM\SYSTEM\Setup\Status" /v "AuditBoot" /t REG_DWORD /d "1" /f



	REM Localize RunOnceEx
	start /wait RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 128 %~dp0RunOnceEx.inf
	
	
	REM Remove unneeded header names without actions

	setlocal EnableExtensions EnableDelayedExpansion
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\001') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\001 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\002') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\002 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\003') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\003 /f
	
	REM Activation
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\004') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\004 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\005') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\005 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\006') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\006 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\007') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\007 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\008') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\008 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\009') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\009 /f
	
	SET /A ACTIONSCOUNT=0
	FOR /F "tokens=*" %%C IN ('REG QUERY %ROE%\012') DO CALL SET /A ACTIONSCOUNT+=1
	IF !ACTIONSCOUNT! LEQ 2 REG DELETE %ROE%\012 /f

	endlocal
	
)


REM Delete DriversTarget
IF EXIST "%WINDIR%\DriversTarget" (
	TAKEOWN /F "%WINDIR%\DriversTarget" /A >nul 2>nul
	ICACLS "%WINDIR%\DriversTarget" /grant Administrators:F >nul 2>nul
	ATTRIB -R -H -S -A "%WINDIR%\DriversTarget"
	DEL /q /s "%WINDIR%\DriversTarget" >nul
)



goto :EOF



:ReadINI
for /f "tokens=1* delims==" %%A in ('findstr /b /i "%1" "%~dp0RunOnceEx\%SLLP%.ini"') do set "%2=%%~B"
goto :EOF