#Install a file and create an uninstaller to remove it

#This script will do the following: create an installer named "installer.exe"; 
#Install a file named "test.txt" to the desktop; create an uninstaller named "uninstaller.exe" on the desktop. 
#The uninstaller will remove itself and the installed text file.
!define APPNAME "Fzam"
!define REGPATH_UNINSTSUBKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

RequestExecutionLevel admin

InstallDir "$PROGRAMFILES\${APPNAME}"
InstallDirRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" UninstallString

# define installer name
OutFile "Fzam_Installer_x86_20230412_alpha.exe"
 
# set desktop as install directory
#InstallDir $DESKTOP
 
# default section start
Section
 
# define output path
SetOutPath $INSTDIR
 
# specify file to go in output path

File fzam.exe
File fsqlf.exe
File fzam.ico
File factuzam_original.sql
File factuzam_original_update_script.sql

createShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\fzam.exe" "" "$INSTDIR\fzam.ico"

# define uninstaller name
WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "FZam"
WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" '"$INSTDIR\uninstaller.exe"'
WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1

WriteUninstaller $INSTDIR\uninstaller.exe
 
# Install MariaDB silently
DetailPrint "Instalando MariaDB silenciosamente..."
SetOutPath $TEMP
File "mariadb_installer.msi"
#mariadb_installer.msi
#SERVICENAME=MariaDB DATADIR="$APPDATA\Fzam\mariadb\data" PORT=3310 PASSWORD=default REMOVE=DEVEL REMOVE=HeidiSQL /qn
ExecWait 'msiexec /i "$TEMP\mariadb_installer.msi" DATADIR="$INSTDIR\BaseDatos\mariadb\data" PORT=3310 PASSWORD=Zamora2023 SERVICENAME=MariaDBFzam ADDLOCAL=ALL REMOVE=HeidiSQL  /qn  '
 
#-------
# default section end
SectionEnd

# create a section to define what the uninstaller does.
# the section will always be named "Uninstall"
Section "Uninstall"
 
# Delete installed file
Delete $INSTDIR\fzam.ini
Delete $INSTDIR\fzam.exe
Delete $INSTDIR\fsqlf.exe
Delete $INSTDIR\fzam.ico
Delete $INSTDIR\factuzam_original.sql
Delete $INSTDIR\factuzam_original_update_script.sql

Delete "$DESKTOP\${APPNAME}.lnk"

DetailPrint "Desinstalando MariaDB silenciosamente..."
#mariadb_installer.msi
ExecWait 'msiexec /i "$TEMP\mariadb_installer.msi" REMOVE=ALL /qn ' 

DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

# Delete the uninstaller
Delete $INSTDIR\uninstaller.exe
 
# Delete the directory
RMDir $INSTDIR
SectionEnd