@echo off
title Windows Process Watcher and Killer
cls

set ProcessToFind=%~1

:PerformCheck
for /f "tokens=1 delims= " %%G in ('tasklist ^| findstr %ProcessToFind%') do set RunningProcess=%%G

if "%RunningProcess%" == "%ProcessToFind%" (
    taskkill /im %ProcessToFind% /f
    exit
) else (
    timeout 1 >nul
    goto :PerformCheck
)