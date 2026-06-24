; Empaquetador DEMO autoinstalable de Factuzam.
; Compilar desde esta carpeta con:
;   makensis factuzam_demo_autoinstalable.nsi
; O desde Publicador, pasando VERSION con /DVERSION=...
;
; Ficheros esperados:
;   ..\Win64\Release\fzam.exe
;   ..\factuzam.ico
;   ..\factuzam_original.sql
;   .\mariadb_installer.msi

Unicode True
RequestExecutionLevel admin

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

!cd "${__FILEDIR__}"

!define APPNAME "Factuzam DEMO"
!define COMPANYNAME "Factuzam"
!ifndef VERSION
  !define VERSION "1.0.15.202606240100.alpha"
!endif
!define DBNAME "factuzam"
!define DBPORT "3310"
!define DBPASS "Zamora2023"
!define DBPASS_EN "2qJFaDfegP/9y6RDno1FRg=="
!define USERPASS_EN "q7heHfD7ENowuvRQhW56Og=="
!define SERVICENAME "MariaDBFactuzamDemo"
!define INI_DEMO "fzam_demo.ini"
!define MARIADB_MSI "mariadb_installer.msi"
!define LICENCIA_DEMO "licencia_demo.txt"

!if /FileExists "${MARIADB_MSI}"
  !define HAY_MARIADB_MSI
!else
  !warning "No se encontro ${MARIADB_MSI}. El instalador compilara, pero abortara al instalar MariaDB."
!endif

Name "${APPNAME}"
OutFile "Factuzam_DEMO_${VERSION}.exe"
InstallDir "$PROGRAMFILES64\Factuzam DEMO"
InstallDirRegKey HKLM "Software\FactuzamDemo" "InstallDir"

!define MUI_ABORTWARNING
!define MUI_ICON "..\factuzam.ico"
!define MUI_UNICON "..\factuzam.ico"
!define MUI_WELCOMEPAGE_TITLE "Instalador de ${APPNAME}"
!define MUI_WELCOMEPAGE_TEXT "Este asistente instalara Factuzam DEMO, MariaDB local y una base de datos de demostracion."
!define MUI_FINISHPAGE_RUN "$INSTDIR\fzam.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS "${INI_DEMO}"
!define MUI_FINISHPAGE_RUN_TEXT "Abrir Factuzam DEMO"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${LICENCIA_DEMO}"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Spanish"

Var CodigoSalida

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "Factuzam DEMO se empaqueta con el ejecutable Win64 y requiere Windows de 64 bits."
    Abort
  ${EndIf}
  SetRegView 64
FunctionEnd

Function un.onInit
  SetRegView 64
FunctionEnd

Function EsperarMariaDB
  StrCpy $R0 0
  ${Do}
    IntOp $R0 $R0 + 1
    nsExec::ExecToStack '"$INSTDIR\BaseDatos\mariadb\bin\mysqladmin.exe" --protocol=tcp --host=127.0.0.1 --port=${DBPORT} --user=root --password=${DBPASS} ping'
    Pop $CodigoSalida
    Pop $R1
    ${If} $CodigoSalida == 0
      Return
    ${EndIf}
    Sleep 2000
  ${LoopUntil} $R0 >= 30
  Abort "MariaDB no responde en 127.0.0.1:${DBPORT}. Revise el servicio ${SERVICENAME}."
FunctionEnd

Function CrearBaseDatosDemo
  DetailPrint "Creando base de datos ${DBNAME}..."
  nsExec::ExecToLog '"$INSTDIR\BaseDatos\mariadb\bin\mysql.exe" --protocol=tcp --host=127.0.0.1 --port=${DBPORT} --user=root --password=${DBPASS} --default-character-set=utf8mb4 --execute="DROP DATABASE IF EXISTS ${DBNAME}; CREATE DATABASE ${DBNAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci;"'
  Pop $CodigoSalida
  ${If} $CodigoSalida != 0
    Abort "No se pudo crear la base de datos demo. Codigo: $CodigoSalida"
  ${EndIf}
FunctionEnd

Function ImportarBaseDatosDemo
  DetailPrint "Importando datos de demostracion..."
  nsExec::ExecToLog '"$SYSDIR\cmd.exe" /C ""$INSTDIR\BaseDatos\mariadb\bin\mysql.exe" --protocol=tcp --host=127.0.0.1 --port=${DBPORT} --user=root --password=${DBPASS} --default-character-set=utf8mb4 ${DBNAME} < "$INSTDIR\bbdd\factuzam_demo.sql""'
  Pop $CodigoSalida
  ${If} $CodigoSalida != 0
    Abort "No se pudo importar la base de datos demo. Codigo: $CodigoSalida"
  ${EndIf}
FunctionEnd

Function EscribirIniDemo
  SetShellVarContext current
  CreateDirectory "$LOCALAPPDATA\factuzam"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "ConnData" "HostName" "127.0.0.1"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "ConnData" "Database" "${DBNAME}"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "ConnData" "User" "root"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "ConnData" "Puerto" "${DBPORT}"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "ConnData" "PasswordEn" "${DBPASS_EN}"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "UserInfo" "RememberUser" "Yes"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "UserInfo" "NomUser" "Administrador"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "UserInfo" "RememberPassword" "Yes"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "UserInfo" "PasswordEn" "${USERPASS_EN}"
  WriteINIStr "$LOCALAPPDATA\factuzam\${INI_DEMO}" "UserInfo" "AutoLogin" "Yes"
FunctionEnd

Section "Factuzam DEMO" SecAplicacion
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "..\Win64\Release\fzam.exe"
  File "..\factuzam.ico"
  File "${LICENCIA_DEMO}"

  SetOutPath "$INSTDIR\bbdd"
  File /oname=factuzam_demo.sql "..\factuzam_original.sql"

  SetOutPath "$INSTDIR\instalador"
  !ifdef HAY_MARIADB_MSI
    File /oname=mariadb_installer.msi "${MARIADB_MSI}"
  !endif

  CreateDirectory "$SMPROGRAMS\Factuzam DEMO"
  CreateShortCut "$SMPROGRAMS\Factuzam DEMO\Factuzam DEMO.lnk" "$INSTDIR\fzam.exe" "${INI_DEMO}" "$INSTDIR\factuzam.ico"
  CreateShortCut "$DESKTOP\Factuzam DEMO.lnk" "$INSTDIR\fzam.exe" "${INI_DEMO}" "$INSTDIR\factuzam.ico"

  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\FactuzamDemo" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "QuietUninstallString" "$\"$INSTDIR\Uninstall.exe$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "DisplayIcon" "$INSTDIR\factuzam.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "Publisher" "${COMPANYNAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "DisplayVersion" "${VERSION}"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo" "NoRepair" 1
SectionEnd

Section "MariaDB y BBDD DEMO" SecMariaDB
  SectionIn RO
  !ifndef HAY_MARIADB_MSI
    Abort "Falta empaquetador\${MARIADB_MSI}. Copie el MSI de MariaDB junto a este script y recompile."
  !endif

  IfFileExists "$INSTDIR\instalador\mariadb_installer.msi" +2 0
    Abort "No se encontro $INSTDIR\instalador\mariadb_installer.msi."

  DetailPrint "Instalando MariaDB como servicio ${SERVICENAME}..."
  ExecWait '"$SYSDIR\msiexec.exe" /i "$INSTDIR\instalador\mariadb_installer.msi" INSTALLDIR="$INSTDIR\BaseDatos\mariadb" DATADIR="$INSTDIR\BaseDatos\mariadb\data" PORT=${DBPORT} PASSWORD=${DBPASS} SERVICENAME=${SERVICENAME} ADDLOCAL=ALL REMOVE=HeidiSQL /qn' $CodigoSalida
  ${If} $CodigoSalida != 0
    ${If} $CodigoSalida != 3010
      Abort "No se pudo instalar MariaDB. Codigo MSI: $CodigoSalida"
    ${EndIf}
  ${EndIf}

  IfFileExists "$INSTDIR\BaseDatos\mariadb\bin\mysql.exe" +2 0
    Abort "No se encontro mysql.exe en $INSTDIR\BaseDatos\mariadb\bin."

  Call EsperarMariaDB
  Call CrearBaseDatosDemo
  Call ImportarBaseDatosDemo
  Call EscribirIniDemo
SectionEnd

Section "Uninstall"
  SetShellVarContext current

  nsExec::ExecToLog 'sc stop ${SERVICENAME}'

  IfFileExists "$INSTDIR\instalador\mariadb_installer.msi" 0 +3
    ExecWait '"$SYSDIR\msiexec.exe" /x "$INSTDIR\instalador\mariadb_installer.msi" /qn' $CodigoSalida

  nsExec::ExecToLog 'sc delete ${SERVICENAME}'

  Delete "$DESKTOP\Factuzam DEMO.lnk"
  Delete "$SMPROGRAMS\Factuzam DEMO\Factuzam DEMO.lnk"
  RMDir "$SMPROGRAMS\Factuzam DEMO"

  Delete "$LOCALAPPDATA\factuzam\${INI_DEMO}"
  RMDir "$LOCALAPPDATA\factuzam"

  Delete "$INSTDIR\fzam.exe"
  Delete "$INSTDIR\factuzam.ico"
  Delete "$INSTDIR\${LICENCIA_DEMO}"
  Delete "$INSTDIR\bbdd\factuzam_demo.sql"
  Delete "$INSTDIR\instalador\mariadb_installer.msi"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR\bbdd"
  RMDir "$INSTDIR\instalador"
  RMDir /r "$INSTDIR\BaseDatos"
  RMDir "$INSTDIR"

  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FactuzamDemo"
  DeleteRegKey HKLM "Software\FactuzamDemo"
SectionEnd
