{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTarifasCambios                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de sesiones de cambios de tarifa.                             }
{    Calcula lineas pendientes y aplica los precios a fza_articulos_tarifas.   }
{******************************************************************************}
unit UniDataTarifasCambios;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Math,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen;

type
  TdmTarifasCambios = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
  private
    function  CampoCabecera(const ACampo: string): TField;
    function  LeerFloatLinea(const ACampo: string): Double;
    function  PrecioBaseLinea(const ACampoOrigen: string): Double;
    function  CalcularImporte(AImporteBase: Double;
                              const ATipoAplicacion: string;
                              AValorAplicacion: Double): Double;
    function  RedondearImporte(AImporte: Double;
                               AValorRedondeo: Double;
                               AValorMenos: Double;
                               EsRedondearArriba: Boolean): Double;
    procedure ConfigurarConsultasAplicacion(
      AConsultaBusca, AConsultaMarca, AConsultaUnico: TUniQuery);
    function AplicarLineaTarifa(
      AConsultaBusca, AConsultaExec, AConsultaMarca,
      AConsultaUnico: TUniQuery;
      out AEncoloPrestaShop: Boolean): Boolean;
    function AplicarVentanaDescuento(AConsulta: TUniQuery): Boolean;
    procedure MarcarSesionAplicada(AConsulta: TUniQuery);
    procedure ConfigurarQueries;
  public
    unqryLineas  : TUniQuery;
    dsLineas     : TDataSource;
    unqryTarifas : TUniQuery;
    dsTarifas    : TDataSource;
    procedure AbrirDetalles; override;
    function  RecalcularSesionActual(out AMensaje: string): Integer;
    function  AplicarSesionActual(out AMensaje: string): Integer;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  inLibUser, inLibMsgArticulos, UniDataPrestaShopEncolado,
  inLibPrestaShopColaSenal;

{$R *.dfm}

resourcestring
  SErrorTarifasCambiosSinSesionActiva =
    'No hay ninguna sesion activa.';
  SErrorTarifasCambiosSesionSinLineas =
    'La sesion no tiene lineas.';
  SErrorTarifasCambiosSesionAplicada =
    'La sesion ya esta aplicada.';

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmTarifasCambios.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryLineas := TUniQuery.Create(Self);
  dsLineas := TDataSource.Create(Self);
  dsLineas.DataSet := unqryLineas;
  unqryTarifas := TUniQuery.Create(Self);
  dsTarifas := TDataSource.Create(Self);
  dsTarifas.DataSet := unqryTarifas;
  ConfigurarQueries;
end;

procedure TdmTarifasCambios.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(dsLineas) then
    dsLineas.DataSet := nil;
  if Assigned(dsTarifas) then
    dsTarifas.DataSet := nil;
  if Assigned(unqryLineas) then
  begin
    if unqryLineas.Active then
      unqryLineas.Close;
    unqryLineas.MasterSource := nil;
    unqryLineas.MasterFields := '';
    unqryLineas.DetailFields := '';
  end;
  if Assigned(unqryTarifas) then
  begin
    if unqryTarifas.Active then
      unqryTarifas.Close;
  end;
  inherited;
end;

procedure TdmTarifasCambios.ConfigurarQueries;
begin
  unqryTablaG.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_tarifas_cambios ' +
    ' ORDER BY CODIGO_TARC DESC';
  unqryTablaG.KeyFields := 'CODIGO_TARC';
  unqryTablaG.AfterInsert := unqryTablaGAfterInsert;
  unqryTablaG.BeforePost := unqryTablaGBeforePost;
  unqryLineas.SQL.Text :=
    'SELECT L.*, A.DESCRIPCION_ART, A.CODIGO_FAM_ART, ' +
    '       F.NOMBRE_FAM_FAM, P.RAZON_SOCIAL_PRV ' +
    '  FROM fza_tarifas_cambios_lineas L ' +
    '  LEFT JOIN fza_articulos A ' +
    '    ON A.CODIGO_ART_ART = L.CODIGO_ART_TARCLIN ' +
    '  LEFT JOIN fza_articulos_familias F ' +
    '    ON F.CODIGO_FAM_FAM = A.CODIGO_FAM_ART ' +
    '  LEFT JOIN fza_articulos_proveedores AP ' +
    '    ON AP.CODIGO_ART_AP = A.CODIGO_ART_ART ' +
    '   AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '  LEFT JOIN fza_proveedores P ' +
    '    ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
    ' ORDER BY L.ID_TARCLIN';
  unqryLineas.KeyFields := 'ID_TARCLIN';
  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    '  ESAPLICAR_TARCLIN = :ESAPLICAR_TARCLIN, ' +
    '  PRECIO_NUEVO_TARCLIN = :PRECIO_NUEVO_TARCLIN, ' +
    '  PRECIO_FINAL_NUEVO_TARCLIN = :PRECIO_FINAL_NUEVO_TARCLIN, ' +
    '  PRECIO_DTO_NUEVO_TARCLIN = :PRECIO_DTO_NUEVO_TARCLIN, ' +
    '  PORCENTAJE_DTO_NUEVO_TARCLIN = :PORCENTAJE_DTO_NUEVO_TARCLIN, ' +
    '  ESTADO_TARCLIN = :ESTADO_TARCLIN, ' +
    '  MENSAJE_TARCLIN = :MENSAJE_TARCLIN, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF, ' +
    '  INSTANTE_MODIF = NOW() ' +
    'WHERE ID_TARCLIN = :Old_ID_TARCLIN';
  unqryTarifas.SQL.Text :=
    'SELECT CODIGO_TAR_ARTTAR, NOMBRE_TAR_TAR ' +
    '  FROM fza_tarifas ' +
    ' WHERE ESACTIVO_ARTTAR = ''S'' ' +
    ' ORDER BY ORDEN_TAR, CODIGO_TAR_ARTTAR';
end;

procedure TdmTarifasCambios.AbrirDetalles;
begin
  inherited;
  if not unqryTarifas.Active then
    unqryTarifas.Open;
  if not unqryLineas.Active then
    unqryLineas.Open;
end;

procedure TdmTarifasCambios.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('NOMBRE_TARC').AsString :=
    'Sesion tarifas ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
  DataSet.FieldByName('FECHA_TARC').AsDateTime := Date;
  DataSet.FieldByName('ESTADO_TARC').AsString := 'BORRADOR';
  DataSet.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString := 'PVP';
  DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString := 'PVP';
  DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString := 'PRECIO_ORIGEN';
  DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString := 'AMBOS';
  DataSet.FieldByName('TIPO_APLICACION_TARC').AsString := 'COPIAR';
  DataSet.FieldByName('VALOR_APLICACION_TARC').AsFloat := 0;
  DataSet.FieldByName('VALOR_REDONDEO_TARC').AsFloat := 0.01;
  DataSet.FieldByName('VALOR_MENOS_AJUSTE_TARC').AsFloat := 0;
  DataSet.FieldByName('ESREDONDEAR_ARRIBA_TARC').AsString := 'S';
  DataSet.FieldByName('FECHA_DESDE_TARC').AsDateTime := Date;
end;

procedure TdmTarifasCambios.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  if Trim(DataSet.FieldByName('NOMBRE_TARC').AsString) = '' then
    raise Exception.Create(SErrorNombreSesionCambioTarifaObligatorio);
  if Trim(DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString) = '' then
    raise Exception.Create(SErrorTarifaDestinoObligatoria);
  if Trim(DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString) = '' then
    DataSet.FieldByName('CAMPO_ORIGEN_TARC').AsString := 'PRECIO_ORIGEN';
  if Trim(DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString) = '' then
    DataSet.FieldByName('CAMPO_DESTINO_TARC').AsString := 'AMBOS';
  if Trim(DataSet.FieldByName('TIPO_APLICACION_TARC').AsString) = '' then
    DataSet.FieldByName('TIPO_APLICACION_TARC').AsString := 'COPIAR';
end;

function TdmTarifasCambios.CampoCabecera(const ACampo: string): TField;
begin
  Result := nil;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
    Result := unqryTablaG.FieldByName(ACampo);
end;

function TdmTarifasCambios.LeerFloatLinea(const ACampo: string): Double;
begin
  Result := 0;
  if not unqryLineas.FieldByName(ACampo).IsNull then
    Result := unqryLineas.FieldByName(ACampo).AsFloat;
end;

function TdmTarifasCambios.PrecioBaseLinea(
  const ACampoOrigen: string): Double;
begin
  if SameText(ACampoOrigen, 'PRECIO_COSTE') then
    Result := LeerFloatLinea('PRECIO_COSTE_TARCLIN')
  else if SameText(ACampoOrigen, 'PRECIO_DESTINO_ACTUAL') then
    Result := LeerFloatLinea('PRECIO_FINAL_ACTUAL_TARCLIN')
  else
    Result := LeerFloatLinea('PRECIO_ORIGEN_TARCLIN');
end;

function TdmTarifasCambios.CalcularImporte(AImporteBase: Double;
  const ATipoAplicacion: string; AValorAplicacion: Double): Double;
begin
  if SameText(ATipoAplicacion, 'INCREMENTO_LINEAL') then
    Result := AImporteBase + AValorAplicacion
  else if SameText(ATipoAplicacion, 'INCREMENTO_PORCENTUAL') then
    Result := AImporteBase + (AImporteBase * AValorAplicacion / 100)
  else if SameText(ATipoAplicacion, 'PRECIO_FIJO') then
    Result := AValorAplicacion
  else
    Result := AImporteBase;
end;

function TdmTarifasCambios.RedondearImporte(AImporte: Double;
  AValorRedondeo: Double; AValorMenos: Double;
  EsRedondearArriba: Boolean): Double;
begin
  Result := AImporte;
  if EsRedondearArriba and (AValorRedondeo > 0) then
    Result := Ceil(Result / AValorRedondeo) * AValorRedondeo;
  Result := Result - AValorMenos;
  if Result < 0 then
    Result := 0;
  Result := Round(Result * 100) / 100;
end;

function TdmTarifasCambios.RecalcularSesionActual(
  out AMensaje: string): Integer;
var
  qry               : TUniQuery;
  sCampoOrigen      : string;
  sCampoDestino     : string;
  sTipoAplicacion   : string;
  dValorAplicacion  : Double;
  dValorRedondeo    : Double;
  dValorMenos       : Double;
  dBase             : Double;
  dNuevo            : Double;
  dSalida           : Double;
  dFinal            : Double;
  dDto              : Double;
  dPorcDto          : Double;
  EsRedondearArriba : Boolean;
begin
  Result := 0;
  AMensaje := '';
  if (not unqryTablaG.Active) or unqryTablaG.IsEmpty then
    AMensaje := SErrorTarifasCambiosSinSesionActiva
  else if (not unqryLineas.Active) or unqryLineas.IsEmpty then
    AMensaje := SErrorTarifasCambiosSesionSinLineas
  else
  begin
    sCampoOrigen := CampoCabecera('CAMPO_ORIGEN_TARC').AsString;
    sCampoDestino := CampoCabecera('CAMPO_DESTINO_TARC').AsString;
    sTipoAplicacion := CampoCabecera('TIPO_APLICACION_TARC').AsString;
    dValorAplicacion := CampoCabecera('VALOR_APLICACION_TARC').AsFloat;
    dValorRedondeo := CampoCabecera('VALOR_REDONDEO_TARC').AsFloat;
    dValorMenos := CampoCabecera('VALOR_MENOS_AJUSTE_TARC').AsFloat;
    EsRedondearArriba :=
      SameText(CampoCabecera('ESREDONDEAR_ARRIBA_TARC').AsString, 'S');
    qry := TUniQuery.Create(nil);
    try
      qry.Connection := unqryTablaG.Connection;
      qry.SQL.Text :=
        'UPDATE fza_tarifas_cambios_lineas SET ' +
        '  PRECIO_NUEVO_TARCLIN = :SALIDA, ' +
        '  PRECIO_FINAL_NUEVO_TARCLIN = :FINAL, ' +
        '  PRECIO_DTO_NUEVO_TARCLIN = :DTO, ' +
        '  PORCENTAJE_DTO_NUEVO_TARCLIN = :PORC_DTO, ' +
        '  ESTADO_TARCLIN = ''PENDIENTE'', ' +
        '  MENSAJE_TARCLIN = NULL, ' +
        '  USUARIO_MODIF = :USUARIO, ' +
        '  INSTANTE_MODIF = NOW() ' +
        'WHERE ID_TARCLIN = :ID';
      unqryLineas.DisableControls;
      try
        unqryLineas.First;
        while not unqryLineas.Eof do
        begin
          dBase := PrecioBaseLinea(sCampoOrigen);
          dNuevo := CalcularImporte(dBase, sTipoAplicacion,
                                    dValorAplicacion);
          dNuevo := RedondearImporte(dNuevo, dValorRedondeo,
                                     dValorMenos, EsRedondearArriba);
          dSalida := dNuevo;
          dFinal := dNuevo;
          dDto := 0;
          dPorcDto := 0;
          if SameText(sCampoDestino, 'PRECIO_FINAL') then
          begin
            dSalida := LeerFloatLinea('PRECIO_SALIDA_ACTUAL_TARCLIN');
            if dSalida <= 0 then
              dSalida := dNuevo;
            dFinal := dNuevo;
            dDto := dSalida - dFinal;
            if dDto < 0 then
              dDto := 0;
          end
          else if SameText(sCampoDestino, 'PRECIO_SALIDA') then
          begin
            dSalida := dNuevo;
            dDto := LeerFloatLinea('PRECIO_DTO_ACTUAL_TARCLIN');
            dFinal := dSalida - dDto;
            if dFinal < 0 then
              dFinal := dSalida;
          end;
          if (dSalida > 0) and (dDto > 0) then
            dPorcDto := dDto / dSalida * 100;
          qry.ParamByName('SALIDA').AsFloat := dSalida;
          qry.ParamByName('FINAL').AsFloat := dFinal;
          qry.ParamByName('DTO').AsFloat := dDto;
          qry.ParamByName('PORC_DTO').AsFloat := dPorcDto;
          qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
          qry.ParamByName('ID').AsInteger :=
            unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
          qry.Execute;
          Inc(Result);
          unqryLineas.Next;
        end;
      finally
        unqryLineas.EnableControls;
      end;
      qry.SQL.Text :=
        'UPDATE fza_tarifas_cambios SET ' +
        '  ESTADO_TARC = ''BORRADOR'', ' +
        '  INSTANTE_APLICACION_TARC = NULL, ' +
        '  USUARIO_APLICACION_TARC = NULL, ' +
        '  USUARIO_MODIF = :USUARIO, ' +
        '  INSTANTE_MODIF = NOW() ' +
        'WHERE CODIGO_TARC = :CODIGO';
      qry.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      qry.ParamByName('CODIGO').AsInteger :=
        unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
      qry.Execute;
      unqryTablaG.Refresh;
      unqryLineas.Refresh;
    finally
      FreeAndNil(qry);
    end;
  end;
end;

procedure TdmTarifasCambios.ConfigurarConsultasAplicacion(
  AConsultaBusca, AConsultaMarca, AConsultaUnico: TUniQuery);
begin
  AConsultaBusca.SQL.Text :=
    'SELECT CODIGO_UNICO_ARTTAR ' +
    'FROM fza_articulos_tarifas ' +
    'WHERE CODIGO_ART_ARTTAR = :ART ' +
    'AND COALESCE(CODIGO_UNIDAD_ARTTAR, '''') = :SKU ' +
    'AND CODIGO_TAR_ARTTAR = :TAR ' +
    'AND ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY FECHA_DESDE_ARTTAR DESC, CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1';
  AConsultaMarca.SQL.Text :=
    'UPDATE fza_tarifas_cambios_lineas SET ' +
    'ESTADO_TARCLIN = ''APLICADA'', MENSAJE_TARCLIN = :MENSAJE, ' +
    'CODIGO_UNICO_ARTTAR_TARCLIN = :UNICO, ' +
    'INSTANTE_APLICACION_TARCLIN = NOW(), USUARIO_MODIF = :USUARIO, ' +
    'INSTANTE_MODIF = NOW() WHERE ID_TARCLIN = :ID';
  AConsultaUnico.SQL.Text :=
    'SELECT LAST_INSERT_ID() AS CODIGO_UNICO_ARTTAR';
end;

function TdmTarifasCambios.AplicarLineaTarifa(
  AConsultaBusca, AConsultaExec, AConsultaMarca,
  AConsultaUnico: TUniQuery;
  out AEncoloPrestaShop: Boolean): Boolean;
var
  EsInsertar: Boolean;
  iUnico: Integer;
  sArticulo: string;
  sSku: string;
  sTarifa: string;
begin
  Result := False;
  AEncoloPrestaShop := False;
  if SameText(unqryLineas.FieldByName(
    'ESAPLICAR_TARCLIN').AsString, 'S') then
  begin
    sArticulo := unqryLineas.FieldByName('CODIGO_ART_TARCLIN').AsString;
    sSku := unqryLineas.FieldByName(
      'CODIGO_UNIDAD_SKU_TARCLIN').AsString;
    sTarifa := unqryLineas.FieldByName(
      'CODIGO_TAR_DESTINO_TARCLIN').AsString;
    AConsultaBusca.Close;
    AConsultaBusca.ParamByName('ART').AsString := sArticulo;
    AConsultaBusca.ParamByName('SKU').AsString := sSku;
    AConsultaBusca.ParamByName('TAR').AsString := sTarifa;
    AConsultaBusca.Open;
    EsInsertar := AConsultaBusca.IsEmpty;
    if EsInsertar then
    begin
      iUnico := 0;
      AConsultaExec.SQL.Text :=
        'INSERT INTO fza_articulos_tarifas ' +
        '(CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, ' +
        'CODIGO_TAR_ARTTAR, ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, ' +
        'PRECIO_FINAL_ARTTAR, PRECIO_DTO_ARTTAR, ' +
        'PORCENTAJE_DTO_ARTTAR, FECHA_DESDE_ARTTAR, ' +
        'FECHA_HASTA_ARTTAR, USUARIO_ALTA, USUARIO_MODIF, ' +
        'INSTANTE_ALTA) VALUES (:ART, :SKU, :TAR, ''S'', :SALIDA, ' +
        ':FINAL, :DTO, :PORC_DTO, :DESDE, :HASTA, :USUARIO, ' +
        ':USUARIO, NOW())';
      AConsultaExec.ParamByName('ART').AsString := sArticulo;
      AConsultaExec.ParamByName('SKU').AsString := sSku;
      AConsultaExec.ParamByName('TAR').AsString := sTarifa;
    end
    else
    begin
      iUnico := AConsultaBusca.FieldByName(
        'CODIGO_UNICO_ARTTAR').AsInteger;
      AConsultaExec.SQL.Text :=
        'UPDATE fza_articulos_tarifas SET ' +
        'PRECIO_SALIDA_ARTTAR = :SALIDA, PRECIO_FINAL_ARTTAR = :FINAL, ' +
        'PRECIO_DTO_ARTTAR = :DTO, PORCENTAJE_DTO_ARTTAR = :PORC_DTO, ' +
        'FECHA_DESDE_ARTTAR = :DESDE, FECHA_HASTA_ARTTAR = :HASTA, ' +
        'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
        'WHERE CODIGO_UNICO_ARTTAR = :UNICO';
      AConsultaExec.ParamByName('UNICO').AsInteger := iUnico;
    end;
    AConsultaExec.ParamByName('SALIDA').AsFloat :=
      LeerFloatLinea('PRECIO_NUEVO_TARCLIN');
    AConsultaExec.ParamByName('FINAL').AsFloat :=
      LeerFloatLinea('PRECIO_FINAL_NUEVO_TARCLIN');
    AConsultaExec.ParamByName('DTO').AsFloat :=
      LeerFloatLinea('PRECIO_DTO_NUEVO_TARCLIN');
    AConsultaExec.ParamByName('PORC_DTO').AsFloat :=
      LeerFloatLinea('PORCENTAJE_DTO_NUEVO_TARCLIN');
    if CampoCabecera('FECHA_DESDE_TARC').IsNull then
      AConsultaExec.ParamByName('DESDE').AsDateTime := Date
    else
      AConsultaExec.ParamByName('DESDE').AsDateTime :=
        CampoCabecera('FECHA_DESDE_TARC').AsDateTime;
    if CampoCabecera('FECHA_HASTA_TARC').IsNull then
      AConsultaExec.ParamByName('HASTA').Clear
    else
      AConsultaExec.ParamByName('HASTA').AsDateTime :=
        CampoCabecera('FECHA_HASTA_TARC').AsDateTime;
    AConsultaExec.ParamByName('USUARIO').AsString :=
      IdentidadSesion.Usuario;
    AConsultaExec.Execute;
    if EsInsertar then
    begin
      AConsultaUnico.Close;
      AConsultaUnico.Open;
      iUnico := AConsultaUnico.FieldByName(
        'CODIGO_UNICO_ARTTAR').AsInteger;
    end;
    AConsultaMarca.ParamByName('MENSAJE').AsString := 'Aplicada';
    AConsultaMarca.ParamByName('UNICO').AsInteger := iUnico;
    AConsultaMarca.ParamByName('USUARIO').AsString :=
      IdentidadSesion.Usuario;
    AConsultaMarca.ParamByName('ID').AsInteger :=
      unqryLineas.FieldByName('ID_TARCLIN').AsInteger;
    AConsultaMarca.Execute;
    if SameText(
      Trim(sTarifa),
      LeerCodigoTarifaPrestaShop(
        AConsultaExec.Connection,
        IdentidadSesion.Usuario)) then
    begin
      EncolarPrecioPrestaShop(
        AConsultaExec.Connection,
        sArticulo,
        IdentidadSesion.Usuario);
      AEncoloPrestaShop := True;
    end;
    Result := True;
  end;
end;

function TdmTarifasCambios.AplicarVentanaDescuento(
  AConsulta: TUniQuery): Boolean;
var
  fDesde: TField;
  fHasta: TField;
  sTarifa: string;
begin
  Result := False;
  fDesde := unqryTablaG.FindField('FECHA_DESDE_DTO_TARC');
  fHasta := unqryTablaG.FindField('FECHA_HASTA_DTO_TARC');
  if Assigned(fDesde) and Assigned(fHasta) and
    ((not fDesde.IsNull) or (not fHasta.IsNull)) then
  begin
    AConsulta.SQL.Text :=
      'UPDATE fza_tarifas SET FECHA_DESDE_DTO_TAR = :DESDE_DTO, ' +
      'FECHA_HASTA_DTO_TAR = :HASTA_DTO, USUARIO_MODIF = :USUARIO, ' +
      'INSTANTE_MODIF = NOW() WHERE CODIGO_TAR_ARTTAR = :TAR';
    if fDesde.IsNull then
      AConsulta.ParamByName('DESDE_DTO').Clear
    else
      AConsulta.ParamByName('DESDE_DTO').AsDateTime := fDesde.AsDateTime;
    if fHasta.IsNull then
      AConsulta.ParamByName('HASTA_DTO').Clear
    else
      AConsulta.ParamByName('HASTA_DTO').AsDateTime := fHasta.AsDateTime;
    AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    sTarifa := unqryTablaG.FieldByName(
      'CODIGO_TAR_DESTINO_TARC').AsString;
    AConsulta.ParamByName('TAR').AsString := sTarifa;
    AConsulta.Execute;
    if SameText(
      Trim(sTarifa),
      LeerCodigoTarifaPrestaShop(
        AConsulta.Connection,
        IdentidadSesion.Usuario)) then
    begin
      EncolarTodosWebPrestaShop(
        AConsulta.Connection,
        True,
        False,
        IdentidadSesion.Usuario);
      Result := True;
    end;
  end;
end;

procedure TdmTarifasCambios.MarcarSesionAplicada(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_tarifas_cambios SET ESTADO_TARC = ''APLICADA'', ' +
    'INSTANTE_APLICACION_TARC = NOW(), USUARIO_APLICACION_TARC = ' +
    ':USUARIO, USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_TARC = :CODIGO';
  AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  AConsulta.ParamByName('CODIGO').AsInteger :=
    unqryTablaG.FieldByName('CODIGO_TARC').AsInteger;
  AConsulta.Execute;
end;

function TdmTarifasCambios.AplicarSesionActual(
  out AMensaje: string): Integer;
var
  EncoloLineaPrestaShop: Boolean;
  EsTransaccionPropia: Boolean;
  HayEncoladoPrestaShop: Boolean;
  TransaccionConfirmada: Boolean;
  oConexion: TUniConnection;
  qryBusca: TUniQuery;
  qryExec: TUniQuery;
  qryMarca: TUniQuery;
  qryUnico: TUniQuery;
begin
  Result := 0;
  AMensaje := '';
  if (not unqryTablaG.Active) or unqryTablaG.IsEmpty then
    AMensaje := SErrorTarifasCambiosSinSesionActiva
  else if SameText(unqryTablaG.FieldByName('ESTADO_TARC').AsString,
    'APLICADA') then
    AMensaje := SErrorTarifasCambiosSesionAplicada
  else if (not unqryLineas.Active) or unqryLineas.IsEmpty then
    AMensaje := SErrorTarifasCambiosSesionSinLineas
  else
  begin
    qryBusca := nil;
    qryExec := nil;
    qryMarca := nil;
    qryUnico := nil;
    try
      qryBusca := TUniQuery.Create(nil);
      qryExec := TUniQuery.Create(nil);
      qryMarca := TUniQuery.Create(nil);
      qryUnico := TUniQuery.Create(nil);
      oConexion := unqryTablaG.Connection as TUniConnection;
      qryBusca.Connection := oConexion;
      qryExec.Connection := oConexion;
      qryMarca.Connection := oConexion;
      qryUnico.Connection := oConexion;
      ConfigurarConsultasAplicacion(qryBusca, qryMarca, qryUnico);
      EsTransaccionPropia := not oConexion.InTransaction;
      HayEncoladoPrestaShop := False;
      TransaccionConfirmada := False;
      if EsTransaccionPropia then
        oConexion.StartTransaction;
      try
        unqryLineas.DisableControls;
        try
          unqryLineas.First;
          while not unqryLineas.Eof do
          begin
            if AplicarLineaTarifa(
              qryBusca, qryExec, qryMarca, qryUnico,
              EncoloLineaPrestaShop) then
              Inc(Result);
            HayEncoladoPrestaShop :=
              HayEncoladoPrestaShop or EncoloLineaPrestaShop;
            unqryLineas.Next;
          end;
        finally
          unqryLineas.EnableControls;
        end;
        HayEncoladoPrestaShop :=
          AplicarVentanaDescuento(qryExec) or HayEncoladoPrestaShop;
        MarcarSesionAplicada(qryExec);
        if EsTransaccionPropia then
        begin
          oConexion.Commit;
          TransaccionConfirmada := True;
        end;
      except
        on E: Exception do
        begin
          if EsTransaccionPropia and oConexion.InTransaction then
            oConexion.Rollback;
          if EsTransaccionPropia then
          begin
            AMensaje := E.Message;
            Result := 0;
          end
          else
            raise;
        end;
      end;
      if TransaccionConfirmada and HayEncoladoPrestaShop then
        SolicitarProcesadoPrestaShop;
      unqryTablaG.Refresh;
      unqryLineas.Refresh;
    finally
      FreeAndNil(qryUnico);
      FreeAndNil(qryMarca);
      FreeAndNil(qryExec);
      FreeAndNil(qryBusca);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmTarifasCambios);
  ForceReferenceToClass(TdmTarifasCambios);
end.
