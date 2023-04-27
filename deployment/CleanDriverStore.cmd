@echo off
title Windows DriverStore CleanUp
cls

echo.
echo Creating Restore Point

"%WinDir%\System32\wbem\wmic.exe" /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "DriverStore CleanUp %DATE%", 100, 1 >nul

REM Get count of all OEM drivers
set OEMDRVCNT=0
for %%A in ("%WinDir%\inf\OEM*.inf") do set /a OEMDRVCNT+=1

echo.

if exist "%WinDir%\Logs\CleanDriverStore.log" del /q /s "%WinDir%\Logs\CleanDriverStore.log"

REM Remove unused 3rd drivers, drivers in use will be skipped with error
for /L %%A in (0,1,%OEMDRVCNT%) do (
	if exist "%WinDir%\inf\OEM%%A.inf" (
		if "%~1" == "/log" (
			echo Deleting "%WinDir%\inf\OEM%%A.inf" >> "%WinDir%\Logs\CleanDriverStore.log"
			"%WinDir%\system32\pnputil.exe" -d "OEM%%A.inf" >> "%WinDir%\Logs\CleanDriverStore.log"
		) else (
			echo Deleting "%WinDir%\inf\OEM%%A.inf"
			"%WinDir%\system32\pnputil.exe" -d "OEM%%A.inf"
		)
	)
)

exit