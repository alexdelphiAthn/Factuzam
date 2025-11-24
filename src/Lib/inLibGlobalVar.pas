{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit inLibGlobalVar;

interface

uses Uni,
     UniDataPerfiles,
     UniDataConn,cxMemo, inMtoPrincipal2;

var
  odmPerfiles:TdmPerfiles;
  oConn      :TUniConnection;
  odmConn    :TdmConn;
  oMemoSQL   :TcxMemo;
  ofrmMto2   :TfrmOpenApp2;
  oUser      :String;
  oGroup     :String;
  orootGroup :String;
  oAppName   :String;
  oVersion   :String;
  oAll       :string;

implementation

initialization
  oAppName         := 'Fzam';
  oVersion         := '1.0.0.20231204.alpha';
  oUser            := 'No definido';
  oGroup           := 'No definido';
  orootGroup       := 'N';
  odmPerfiles      := nil;
  odmConn          := nil;
  oConn            := nil;
  oAll             := 'Todos';
end.
