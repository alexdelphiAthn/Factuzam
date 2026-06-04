{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenBusq                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lanzamiento genérico de formularios de búsqueda.                          }
{    Devuelve el dataset o el valor seleccionado por el usuario.               }
{******************************************************************************}
unit inLibGenBusq;

interface
uses  SysUtils, Variants, DB, ADODB, ExtCtrls, DBCtrls, Controls, Grids,
      Classes, COMObj, ComCtrls, ExtActns, OleCtrls, Forms, inifiles, Uni,
      DBAccess,
      SQLBuilder4D, SQLBuilder4D.Parser, SQLBuilder4D.Parser.GaSQLParser,
      System.StrUtils, DCPrijndael, dcpbase64,DCPcrypt2, System.NetEncoding,
      inLibUser, Datasnap.Provider, Datasnap.DBClient, System.DateUtils,
      MidasLib,   Datasnap.Midas,   Soap.SOAPMidas, Datasnap.Win.MidasCon,
      inLibGlobalVar, Dialogs, vcl.consts, inLibMsg, inMtoGenSearch;


type
  TBusquedaUtils = class
  public
  class function EjecutarBusqueda(const ACaption: string;
                                ADataSet: TCustomDADataSet;
                                const AName: String;
                             AParentForm: TCustomForm = nil): Boolean; overload;

  class function EjecutarBusqueda(const ACaption: string;
                                const ASql: string;
                                const CampoResultado: string;
                                out ValorDevuelto: string;
                                const AName: String;
                                AParentForm: TCustomForm = nil
                               ): Boolean; overload;
end;

implementation

class function TBusquedaUtils.EjecutarBusqueda(const ACaption: string;
                                ADataSet: TCustomDADataSet;
                                const AName: String;
                             AParentForm: TCustomForm = nil): Boolean;
var
  formulario: TfrmMtoSearch;
begin
  formulario := TfrmMtoSearch.Create(nil);
  try
    formulario.Caption := ACaption;
    formulario.Name := AName;
    if Assigned(AParentForm) then
      formulario.PopupParent := AParentForm;
    ADataSet.Connection := oConn;
    formulario.dsTablaG.DataSet := ADataSet;
    if not ADataSet.Active then
      ADataSet.Open;
    formulario.ProcesarPerfiles;
    formulario.ShowModal;
    Result := (formulario.sFicha = 'S');
  finally
    FreeAndNil(formulario);
  end;
end;

class function TBusquedaUtils.EjecutarBusqueda(const ACaption: string;
                                               const ASql: string;
                                               const CampoResultado: string;
                                               out ValorDevuelto: string;
                                               const AName: String;
                                               AParentForm: TCustomForm = nil): Boolean;
var
  formulario: TfrmMtoSearch;
  QueryTemp: TUniQuery;
begin
  Result := False;
  formulario := TfrmMtoSearch.Create(nil);
  QueryTemp := TUniQuery.Create(formulario);
  try
    formulario.Caption := ACaption;
    formulario.Name := AName;

    // --- NUEVO: Asignar el PopupParent si se ha pasado como parámetro ---
    if Assigned(AParentForm) then
      formulario.PopupParent := AParentForm;
    // --------------------------------------------------------------------

    QueryTemp.Connection := oConn;
    QueryTemp.SQL.Text := ASql;
    formulario.dsTablaG.DataSet := QueryTemp;
    QueryTemp.Open;
    formulario.ProcesarPerfiles;
    formulario.ShowModal;

    if ((formulario.sFicha = 'S') and (QueryTemp.RecordCount > 0)) then
    begin
      ValorDevuelto := QueryTemp.FieldByName(CampoResultado).AsString;
      Result := True;
    end;
  finally
    FreeAndNil(QueryTemp);
    FreeAndNil(formulario);
  end;
end;

end.
