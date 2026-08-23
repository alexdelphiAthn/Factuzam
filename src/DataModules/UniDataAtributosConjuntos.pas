{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAtributosConjuntos                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de conjuntos de atributos.                                    }
{    Mantiene fza_atributos_conjuntos y su detalle de valores asociados a      }
{    artículos.                                                                }
{******************************************************************************}
unit UniDataAtributosConjuntos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser;

type
  TdmAtributosConjuntos = class(TdmBase)
    unqryConjuntoDetalle: TUniQuery;
    dsConjuntoDetalle: TDataSource;
    unqryValoresLookup: TUniQuery;
    dsValoresLookup: TDataSource;
    unqryArticulosConjunto: TUniQuery;
    dsArticulosConjunto: TDataSource;
    unqryVariacionesLookup: TUniQuery;
    dsVariacionesLookup: TDataSource;
    unqryAtributosLookup: TUniQuery;
    dsAtributosLookup: TDataSource;
    unqryAtributosBasicosLookup: TUniQuery;
    dsAtributosBasicosLookup: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryConjuntoDetalleAfterInsert(DataSet: TDataSet);
    procedure unqryConjuntoDetalleBeforePost(DataSet: TDataSet);
    procedure unqryTablaGConjuntosBeforePost(DataSet: TDataSet);
  private
    function BuscarValor(const AIdAtributo, ATexto: string;
      out AIdValor: Integer; out AValor: string;
      out AActivo: Boolean): Boolean;
    function DetallesPertenecenAtributo(AIdConjunto: Integer;
      const AIdAtributo: string): Boolean;
    function ValorPerteneceAtributo(AIdValor: Integer;
      const AIdAtributo: string): Boolean;
    function ValorRepetidoEnConjunto(AIdConjunto,
      AIdValor, AIdAnterior: Integer): Boolean;
  public
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    function AsegurarValor(const AIdAtributo, ATexto: string;
      AOrden: Integer; out AValor: string): Integer;
    function BuscarValorActivo(const AIdAtributo, ATexto: string;
      out AIdValor: Integer; out AValor: string): Boolean;
    function CalcularSiguienteOrdenValor(AIdConjunto: Integer;
      const AIdAtributo: string): Integer;
    procedure FiltrarValoresLookup(const AIdAtributo: string);
  end;

implementation

uses
  System.Diagnostics, System.Variants,
  UniDataAperturaConsultas, inLibMsgArticulos;

const
  SQL_BUSCAR_VALOR =
    'SELECT ID_AV, AV, ESACTIVO_AV ' +
    '  FROM fza_atributos_valores ' +
    ' WHERE ID_VA_AV = :IDVA ' +
    '   AND TRIM(UPPER(AV)) = UPPER(TRIM(:VALOR)) ' +
    ' ORDER BY (ESACTIVO_AV = ''S'') DESC, ID_AV ' +
    ' LIMIT 1';
  SQL_REACTIVAR_VALOR =
    'UPDATE fza_atributos_valores ' +
    '   SET ESACTIVO_AV = ''S'', ORDEN_AV = :ORDEN, ' +
    '       INSTANTE_MODIF = NOW(), ' +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_AV = :ID';
  SQL_INSERTAR_VALOR =
    'INSERT INTO fza_atributos_valores ' +
    '  (ID_VA_AV, AV, ORDEN_AV, ESACTIVO_AV, INSTANTE_ALTA, ' +
    '   INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:IDVA, :VALOR, :ORDEN, ''S'', NOW(), NOW(), ' +
    '        :USUARIO, :USUARIO)';
  SQL_ULTIMO_ID_VALOR =
    'SELECT LAST_INSERT_ID() AS ID';
  SQL_SIGUIENTE_ORDEN_CONJUNTO =
    'SELECT (FLOOR(COALESCE(MAX(ORDEN_ACD), 0) / 10) + 1) * 10 ' +
    '       AS SIGUIENTE_ORDEN ' +
    '  FROM fza_atributos_conjuntos_det ' +
    ' WHERE ID_AC_ACD = :IDCONJUNTO';
  SQL_SIGUIENTE_ORDEN_ATRIBUTO =
    'SELECT (FLOOR(COALESCE(MAX(ORDEN_AV), 0) / 10) + 1) * 10 ' +
    '       AS SIGUIENTE_ORDEN ' +
    '  FROM fza_atributos_valores ' +
    ' WHERE ID_VA_AV = :IDVA';
  SQL_VALOR_PERTENECE_ATRIBUTO =
    'SELECT 1 ' +
    '  FROM fza_atributos_valores ' +
    ' WHERE ID_AV = :ID ' +
    '   AND ID_VA_AV = :IDVA ' +
    ' LIMIT 1';
  SQL_DETALLES_FUERA_ATRIBUTO =
    'SELECT 1 ' +
    '  FROM fza_atributos_conjuntos_det d ' +
    '  JOIN fza_atributos_valores v ON v.ID_AV = d.ID_AV_ACD ' +
    ' WHERE d.ID_AC_ACD = :IDCONJUNTO ' +
    '   AND (:IDVA = '''' OR v.ID_VA_AV <> :IDVA) ' +
    ' LIMIT 1';
  SQL_VALOR_REPETIDO_CONJUNTO =
    'SELECT 1 ' +
    '  FROM fza_atributos_conjuntos_det d ' +
    '  JOIN fza_atributos_valores existente ' +
    '    ON existente.ID_AV = d.ID_AV_ACD ' +
    '  JOIN fza_atributos_valores nuevo ON nuevo.ID_AV = :IDVALOR ' +
    ' WHERE d.ID_AC_ACD = :IDCONJUNTO ' +
    '   AND (:IDANTERIOR = 0 OR d.ID_AV_ACD <> :IDANTERIOR) ' +
    '   AND existente.ID_VA_AV = nuevo.ID_VA_AV ' +
    '   AND TRIM(UPPER(existente.AV)) = TRIM(UPPER(nuevo.AV)) ' +
    ' LIMIT 1';

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmAtributosConjuntos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  // Solo Connection. Los .Open estan en AbrirDetalles y los
  // MasterSource en AsignarMaestroCabecera.
  unqryValoresLookup.Connection := ConexionPrincipal;
  unqryVariacionesLookup.Connection := ConexionPrincipal;
  unqryAtributosLookup.Connection := ConexionPrincipal;
  unqryAtributosBasicosLookup.Connection := ConexionPrincipal;
  unqryConjuntoDetalle.Connection := ConexionPrincipal;
  unqryArticulosConjunto.Connection := ConexionPrincipal;
end;

procedure TdmAtributosConjuntos.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryConjuntoDetalle.MasterSource := ADataSource;
  unqryArticulosConjunto.MasterSource := ADataSource;
end;

function TdmAtributosConjuntos.BuscarValor(
  const AIdAtributo, ATexto: string;
  out AIdValor: Integer; out AValor: string;
  out AActivo: Boolean): Boolean;
var
  oConsulta: TUniQuery;
begin
  AIdValor := 0;
  AValor := '';
  AActivo := False;
  Result := (Trim(AIdAtributo) <> '') and (Trim(ATexto) <> '');
  if Result then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      oConsulta.SQL.Text := SQL_BUSCAR_VALOR;
      oConsulta.ParamByName('IDVA').AsString := Trim(AIdAtributo);
      oConsulta.ParamByName('VALOR').AsString := Trim(ATexto);
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
      if Result then
      begin
        AIdValor := oConsulta.FieldByName('ID_AV').AsInteger;
        AValor := oConsulta.FieldByName('AV').AsString;
        AActivo := SameText(
          oConsulta.FieldByName('ESACTIVO_AV').AsString, 'S');
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TdmAtributosConjuntos.BuscarValorActivo(
  const AIdAtributo, ATexto: string;
  out AIdValor: Integer; out AValor: string): Boolean;
var
  bActivo: Boolean;
begin
  Result := BuscarValor(
    AIdAtributo, ATexto, AIdValor, AValor, bActivo) and bActivo;
end;

function TdmAtributosConjuntos.AsegurarValor(
  const AIdAtributo, ATexto: string;
  AOrden: Integer; out AValor: string): Integer;
var
  bActivo: Boolean;
  iIdValor: Integer;
  oConsulta: TUniQuery;
  sTexto: string;
  sValorEncontrado: string;
begin
  Result := 0;
  sTexto := Trim(ATexto);
  AValor := sTexto;
  if (Trim(AIdAtributo) <> '') and (sTexto <> '') then
  begin
    if BuscarValor(
         AIdAtributo, sTexto, iIdValor, sValorEncontrado, bActivo) then
    begin
      Result := iIdValor;
      AValor := sValorEncontrado;
      if not bActivo then
      begin
        oConsulta := TUniQuery.Create(nil);
        try
          oConsulta.Connection := ConexionPrincipal;
          oConsulta.SQL.Text := SQL_REACTIVAR_VALOR;
          oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
          oConsulta.ParamByName('USUARIO').AsString :=
            IdentidadSesion.Usuario;
          oConsulta.ParamByName('ID').AsInteger := Result;
          oConsulta.ExecSQL;
        finally
          FreeAndNil(oConsulta);
        end;
      end;
    end
    else
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := ConexionPrincipal;
        oConsulta.SQL.Text := SQL_INSERTAR_VALOR;
        oConsulta.ParamByName('IDVA').AsString := Trim(AIdAtributo);
        oConsulta.ParamByName('VALOR').AsString := sTexto;
        oConsulta.ParamByName('ORDEN').AsInteger := AOrden;
        oConsulta.ParamByName('USUARIO').AsString :=
          IdentidadSesion.Usuario;
        oConsulta.ExecSQL;
        oConsulta.SQL.Text := SQL_ULTIMO_ID_VALOR;
        oConsulta.Open;
        Result := oConsulta.FieldByName('ID').AsInteger;
      finally
        FreeAndNil(oConsulta);
      end;
    end;
  end;
end;

function TdmAtributosConjuntos.DetallesPertenecenAtributo(
  AIdConjunto: Integer; const AIdAtributo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := True;
  if AIdConjunto > 0 then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      oConsulta.SQL.Text := SQL_DETALLES_FUERA_ATRIBUTO;
      oConsulta.ParamByName('IDCONJUNTO').AsInteger := AIdConjunto;
      oConsulta.ParamByName('IDVA').AsString := Trim(AIdAtributo);
      oConsulta.Open;
      Result := oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TdmAtributosConjuntos.ValorPerteneceAtributo(
  AIdValor: Integer; const AIdAtributo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if (AIdValor > 0) and (Trim(AIdAtributo) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      oConsulta.SQL.Text := SQL_VALOR_PERTENECE_ATRIBUTO;
      oConsulta.ParamByName('ID').AsInteger := AIdValor;
      oConsulta.ParamByName('IDVA').AsString := Trim(AIdAtributo);
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TdmAtributosConjuntos.ValorRepetidoEnConjunto(
  AIdConjunto, AIdValor, AIdAnterior: Integer): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if (AIdConjunto > 0) and (AIdValor > 0) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      oConsulta.SQL.Text := SQL_VALOR_REPETIDO_CONJUNTO;
      oConsulta.ParamByName('IDCONJUNTO').AsInteger := AIdConjunto;
      oConsulta.ParamByName('IDVALOR').AsInteger := AIdValor;
      oConsulta.ParamByName('IDANTERIOR').AsInteger := AIdAnterior;
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TdmAtributosConjuntos.CalcularSiguienteOrdenValor(
  AIdConjunto: Integer; const AIdAtributo: string): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 10;
  if (AIdConjunto > 0) or (Trim(AIdAtributo) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionPrincipal;
      if AIdConjunto > 0 then
      begin
        oConsulta.SQL.Text := SQL_SIGUIENTE_ORDEN_CONJUNTO;
        oConsulta.ParamByName('IDCONJUNTO').AsInteger := AIdConjunto;
      end
      else
      begin
        oConsulta.SQL.Text := SQL_SIGUIENTE_ORDEN_ATRIBUTO;
        oConsulta.ParamByName('IDVA').AsString := Trim(AIdAtributo);
      end;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('SIGUIENTE_ORDEN').AsInteger;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TdmAtributosConjuntos.FiltrarValoresLookup(
  const AIdAtributo: string);
begin
  if unqryValoresLookup.Active then
  begin
    unqryValoresLookup.Filtered := False;
    unqryValoresLookup.Filter := '';
    if Trim(AIdAtributo) <> '' then
    begin
      unqryValoresLookup.Filter :=
        'ID_VA_AV = ' + QuotedStr(Trim(AIdAtributo));
      unqryValoresLookup.Filtered := True;
    end;
  end;
end;

procedure TdmAtributosConjuntos.AbrirDetalles;
const
  TAG = 'AtributosConjuntos.AbrirDetalles';
var sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConsultaConTiempo(
    unqryValoresLookup, TAG, 'unqryValoresLookup', RegistroLog);
  if unqryTablaG.Active then
    FiltrarValoresLookup(
      unqryTablaG.FieldByName('ID_VA_AC').AsString);
  AbrirConsultaConTiempo(
    unqryVariacionesLookup, TAG, 'unqryVariacionesLookup', RegistroLog);
  AbrirConsultaConTiempo(
    unqryAtributosLookup, TAG, 'unqryAtributosLookup', RegistroLog);
  AbrirConsultaConTiempo(
    unqryAtributosBasicosLookup, TAG, 'unqryAtributosBasicosLookup',
    RegistroLog);
  AbrirConsultaConTiempo(
    unqryConjuntoDetalle, TAG, 'unqryConjuntoDetalle', RegistroLog);
  AbrirConsultaConTiempo(
    unqryArticulosConjunto, TAG, 'unqryArticulosConjunto', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleAfterInsert(
                                                             DataSet: TDataSet);
begin
  inherited;
  DataSet.FieldByName('ID_AC_ACD').AsInteger :=
                                     unqryTablaG.FieldByName('ID_AC').AsInteger;
end;

procedure TdmAtributosConjuntos.unqryConjuntoDetalleBeforePost(
                                                             DataSet: TDataSet);
var
  bValorModificado: Boolean;
  iIdAnterior: Integer;
  iIdConjunto: Integer;
  iIdValor: Integer;
  sIdAtributo: string;
begin
  inherited;
  if unqryTablaG.State in [dsEdit, dsInsert] then
    raise Exception.Create(
      'Graba primero los datos de la colección antes de modificar sus valores.');
  if DataSet.FieldByName('ID_AV_ACD').IsNull then
    raise Exception.Create(SErrorValorColeccionAtributosObligatorio);
  iIdConjunto := unqryTablaG.FieldByName('ID_AC').AsInteger;
  iIdValor := DataSet.FieldByName('ID_AV_ACD').AsInteger;
  iIdAnterior := 0;
  if DataSet.State = dsEdit then
    iIdAnterior := StrToIntDef(
      VarToStr(DataSet.FieldByName('ID_AV_ACD').OldValue), 0);
  DataSet.FieldByName('ID_AC_ACD').AsInteger := iIdConjunto;
  sIdAtributo := unqryTablaG.FieldByName('ID_VA_AC').AsString;
  if not ValorPerteneceAtributo(
           iIdValor, sIdAtributo) then
    raise Exception.Create(
      'El valor seleccionado no pertenece al atributo de la colección.');
  bValorModificado := DataSet.State = dsInsert;
  if DataSet.State = dsEdit then
    bValorModificado :=
      VarToStr(DataSet.FieldByName('ID_AV_ACD').OldValue) <>
      DataSet.FieldByName('ID_AV_ACD').AsString;
  if bValorModificado and
     ValorRepetidoEnConjunto(
       iIdConjunto, iIdValor, iIdAnterior) then
    raise Exception.Create(
      'Ese valor ya está incluido en la colección.');
  ActualizarAuditoria(DataSet);
end;

procedure TdmAtributosConjuntos.unqryTablaGConjuntosBeforePost(
  DataSet: TDataSet);
var
  bAtributoModificado: Boolean;
  iIdConjunto: Integer;
  sIdAtributo: string;
begin
  iIdConjunto := 0;
  if not DataSet.FieldByName('ID_AC').IsNull then
    iIdConjunto := DataSet.FieldByName('ID_AC').AsInteger;
  sIdAtributo := DataSet.FieldByName('ID_VA_AC').AsString;
  bAtributoModificado := DataSet.State = dsEdit;
  if bAtributoModificado then
    bAtributoModificado := not SameText(
      VarToStr(DataSet.FieldByName('ID_VA_AC').OldValue),
      sIdAtributo);
  if bAtributoModificado and
     (not DetallesPertenecenAtributo(
            iIdConjunto, sIdAtributo)) then
    raise Exception.Create(
      'La colección contiene valores de otro atributo. ' +
      'Elimina primero sus valores antes de cambiar el atributo.');
  inherited unqryTablaGBeforePost(DataSet);
end;

initialization
  RegistrarDataModule(TdmAtributosConjuntos);
  ForceReferenceToClass(TdmAtributosConjuntos);
end.
