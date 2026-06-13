; UTF-8
Unicode True

; Include Modern UI
!include "MUI2.nsh"

; Definir el nombre del programa y la compañía
!define APPNAME "FZAM"
!define COMPANYNAME "Fzam & Co"
!define VERSION "1.0.0"

; Nombre del instalador
OutFile "FZAM_Installer_v${VERSION}.exe"

; Directorio de instalación predeterminado
InstallDir "$PROGRAMFILES\${APPNAME}"

; Obtener la instalación del registro si está disponible
InstallDirRegKey HKLM "Software\${APPNAME}" ""

; Solicitar privilegios de administrador
RequestExecutionLevel admin

; Interfaz
!define MUI_ABORTWARNING
!define MUI_ICON "fzam.ico"
!define MUI_UNICON "fzam.ico"

; Personalizar mensajes
!define MUI_WELCOMEPAGE_TITLE "Bienvenido al instalador de ${APPNAME}"
!define MUI_WELCOMEPAGE_TEXT "Este asistente le guiará a través de la instalación de ${APPNAME} v${VERSION}.$\n$\nSe recomienda cerrar todas las demás aplicaciones antes de iniciar la instalación.$\n$\nHaga clic en Siguiente para continuar."

!define MUI_FINISHPAGE_TITLE "Instalación de ${APPNAME} completada"
!define MUI_FINISHPAGE_TEXT "${APPNAME} v${VERSION} ha sido instalado en su sistema.$\n$\nHaga clic en Finalizar para cerrar este asistente."

; Páginas del instalador
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "licencia.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Páginas del desinstalador
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Idioma
!insertmacro MUI_LANGUAGE "Spanish"

; Secciones del instalador
Section "FZAM (requerido)" SecMain
    SectionIn RO
    SetOutPath $INSTDIR
    
    ; Archivos principales
    File "fzam.exe"
    File "fsqlf.exe"
    File "fzam.ico"
    File "factuzam_original.sql"
    File "factuzam_original_update_script.sql"
    
    ; Crear acceso directo en el menú de inicio
    CreateDirectory "$SMPROGRAMS\${APPNAME}"
    CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\fzam.exe" "" "$INSTDIR\fzam.ico"
    
    ; Escribir la información de desinstalación en el registro
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\Uninstall.exe$\" /S"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$\"$INSTDIR\fzam.ico$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSION}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
SectionEnd

Section "MariaDB" SecMariaDB
    SetOutPath "$TEMP"
    File "mariadb_installer.msi"
    ExecWait 'msiexec /i "$TEMP\mariadb_installer.msi" DATADIR="$INSTDIR\BaseDatos\mariadb\data" PORT=3310 PASSWORD=Zamora2023 SERVICENAME=MariaDBFzam ADDLOCAL=ALL REMOVE=HeidiSQL /qn'
    
    ; Crear un archivo de bandera para indicar que MariaDB fue instalado
    FileOpen $0 "$INSTDIR\mariadb_installed.flag" w
    FileClose $0
SectionEnd

; Descripciones de las secciones
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} "Componentes principales de ${APPNAME}."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMariaDB} "Base de datos MariaDB (opcional)."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Sección de desinstalación
Section "Uninstall"
    ; Eliminar archivos instalados
    Delete "$INSTDIR\fzam.exe"
    Delete "$INSTDIR\fsqlf.exe"
    Delete "$INSTDIR\fzam.ico"
    Delete "$INSTDIR\factuzam_original.sql"
    Delete "$INSTDIR\factuzam_original_update_script.sql"
    Delete "$INSTDIR\Uninstall.exe"
    Delete "$INSTDIR\mariadb_installed.flag"
    
    ; Eliminar accesos directos
    Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
    RMDir "$SMPROGRAMS\${APPNAME}"
    
    ; Eliminar directorio de instalación
    RMDir "$INSTDIR"
    
    ; Eliminar entradas del registro
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
    DeleteRegKey HKLM "Software\${APPNAME}"
    
    ; Desinstalar MariaDB si fue instalado
    IfFileExists "$INSTDIR\mariadb_installed.flag" 0 +2
    ExecWait 'msiexec /x "$TEMP\mariadb_installer.msi" /qn'
SectionEnd

; Función para inicializar el instalador
Function .onInit
    ; Puedes agregar código de inicialización aquí si es necesario
FunctionEnd