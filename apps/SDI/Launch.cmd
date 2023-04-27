@echo off
title Silent Snappy Driver Installer launcher


IF EXIST "%WINDIR%\SysWOW64" (
	SET ARCH=x64
) ElSE (
	SET ARCH=x86
)

REM Get DVD / USB drive
FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%I:\sources\install.esd" SET DRIVE=%%I:&&SET INSTALL=install.esd
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%I:\sources\install.wim" SET DRIVE=%%I:&&SET INSTALL=install.wim
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST "%%I:\sources\install.swm" SET DRIVE=%%I:&&SET INSTALL=install.swm


if not exist "%WinDir%\Logs" md "%WinDir%\Logs" >nul

cd /D "%DRIVE%\support\SDI"


REM Detect Windows default language
if exist "%WinDir%\servicing\Version\6.0.*" (
	REM Windows Vista
	for /f "tokens=3 delims= " %%i in ('reg query "HKEY_USERS\.DEFAULT\Control Panel\International" /v "LocaleName"') do set sllp=%%i
) else (
	REM Windows 7 and newer
	for /f "tokens=3 delims=: " %%i in ('dism.exe /online /get-intl /english ^| find /i "System locale :"') do set sllp=%%i
)


REM Set SDI language
if "%SLLP%" == "en-US" set "SDILANG=English"
if "%SLLP%" == "cs-CZ" set "SDILANG=Czech"
if "%SLLP%" == "ar-SA" set "SDILANG=Arabic"
if "%SLLP%" == "hy-AM" set "SDILANG=Armenian"
if "%SLLP%" == "be-BY" set "SDILANG=Belarusian"
if "%SLLP%" == "pt-BR" set "SDILANG=Brazilian"
if "%SLLP%" == "bg-BG" set "SDILANG=Bulgarian"
if "%SLLP%" == "ca-ES" set "SDILANG=Catalan"
if "%SLLP%" == "hr-HR" set "SDILANG=Croatian"
if "%SLLP%" == "da-DK" set "SDILANG=Danish"
if "%SLLP%" == "nl-NL" set "SDILANG=Dutch"
if "%SLLP%" == "et-EE" set "SDILANG=Estonian"
if "%SLLP%" == "fr-FR" set "SDILANG=French"
if "%SLLP%" == "ka-GE" set "SDILANG=Georgian"
if "%SLLP%" == "de-DE" set "SDILANG=German"
if "%SLLP%" == "el-GR" set "SDILANG=Greek"
if "%SLLP%" == "he-IL" set "SDILANG=Hebrew"
if "%SLLP%" == "hu-HU" set "SDILANG=Hungarian"
if "%SLLP%" == "zh-TW" set "SDILANG=Chinese_tw"
if "%SLLP%" == "zh-CN" set "SDILANG=Chinese_zh"
if "%SLLP%" == "id-ID" set "SDILANG=Indonesian"
if "%SLLP%" == "it-IT" set "SDILANG=Italian"
if "%SLLP%" == "ja-JP" set "SDILANG=Japanese"
if "%SLLP%" == "ko-KR" set "SDILANG=Korean"
if "%SLLP%" == "lv-LV" set "SDILANG=Latvian"
if "%SLLP%" == "lt-LT" set "SDILANG=Lithuanian"
if "%SLLP%" == "nb-NO" set "SDILANG=Norwegian"
if "%SLLP%" == "pl-PL" set "SDILANG=Polish"
if "%SLLP%" == "pt-PT" set "SDILANG=Portuguese"
if "%SLLP%" == "ro-RO" set "SDILANG=Romanian"
if "%SLLP%" == "ru-RU" set "SDILANG=Russian"
if "%SLLP%" == "sk-SK" set "SDILANG=Slovak"
if "%SLLP%" == "es-ES" set "SDILANG=Spanish"
if "%SLLP%" == "sv-SE" set "SDILANG=Swedish"
if "%SLLP%" == "th-TH" set "SDILANG=Thai"
if "%SLLP%" == "tr-TR" set "SDILANG=Turkish"
if "%SLLP%" == "uk-UA" set "SDILANG=Ukrainian"
if "%SLLP%" == "vi-VN" set "SDILANG=Vietnamese"
if "%SLLP%" == "az-Latn-AZ" set "SDILANG=Azerbaijan"
if "%SLLP%" == "az-Cyrl-AZ" set "SDILANG=Azerbaijan"
if "%SLLP%" == "fa-IR" set "SDILANG=Farsi"


if not defined SDILANG set "SDILANG=English"

REM SDI Execution
start /wait "SDI" "%~dp0SDI_%ARCH%.exe" -theme:Grass -lang:%SDILANG% -license:1 -expertmode -showdrpnames2 -novirusalerts -norestorepnt -reindex -drp_dir:"%DRIVE%\driverpacks" -log_dir:"%WinDir%\Logs" -autoinstall -autoclose



goto :EOF