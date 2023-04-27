Place any MSI installer into this folder and software will be silenty installed using RunOnceEx dialog 
 
(YOURAPPINSTALLER-x86.msi and YOURAPPINSTALLER-x64.msi) or YOURAPPINSTALLER-all.msi 
 
 
Install any other software unattended using this folder. Just place installer here with right format, same as MSI installation 
Create YOURAPPINSTALLER.TXT file with only one line that contain silent switch 
(YOURAPPINSTALLER-x86.exe and YOURAPPINSTALLER-x64.exe) or YOURAPPINSTALLER-all.exe 
 
For example install WinRar silenty, you need to add Winrar-x86.exe + Winrar-x64.exe + WinRar.txt that contains /S 
 
 
If you want add registry tweaks into system, just place any *.reg files here and they will be automatically applied

Place here any *.cer and they will be added as first thing. This is very usefull for unattended VirtualBox installation

Also custom *.bat *.cmd *.ps1 can be placed here and they are launched as last thing before reboot
