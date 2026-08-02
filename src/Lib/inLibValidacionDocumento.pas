{******************************************************************************}
{                                                                              }
{  Módulo:       inLibValidacionDocumento                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validación y persistencia común para documentos de compra y venta.        }
{******************************************************************************}
unit inLibValidacionDocumento;

interface

uses
  Data.DB, Uni, inLibDocumentoIntf, inLibArticulosValidadorIntf;

type
  TAccionCabeceraDocumento = procedure of object;
  TAccionCabeceraCompra = TAccionCabeceraDocumento;
  TValidadorPivoteCompra = function(
    var AMensaje: string): Boolean of object;

procedure AsegurarCabeceraPersistidaDocumento(
  ACabecera, ALineas: TDataSet;
  const AConfiguracion: TConfiguracionDocumento;
  AValidarCabecera: TAccionCabeceraDocumento);
function LineaCompraTieneArticulo(ADataSet: TDataSet;
  const AConfiguracion: TConfiguracionDocumento): Boolean;
function LineaCompraVacia(ADataSet: TDataSet;
  const AConfiguracion: TConfiguracionDocumento): Boolean;
function LineaCompraTieneSistemaTallas(ADataSet: TDataSet;
  const AConfiguracion: TConfiguracionDocumento): Boolean;
function LineasSinSkuRequerido(
  const AValidador: IArticulosValidador;
  ALineas: TDataSet;
  const ASufijo: string): string;
procedure AsegurarCabeceraPersistidaCompra(
  ACabecera, ALineas: TDataSet;
  const AConfiguracion: TConfiguracionDocumento;
  AValidarCabecera: TAccionCabeceraCompra);
function SqlArticulosSinSistemaTallasCompra(
  const AConfiguracion: TConfiguracionDocumento): string;
function PuedeActivarTallasHorizontalCompra(
  ACabecera, ALineas: TDataSet;
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionDocumento;
  AAsegurarCabecera: TAccionCabeceraCompra;
  AValidarPivote: TValidadorPivoteCompra;
  var AMensaje: string): Boolean;

implementation

uses
  System.Classes, System.SysUtils, inLibMsgArticulos,
  inLibMsgCompras, inLibMsgComun;

function ValorTextoLinea(ADataSet: TDataSet;
  const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if Assigned(oCampo) then
      Result := Trim(oCampo.AsString);
  end;
end;

function LineaDocumentoVacia(ADataSet: TDataSet;
  const AConfiguracion: TConfiguracionDocumento): Boolean;
begin
  Result :=
    (ValorTextoLinea(
      ADataSet, AConfiguracion.CampoArticuloLinea) = '') and
    (ValorTextoLinea(
      ADataSet, AConfiguracion.CampoProductoLinea) = '');
end;

function LineaCompraTieneArticulo(ADataSet: TDataSet;
  const AConfiguracion: TConfiguracionDocumento): Boolean;
begin
  Result :=
    (ValorTextoLinea(
      ADataSet, AConfiguracion.CampoArticuloLinea) <> '') or
    (ValorTextoLinea(
      ADataSet, AConfiguracion.CampoUnidadLinea) <> '');
end;

function LineaCompraVacia(ADataSet: TDataSet;
  const AConfiguracion: TConfiguracionDocumento): Boolean;
begin
  Result := not LineaCompraTieneArticulo(
    ADataSet, AConfiguracion);
end;

function LineaCompraTieneSistemaTallas(ADataSet: TDataSet;
  const AConfiguracion: TConfiguracionDocumento): Boolean;
var
  oCampo: TField;
begin
  Result := False;
  if Assigned(ADataSet) then
  begin
    oCampo := ADataSet.FindField(AConfiguracion.CampoPivoteLinea);
    if Assigned(oCampo) then
      Result := (not oCampo.IsNull) and (oCampo.AsInteger > 0);
  end;
end;

function LineasSinSkuRequerido(
  const AValidador: IArticulosValidador;
  ALineas: TDataSet;
  const ASufijo: string): string;
var
  Cache: TStringList;
  Marcador: TBookmark;
  Articulo: string;
  TieneSku: string;
  CampoArticulo: TField;
  CampoSku: TField;
  CampoLinea: TField;
begin
  Result := '';
  if Assigned(AValidador) and
     Assigned(ALineas) and
     ALineas.Active then
  begin
    CampoArticulo := ALineas.FindField('CODIGO_ART_' + ASufijo);
    CampoSku := ALineas.FindField('CODIGO_UNIDAD_' + ASufijo);
    CampoLinea := ALineas.FindField('LINEA_' + ASufijo);
    if Assigned(CampoArticulo) and
       Assigned(CampoSku) and
       Assigned(CampoLinea) and
       (not ALineas.IsEmpty) then
    begin
      Cache := TStringList.Create;
      Marcador := ALineas.GetBookmark;
      ALineas.DisableControls;
      try
        ALineas.First;
        while not ALineas.Eof do
        begin
          Articulo := Trim(CampoArticulo.AsString);
          if (Articulo <> '') and (Trim(CampoSku.AsString) = '') then
          begin
            TieneSku := Cache.Values[Articulo];
            if TieneSku = '' then
            begin
              if AValidador.TieneSkuActivo(Articulo) then
                TieneSku := 'S';
              if TieneSku = '' then
                TieneSku := 'N';
              Cache.Values[Articulo] := TieneSku;
            end;
            if TieneSku = 'S' then
            begin
              if Result <> '' then
                Result := Result + ', ';
              Result := Result + CampoLinea.AsString;
            end;
          end;
          ALineas.Next;
        end;
        if ALineas.BookmarkValid(Marcador) then
          ALineas.GotoBookmark(Marcador);
      finally
        ALineas.EnableControls;
        ALineas.FreeBookmark(Marcador);
        FreeAndNil(Cache);
      end;
    end;
  end;
end;

procedure SincronizarCabeceraEnLineaDocumento(
  ACabecera, ALineas: TDataSet;
  const AConfiguracion: TConfiguracionDocumento);
var
  oCampo: TField;
begin
  if Assigned(ALineas) and ALineas.Active and
     (ALineas.State in dsEditModes) then
  begin
    oCampo := ALineas.FindField(
      AConfiguracion.CampoNumeroLinea);
    if Assigned(oCampo) then
      oCampo.AsString := ACabecera.FieldByName(
        AConfiguracion.CampoNumeroCabecera).AsString;
    oCampo := ALineas.FindField(
      AConfiguracion.CampoSerieLinea);
    if Assigned(oCampo) then
      oCampo.AsString := ACabecera.FieldByName(
        AConfiguracion.CampoSerieCabecera).AsString;
  end;
end;

procedure AsegurarCabeceraPersistidaDocumento(
  ACabecera, ALineas: TDataSet;
  const AConfiguracion: TConfiguracionDocumento;
  AValidarCabecera: TAccionCabeceraDocumento);
var
  bCancelarLinea: Boolean;
  bDebePublicar: Boolean;
  bRecrearLinea: Boolean;
  oCampoEstado: TField;
  sNumero: string;
begin
  if (ACabecera = nil) or (not ACabecera.Active) or
     (ACabecera.IsEmpty and
      not (ACabecera.State in dsEditModes)) then
    raise Exception.Create(
      AConfiguracion.MensajeCabeceraNoDisponible);
  if Assigned(AValidarCabecera) then
    AValidarCabecera;
  sNumero := Trim(ACabecera.FieldByName(
    AConfiguracion.CampoNumeroCabecera).AsString);
  bDebePublicar := (ACabecera.State in dsEditModes) or
    (sNumero = '') or (sNumero = '0');
  bRecrearLinea := False;
  if bDebePublicar then
  begin
    bCancelarLinea := Assigned(ALineas) and ALineas.Active and
      (ALineas.State = dsInsert) and
      LineaDocumentoVacia(ALineas, AConfiguracion);
    if bCancelarLinea and
       AConfiguracion.CancelarLineaSoloSinNumero then
      bCancelarLinea := (sNumero = '') or (sNumero = '0');
    if bCancelarLinea then
    begin
      ALineas.Cancel;
      bRecrearLinea := AConfiguracion.RecrearLineaVacia;
    end;
    if not (ACabecera.State in dsEditModes) then
      ACabecera.Edit;
    if AConfiguracion.CampoEstadoCabecera <> '' then
    begin
      oCampoEstado := ACabecera.FindField(
        AConfiguracion.CampoEstadoCabecera);
      if Assigned(oCampoEstado) and
         (Trim(oCampoEstado.AsString) = '') then
        oCampoEstado.AsString :=
          AConfiguracion.ValorEstadoCabecera;
    end;
    ACabecera.Post;
  end;
  SincronizarCabeceraEnLineaDocumento(
    ACabecera, ALineas, AConfiguracion);
  if Assigned(ALineas) and ALineas.Active and
     (not (ALineas.State in dsEditModes)) then
  begin
    ALineas.Close;
    ALineas.Open;
  end;
  if bRecrearLinea and Assigned(ALineas) and ALineas.Active and
     (not (ALineas.State in dsEditModes)) then
    ALineas.Append;
end;

procedure AsegurarCabeceraPersistidaCompra(
  ACabecera, ALineas: TDataSet;
  const AConfiguracion: TConfiguracionDocumento;
  AValidarCabecera: TAccionCabeceraCompra);
begin
  AsegurarCabeceraPersistidaDocumento(
    ACabecera, ALineas, AConfiguracion, AValidarCabecera);
end;

function SqlArticulosSinSistemaTallasCompra(
  const AConfiguracion: TConfiguracionDocumento): string;
begin
  Result :=
    'SELECT DISTINCT L.' + AConfiguracion.CampoArticuloLinea +
    ' AS ART ' +
    '  FROM ' + AConfiguracion.TablaLineas + ' L ' +
    ' WHERE L.' + AConfiguracion.CampoSerieLinea + ' = :serie ' +
    '   AND L.' + AConfiguracion.CampoNumeroLinea + ' = :numero ' +
    '   AND COALESCE(TRIM(L.' +
    AConfiguracion.CampoArticuloLinea + '), '''') <> '''' ' +
    '   AND (L.' + AConfiguracion.CampoPivoteLinea + ' IS NULL ' +
    '        OR L.' + AConfiguracion.CampoPivoteLinea + ' = 0) ' +
    ' ORDER BY ART';
end;

function PuedeActivarTallasHorizontalCompra(
  ACabecera, ALineas: TDataSet;
  AConexion: TUniConnection;
  const AConfiguracion: TConfiguracionDocumento;
  AAsegurarCabecera: TAccionCabeceraCompra;
  AValidarPivote: TValidadorPivoteCompra;
  var AMensaje: string): Boolean;
var
  oConsulta: TUniQuery;
  oIncidencias: TStringList;
  sNumero: string;
  sSerie: string;
begin
  Result := False;
  AMensaje := '';
  if (ACabecera = nil) or (not ACabecera.Active) or
     ACabecera.IsEmpty then
    AMensaje := Format(SErrorCrearSeleccionarDocumentoAntesTallas,
      [AConfiguracion.DocumentoConArticulo])
  else
  begin
    if Assigned(ALineas) and ALineas.Active and
       (ALineas.State in dsEditModes) then
    begin
      if LineaCompraTieneArticulo(ALineas, AConfiguracion) and
         (not LineaCompraTieneSistemaTallas(
           ALineas, AConfiguracion)) then
        AMensaje := SErrorArticuloCursoSinSistemaTallas
      else if LineaCompraTieneArticulo(
        ALineas, AConfiguracion) then
      begin
        AAsegurarCabecera;
        if ALineas.State in dsEditModes then
          ALineas.Post;
      end
      else if ACabecera.State = dsInsert then
        AMensaje := SErrorAltaSeleccionarArticuloConTallas;
    end
    else if ACabecera.State = dsInsert then
      AMensaje := SErrorAltaSeleccionarArticuloConTallas;
    if AMensaje = '' then
    begin
      sNumero := Trim(ACabecera.FieldByName(
        AConfiguracion.CampoNumeroCabecera).AsString);
      if (sNumero = '') or (sNumero = '0') then
        AAsegurarCabecera;
      sSerie := Trim(ACabecera.FieldByName(
        AConfiguracion.CampoSerieCabecera).AsString);
      sNumero := Trim(ACabecera.FieldByName(
        AConfiguracion.CampoNumeroCabecera).AsString);
      oIncidencias := TStringList.Create;
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          SqlArticulosSinSistemaTallasCompra(AConfiguracion);
        oConsulta.ParamByName('serie').AsString := sSerie;
        oConsulta.ParamByName('numero').AsString := sNumero;
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          oIncidencias.Add(Format(SErrorArticuloSinSistemaTallasCompra,
            [oConsulta.FieldByName('ART').AsString]));
          oConsulta.Next;
        end;
        if oIncidencias.Count > 0 then
          AMensaje := Format(SErrorActivarTallasHorizontalesCompra,
            [oIncidencias.Text])
        else
          Result := AValidarPivote(AMensaje);
      finally
        FreeAndNil(oConsulta);
        FreeAndNil(oIncidencias);
      end;
    end;
  end;
end;

end.
