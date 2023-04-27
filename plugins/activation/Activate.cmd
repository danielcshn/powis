REM Your custom activation steps go in this file

@echo off
title Windows Activation
cls

REM Get DVD / USB
FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.esd SET DRIVE=%%I:
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.wim SET DRIVE=%%I:
IF "%DRIVE%" == "" FOR %%I IN (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) DO IF EXIST %%I:\sources\install.swm SET DRIVE=%%I:

REM Place your needed commands here

goto :EOF

