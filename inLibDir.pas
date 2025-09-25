{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inLibDir;

interface

uses  Forms, SysUtils, Variants, ShlObj, Windows, System.IOUtils ;


const
  CSIDL_DESKTOP             = $0000; { <desktop> }
  CSIDL_INTERNET            = $0001; { Internet Explorer (icon on desktop) }
  CSIDL_PROGRAMS            = $0002; { Start Menu\Programs }
  CSIDL_CONTROLS            = $0003; { My Computer\Control Panel }
  CSIDL_PRINTERS            = $0004; { My Computer\Printers }
  CSIDL_PERSONAL            = $0005; { My Documents.  This is equivalent to
                                          CSIDL_MYDOCUMENTS in XP and above }
  CSIDL_FAVORITES           = $0006; { <user name>\Favorites }
  CSIDL_STARTUP             = $0007; { Start Menu\Programs\Startup }
  CSIDL_RECENT              = $0008; { <user name>\Recent }
  CSIDL_SENDTO              = $0009; { <user name>\SendTo }
  CSIDL_BITBUCKET           = $000a; { <desktop>\Recycle Bin }
  CSIDL_STARTMENU           = $000b; { <user name>\Start Menu }
  CSIDL_MYDOCUMENTS         = $000c; { logical "My Documents" desktop icon }
  CSIDL_MYMUSIC             = $000d; { "My Music" folder }
  CSIDL_MYVIDEO             = $000e; { "My Video" folder }
  CSIDL_DESKTOPDIRECTORY    = $0010; { <user name>\Desktop }
  CSIDL_DRIVES              = $0011; { My Computer }
  CSIDL_NETWORK             = $0012; { Network Neighborhood
                                                        (My Network Places) }
  CSIDL_NETHOOD             = $0013; { <user name>\nethood }
  CSIDL_FONTS               = $0014; { windows\fonts }
  CSIDL_TEMPLATES           = $0015; { <user name>\appdata\roaming\template
                                                                     folder }
  CSIDL_COMMON_STARTMENU    = $0016; { All Users\Start Menu }
  CSIDL_COMMON_PROGRAMS     = $0017; { All Users\Start Menu\Programs }
  CSIDL_COMMON_STARTUP      = $0018; { All Users\Startup }
  CSIDL_COMMON_DESKTOPDIRECTORY  = $0019; { All Users\Desktop }
  CSIDL_APPDATA                  = $001a; { <user name>\Application Data }
  CSIDL_PRINTHOOD                = $001b; { <user name>\PrintHood }
  CSIDL_LOCAL_APPDATA            = $001c; { <user name>\Local Settings\
                                               Application Data (non roaming) }
  CSIDL_ALTSTARTUP               = $001d; { non localized startup }
  CSIDL_COMMON_ALTSTARTUP        = $001e; { non localized common startup }
  CSIDL_COMMON_FAVORITES         = $001f; { User favourites }
  CSIDL_INTERNET_CACHE           = $0020; { temporary inter files }
  CSIDL_COOKIES                  = $0021; { <user name>\Local Settings\
                                                   Application Data\..\cookies }
  CSIDL_HISTORY                  = $0022; { <user name>\Local Settings\
                                                    Application Data\..\history}
  CSIDL_COMMON_APPDATA           = $0023; { All Users\Application Data }
  CSIDL_WINDOWS                  = $0024; { GetWindowsDirectory() }
  CSIDL_SYSTEM                   = $0025; { GetSystemDirectory() }
  CSIDL_PROGRAM_FILES            = $0026; { C:\Program Files }
  CSIDL_MYPICTURES               = $0027; { C:\Program Files\My Pictures }
  CSIDL_PROFILE                  = $0028; { USERPROFILE }
  CSIDL_SYSTEMX86                = $0029; { x86 system directory on RISC }
  CSIDL_PROGRAM_FILESX86         = $002a; { x86 C:\Program Files on RISC }
  CSIDL_PROGRAM_FILES_COMMON     = $002b; { C:\Program Files\Common }
  CSIDL_PROGRAM_FILES_COMMONX86  = $002c; { x86 C:\Program Files\Common on RISC}
  CSIDL_COMMON_TEMPLATES         = $002d; { All Users\Templates }
  CSIDL_COMMON_DOCUMENTS         = $002e; { All Users\Documents }
  CSIDL_COMMON_ADMINTOOLS        = $002f; { All Users\Start Menu\Programs\
                                                          Administrative Tools }
  CSIDL_ADMINTOOLS               = $0030; { <user name>\Start Menu\Programs\
                                                          Administrative Tools }
  CSIDL_CONNECTIONS              = $0031; { Network and Dial-up Connections }
  CSIDL_COMMON_MUSIC             = $0035; { All Users\My Music }
  CSIDL_COMMON_PICTURES          = $0036; { All Users\My Pictures }
  CSIDL_COMMON_VIDEO             = $0037; { All Users\My Video }
  CSIDL_RESOURCES                = $0038; { Resource Directory }
  CSIDL_RESOURCES_LOCALIZED      = $0039; { Localized Resource Directory }
  CSIDL_CDBURN_AREA              = $003b; { USERPROFILE\Local Settings\}

function NomApp:String;
function DirApp:String;
//function GetDirUser(sUser:String):String;
//procedure SetDirUser(sFolder: String; sUser:String);
//procedure GetDefaultUser(var sUser:String; var sDir:String);
function GetSpecialFolderPath(CSIDLFolder: Integer): string;
function GetUserFolder:String;
function GetUserDeskFolder:String;
function GetTempPath:String;
function GetLogFolder:String;

implementation

uses inLibtb;

function GetTempPath:String;
begin
  Result := TPath.GetTempPath;
end;

{http://delphiprogrammingdiary.blogspot.com/2017/08/
                                    how-to-get-windows-special-directories.html}
function GetSpecialFolderPath(CSIDLFolder: Integer): string;
var
   FilePath: array [0..MAX_PATH] of char;
begin
  SHGetFolderPath(0, CSIDLFolder, 0, 0, FilePath);
  Result := FilePath;
end;

function GetUserFolder:String;
begin
  ForceDirectories(GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)+ '\factuzam\');
  Result := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)+ '\factuzam\';
end;

function GetLogFolder:String;
begin
  ForceDirectories(GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)+
                                                      '\factuzam\log\archive\');
  ForceDirectories(GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)+ '\factuzam\log\');
  Result := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA)+ '\factuzam\log\';

end;

function GetUserDeskFolder:String;
begin
  Result := GetSpecialFolderPath(CSIDL_DESKTOPDIRECTORY);
end;

function NomApp:String;
var
  sRegion:String;
  iPos:Integer;
begin
 sRegion   := ExtractFileName( Application.ExeName );
 iPos := Pos( '.', sRegion );
 if iPos > 0 then
   Delete( sRegion, iPos, 255 );
 Result := sRegion;
end;

function DirApp:String;
begin
  Result := ExtractFilePath(Application.ExeName);
end;

//function GetDirUser(sUser:String):String;
//var
//  tfUserFile:TextFile;
//  buffer, sResul : string;
//  slUsuario:TStringArray;
//begin
//  if fileexists(PAthFichFileUser) then
//  begin
//     AssignFile(tfUserFile, PathFichFileUser) ;
//     Reset(tfUserFile);
//     sResul := '';
//     while ( (not eof(tfUserFile)) and (sResul = '') ) do
//     begin
//       ReadLn(tfUserFile, buffer) ;
//       slUsuario := AnsiSplit(buffer, ';');
//       if slUsuario[0] = sUser then
//         sResul := slUsuario[1];
//     end;
//     CloseFile(tfUserFile);
//  end
//  else sResul := '';
//
//  Result := sResul;
//end;

//procedure GetDefaultUser(var sUser:String; var sDir:String);
//var
//  tfUserFile:TextFile;
//  buffer: string;
//  slUsuario:TStringArray;
//  bDefault:boolean;
//begin
//  if fileexists(PAthFichFileUser) then
//  begin
//     bDefault := false;
//     AssignFile(tfUserFile, PathFichFileUser) ;
//     Reset(tfUserFile);
//     while ( (not eof(tfUserFile)) and (bDefault = false) ) do
//     begin
//       ReadLn(tfUserFile, buffer) ;
//       slUsuario := AnsiSplit(buffer, ';');
//       if slUsuario[2] = '*' then
//       begin
//         bDefault := true;
//         sUser := slUsuario[0];
//         sDir  := slUsuario[1];
//       end
//     end;
//     if bDefault = false then
//     begin
//       sUser := '';
//       sDir := '';
//     end;
//     CloseFile(tfUserFile);
//  end
//  else
//  begin
//   sUser:= '';
//   sDir := '';
//  end;
//end;

//procedure SetDirUser(sFolder: String; sUser:String);
//var
//  tfUserF:TextFile;
//  sResul, buffer:String;
//  slUsuario:TStringArray;
//  sLines:TStringArray;
//  i:Integer;
//begin
//  AssignFile(tfUserF, PathFichFileUser) ;
//  if fileexists(PathFichFileUser) then
//  begin
//     Reset(tfUserF);
//     i:=0;
//     while ( (not eof(tfUserF)) and (sResul = '') ) do
//     begin
//       ReadLn(tfUserF, buffer) ;
//       slUsuario := AnsiSplit(buffer, ';');
//       if slUsuario[0] = sUser then
//       begin
//         sResul := slUsuario[1];
//       end
//       else
//         begin
//           sLines[i]:= buffer;
//           i:= i + 1;
//         end;
//     end;
//     CloseFile(tfUserF);
//  end
//  else
//    sResul := '';
//  if sResul <> '' then
//  begin
//    DeleteFile(PWideChar(PathFichFileUser));
//    if Length(sLines) > 0 then
//    begin
//       Rewrite(tfUserF);
//       for i:= 0 to Length(sLines) do
//         writeln(tfUserF, sLines[i]);
//       CloseFile(tfUserF);
//    end;
//  end;
//  Rewrite(tfUserF);
//  writeln(tfUserF, sUser + ';' + sFolder + ';' + '*');
//  CloseFile(tfUserF);
//end;

end.
