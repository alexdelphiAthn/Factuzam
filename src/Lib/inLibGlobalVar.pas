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
     UniDataConn,cxMemo, inMtoPrincipal;
//type
//  TUpdateTotalEvent = procedure(Sender: TObject; NuevoTotal: Currency) of object;

var
  odmPerfiles:TdmPerfiles;
  oConn      :TUniConnection;
  odmConn    :TdmConn;
  oMemoSQL   :TcxMemo;
  ofrmMto2   :TfrmMtoPrincipal;
  oNomImpresoraCaja:String;
  oUser      :String;
  oGroup     :String;
  orootGroup :String;
  oEmpresa   :String;
  oAlmacen   :String;
  oCaja      :String;
  oAppName   :String;
  oVersion   :String;
  oAll       :string;

implementation

initialization
  oAppName         := 'Fzam';
  oVersion         := '1.0.0.202607051904.alpha';
  oUser            := 'No definido';
  oGroup           := 'No definido';
  oNomImpresoraCaja:='';
  orootGroup       := 'N';
  odmPerfiles      := nil;
  odmConn          := nil;
  oConn            := nil;
  oAll             := 'Todos';
end.
