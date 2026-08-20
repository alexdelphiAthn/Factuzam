{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoInventariosImportacionVcl                               }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       10/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Coordina la importacion de recuentos desde Excel o CSV. Solo conoce el    }
{    dialogo, el dataset de lineas y callbacks estrechos de persistencia y     }
{    refresco; no recibe el formulario ni el data module de inventarios.       }
{******************************************************************************}
unit inMtoInventariosImportacionVcl;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  Datasnap.DBClient,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.Forms,
  inLibInventariosAplicacionIntf;

type
  TCargarSkusImportacionInventario = reference to procedure(
    const ALista: TStringList);

  TMensajesImportacionInventario = record
    ErrorInventarioCerrado: string;
    ErrorArchivoNoExiste: string;
    ErrorSinDatos: string;
    TituloIncidencias: string;
    TextoIncidencias: string;
    FormatoIncidenciaCantidad: string;
    FormatoIncidenciaPmpNuevo: string;
    InfoLineasCsv: string;
    InfoResultado: string;
  end;

  TImportadorRecuentoInventarioVcl = class
  private
    FPropietario: TComponent;
    FDialogo: TOpenDialog;
    FLineas: TClientDataSet;
    FAsegurarFechaRecuento: TProc;
    FCargarSkusNuevos: TCargarSkusImportacionInventario;
    FRefrescar: TProc;
    FMensajes: TMensajesImportacionInventario;
    function LeerFichero(
      const AArchivo: string;
      out ALineas: TLineasImportacionInventario;
      out AIncidencias: TStringList;
      out AMensaje: string): Boolean;
    procedure ImportarLineas(
      const ALineas: TLineasImportacionInventario;
      const AMensaje: string);
  public
    constructor Create(
      APropietario: TComponent;
      ADialogo: TOpenDialog;
      ALineas: TClientDataSet;
      const AAsegurarFechaRecuento: TProc;
      const ACargarSkusNuevos: TCargarSkusImportacionInventario;
      const ARefrescar: TProc;
      const AMensajes: TMensajesImportacionInventario);
    procedure Ejecutar(APuedeEditar: Boolean);
  end;

implementation

uses
  dxSpreadSheet,
  inLibHojaCalculoDevEx,
  inLibInventarioExcel,
  inLibInventariosAplicacion,
  inMtoModalScriptLog;

constructor TImportadorRecuentoInventarioVcl.Create(
  APropietario: TComponent;
  ADialogo: TOpenDialog;
  ALineas: TClientDataSet;
  const AAsegurarFechaRecuento: TProc;
  const ACargarSkusNuevos: TCargarSkusImportacionInventario;
  const ARefrescar: TProc;
  const AMensajes: TMensajesImportacionInventario);
begin
  inherited Create;
  if APropietario = nil then
    raise EArgumentNilException.Create('APropietario');
  if ADialogo = nil then
    raise EArgumentNilException.Create('ADialogo');
  if ALineas = nil then
    raise EArgumentNilException.Create('ALineas');
  if not Assigned(AAsegurarFechaRecuento) then
    raise EArgumentNilException.Create('AAsegurarFechaRecuento');
  if not Assigned(ACargarSkusNuevos) then
    raise EArgumentNilException.Create('ACargarSkusNuevos');
  if not Assigned(ARefrescar) then
    raise EArgumentNilException.Create('ARefrescar');
  FPropietario := APropietario;
  FDialogo := ADialogo;
  FLineas := ALineas;
  FAsegurarFechaRecuento := AAsegurarFechaRecuento;
  FCargarSkusNuevos := ACargarSkusNuevos;
  FRefrescar := ARefrescar;
  FMensajes := AMensajes;
end;

function TImportadorRecuentoInventarioVcl.LeerFichero(
  const AArchivo: string;
  out ALineas: TLineasImportacionInventario;
  out AIncidencias: TStringList;
  out AMensaje: string): Boolean;
var
  Lista: TStringList;
  LineasExcel: TLineasImportadas;
  IncidenciasExcel: TIncidenciasImportacionInventario;
  Textos: TArray<string>;
  Hoja: TdxSpreadSheet;
  iLinea: Integer;
begin
  SetLength(ALineas, 0);
  AIncidencias := TStringList.Create;
  AMensaje := '';
  Lista := nil;
  SetLength(LineasExcel, 0);
  SetLength(IncidenciasExcel, 0);
  try
    if SameText(ExtractFileExt(AArchivo), '.xlsx') or
       SameText(ExtractFileExt(AArchivo), '.xls') then
    begin
      Hoja := TdxSpreadSheet.Create(nil);
      try
        Hoja.LoadFromFile(AArchivo);
        ImportarInventarioDesdeSheet(CrearLectorDevEx(Hoja),
          LineasExcel, Lista, IncidenciasExcel, AMensaje);
      finally
        FreeAndNil(Hoja);
      end;
      if Length(IncidenciasExcel) > 0 then
      begin
        AIncidencias.Add(FMensajes.TextoIncidencias);
        AIncidencias.Add('');
      end;
      for iLinea := 0 to High(IncidenciasExcel) do
        case IncidenciasExcel[iLinea].Campo of
          ciiCantidad:
            AIncidencias.Add(Format(
              FMensajes.FormatoIncidenciaCantidad,
              [IncidenciasExcel[iLinea].Fila,
               IncidenciasExcel[iLinea].Sku,
               IncidenciasExcel[iLinea].Valor]));
          ciiPmpNuevo:
            AIncidencias.Add(Format(
              FMensajes.FormatoIncidenciaPmpNuevo,
              [IncidenciasExcel[iLinea].Fila,
               IncidenciasExcel[iLinea].Sku,
               IncidenciasExcel[iLinea].Valor]));
        end;
      SetLength(ALineas, Length(LineasExcel));
      for iLinea := 0 to High(LineasExcel) do
      begin
        ALineas[iLinea].CodigoUnidad := LineasExcel[iLinea].Sku;
        ALineas[iLinea].Cantidad := LineasExcel[iLinea].Cantidad;
        ALineas[iLinea].PrecioMedioNuevo := LineasExcel[iLinea].PmpNuevo;
        ALineas[iLinea].TienePrecioMedio := LineasExcel[iLinea].TienePmp;
        ALineas[iLinea].TextoOriginal := '';
        if (Lista <> nil) and (iLinea < Lista.Count) then
          ALineas[iLinea].TextoOriginal := Lista[iLinea];
      end;
    end
    else
    begin
      Lista := TStringList.Create;
      Lista.LoadFromFile(AArchivo);
      SetLength(Textos, Lista.Count);
      for iLinea := 0 to Lista.Count - 1 do
        Textos[iLinea] := Lista[iLinea];
      ALineas := LeerLineasImportacionCsvInventario(Textos);
      AMensaje := Format(FMensajes.InfoLineasCsv, [Lista.Count]);
    end;
    Result := (AIncidencias.Count = 0) and
      (Lista <> nil) and (Lista.Count > 0);
  finally
    FreeAndNil(Lista);
  end;
end;

procedure TImportadorRecuentoInventarioVcl.ImportarLineas(
  const ALineas: TLineasImportacionInventario;
  const AMensaje: string);
var
  ListaNuevos: TStringList;
  Resumen: TResumenImportacionInventario;
begin
  Screen.Cursor := crHourGlass;
  ListaNuevos := TStringList.Create;
  try
    FLineas.DisableControls;
    try
      Resumen := AplicarImportacionInventario(
        ALineas,
        CrearOperacionesImportacionInventario(
          FLineas, ListaNuevos,
          FAsegurarFechaRecuento,
          procedure
          begin
            FLineas.ApplyUpdates(0);
          end));
    finally
      FLineas.EnableControls;
    end;
    if ListaNuevos.Count > 0 then
      FCargarSkusNuevos(ListaNuevos);
    FRefrescar;
    ShowMessage(Format(FMensajes.InfoResultado,
      [AMensaje, Resumen.Actualizadas, Resumen.Nuevas]));
  finally
    Screen.Cursor := crDefault;
    FreeAndNil(ListaNuevos);
  end;
end;

procedure TImportadorRecuentoInventarioVcl.Ejecutar(
  APuedeEditar: Boolean);
var
  Lineas: TLineasImportacionInventario;
  Incidencias: TStringList;
  Mensaje: string;
begin
  Incidencias := nil;
  FDialogo.Filter :=
    'Excel (*.xlsx)|*.xlsx|CSV (*.csv;*.txt)|*.csv;*.txt|Todos (*.*)|*.*';
  FDialogo.DefaultExt := 'xlsx';
  try
    if not APuedeEditar then
      ShowMessage(FMensajes.ErrorInventarioCerrado)
    else if FDialogo.Execute then
    begin
      if not FileExists(FDialogo.FileName) then
        ShowMessage(FMensajes.ErrorArchivoNoExiste)
      else if LeerFichero(
        FDialogo.FileName, Lineas, Incidencias, Mensaje) then
        ImportarLineas(Lineas, Mensaje)
      else if (Incidencias <> nil) and (Incidencias.Count > 0) then
        TfrmMtoModalScriptLog.MostrarTexto(
          FPropietario, FMensajes.TituloIncidencias, Incidencias)
      else if Mensaje <> '' then
        ShowMessage(Mensaje)
      else
        ShowMessage(FMensajes.ErrorSinDatos);
    end;
  finally
    FreeAndNil(Incidencias);
  end;
end;

end.
