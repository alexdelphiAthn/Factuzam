{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCargarSesionTarifa                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Carga masiva de articulos sobre una sesion de cambios de tarifa.          }
{    Reutiliza los filtros de AddBlockBase y guarda una linea revisable.       }
{******************************************************************************}
unit inMtoModalCargarSesionTarifa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Data.DB, MemDS, DBAccess, Uni,
  inMtoModalAddBlockBase;

type
  TCargarSesionTarifaResult = record
    Aceptado      : Boolean;
    NumInsertados : Integer;
  end;

  TfrmModalCargarSesionTarifa = class(TfrmModalAddBlockBase)
  protected
    FCodigoTarc    : Integer;
    FCodigoTarOrig : string;
    FCodigoTarDest : string;
    FResultado     : TCargarSesionTarifaResult;
    function  ColumnasSelectExtra: string; override;
    function  SubquerYaCargado: string; override;
    function  WhereExcluirYaCargados: string; override;
    procedure VincularParametrosExtra(AQry: TUniQuery); override;
    function  TextoConfirmacion(ANumPendientes: Integer): string; override;
    function  TextoExito(ANumInsertados: Integer): string; override;
    function  TextoExcluirYaCargados: string; override;
    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean;
      override;
  public
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            ACodigoTarc: Integer;
                            const ACodigoTarOrig,
                                  ACodigoTarDest: string):
                                  TCargarSesionTarifaResult;
  end;

implementation

{$R *.dfm}

uses
  inLibGlobalVar;

class function TfrmModalCargarSesionTarifa.Ejecutar(AOwner: TComponent;
  AConn: TUniConnection; ACodigoTarc: Integer;
  const ACodigoTarOrig, ACodigoTarDest: string): TCargarSesionTarifaResult;
var
  frm: TfrmModalCargarSesionTarifa;
begin
  frm := TfrmModalCargarSesionTarifa.Create(AOwner);
  try
    frm.FCodigoTarc := ACodigoTarc;
    frm.FCodigoTarOrig := ACodigoTarOrig;
    frm.FCodigoTarDest := ACodigoTarDest;
    frm.FResultado.Aceptado := False;
    frm.Caption := 'Cargar articulos en sesion de tarifas';
    frm.Inicializar(AConn);
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

function TfrmModalCargarSesionTarifa.ColumnasSelectExtra: string;
begin
  Result :=
    '(SELECT TOG.PRECIO_SALIDA_ARTTAR ' +
    '   FROM fza_articulos_tarifas TOG ' +
    '  WHERE TOG.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    '    AND COALESCE(TOG.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '    AND TOG.CODIGO_TAR_ARTTAR = :P_TAR_ORIG ' +
    '    AND TOG.ESACTIVO_ARTTAR = ''S'' ' +
    '  ORDER BY TOG.FECHA_DESDE_ARTTAR DESC, ' +
    '           TOG.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_ORIGEN, ' +
    '(SELECT TDE.PRECIO_SALIDA_ARTTAR ' +
    '   FROM fza_articulos_tarifas TDE ' +
    '  WHERE TDE.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    '    AND COALESCE(TDE.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '    AND TDE.CODIGO_TAR_ARTTAR = :P_TAR_DEST_SAL ' +
    '    AND TDE.ESACTIVO_ARTTAR = ''S'' ' +
    '  ORDER BY TDE.FECHA_DESDE_ARTTAR DESC, ' +
    '           TDE.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_SALIDA_ACT, ' +
    '(SELECT TDF.PRECIO_FINAL_ARTTAR ' +
    '   FROM fza_articulos_tarifas TDF ' +
    '  WHERE TDF.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    '    AND COALESCE(TDF.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '    AND TDF.CODIGO_TAR_ARTTAR = :P_TAR_DEST_FIN ' +
    '    AND TDF.ESACTIVO_ARTTAR = ''S'' ' +
    '  ORDER BY TDF.FECHA_DESDE_ARTTAR DESC, ' +
    '           TDF.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_FINAL_ACT, ' +
    '(SELECT TDD.PRECIO_DTO_ARTTAR ' +
    '   FROM fza_articulos_tarifas TDD ' +
    '  WHERE TDD.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    '    AND COALESCE(TDD.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '    AND TDD.CODIGO_TAR_ARTTAR = :P_TAR_DEST_DTO ' +
    '    AND TDD.ESACTIVO_ARTTAR = ''S'' ' +
    '  ORDER BY TDD.FECHA_DESDE_ARTTAR DESC, ' +
    '           TDD.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_DTO_ACT, ' +
    '(SELECT TDP.PORCENTAJE_DTO_ARTTAR ' +
    '   FROM fza_articulos_tarifas TDP ' +
    '  WHERE TDP.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    '    AND COALESCE(TDP.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '    AND TDP.CODIGO_TAR_ARTTAR = :P_TAR_DEST_PDTO ' +
    '    AND TDP.ESACTIVO_ARTTAR = ''S'' ' +
    '  ORDER BY TDP.FECHA_DESDE_ARTTAR DESC, ' +
    '           TDP.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PORC_DTO_ACT, ' +
    '(SELECT AP.PRECIO_ULT_COMPRA_AP ' +
    '   FROM fza_articulos_proveedores AP ' +
    '  WHERE AP.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
    '    AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '  LIMIT 1) AS PRECIO_COSTE,';
end;

function TfrmModalCargarSesionTarifa.SubquerYaCargado: string;
begin
  Result :=
    'CASE WHEN EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas SL ' +
    '                   WHERE SL.CODIGO_TARC_TARCLIN = :P_TARC_CHK ' +
    '                     AND SL.CODIGO_ART_TARCLIN = a.CODIGO_ART_ART ' +
    '                     AND SL.CODIGO_UNIDAD_SKU_TARCLIN = '''') ' +
    '     THEN ''S'' ELSE ''N'' END';
end;

function TfrmModalCargarSesionTarifa.WhereExcluirYaCargados: string;
begin
  Result :=
    'NOT EXISTS (SELECT 1 FROM fza_tarifas_cambios_lineas SLX ' +
    '             WHERE SLX.CODIGO_TARC_TARCLIN = :P_TARC_EXCL ' +
    '               AND SLX.CODIGO_ART_TARCLIN = a.CODIGO_ART_ART ' +
    '               AND SLX.CODIGO_UNIDAD_SKU_TARCLIN = '''')';
end;

procedure TfrmModalCargarSesionTarifa.VincularParametrosExtra(AQry: TUniQuery);

  function ExisteParam(const ANombre: string): Boolean;
  begin
    Result := AQry.Params.FindParam(ANombre) <> nil;
  end;

begin
  if ExisteParam('P_TARC_CHK') then
    AQry.ParamByName('P_TARC_CHK').AsInteger := FCodigoTarc;
  if ExisteParam('P_TARC_EXCL') then
    AQry.ParamByName('P_TARC_EXCL').AsInteger := FCodigoTarc;
  if ExisteParam('P_TAR_ORIG') then
    AQry.ParamByName('P_TAR_ORIG').AsString := FCodigoTarOrig;
  if ExisteParam('P_TAR_DEST_SAL') then
    AQry.ParamByName('P_TAR_DEST_SAL').AsString := FCodigoTarDest;
  if ExisteParam('P_TAR_DEST_FIN') then
    AQry.ParamByName('P_TAR_DEST_FIN').AsString := FCodigoTarDest;
  if ExisteParam('P_TAR_DEST_DTO') then
    AQry.ParamByName('P_TAR_DEST_DTO').AsString := FCodigoTarDest;
  if ExisteParam('P_TAR_DEST_PDTO') then
    AQry.ParamByName('P_TAR_DEST_PDTO').AsString := FCodigoTarDest;
end;

function TfrmModalCargarSesionTarifa.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format('Se van a cargar %d articulos en la sesion. Continuar?',
                   [ANumPendientes]);
end;

function TfrmModalCargarSesionTarifa.TextoExito(
  ANumInsertados: Integer): string;
begin
  Result := Format('%d articulos cargados en la sesion.', [ANumInsertados]);
end;

function TfrmModalCargarSesionTarifa.TextoExcluirYaCargados: string;
begin
  Result := 'Excluir articulos ya cargados en la sesion';
end;

function TfrmModalCargarSesionTarifa.EjecutarInsercion(
  out ANumInsertados: Integer; out ACodigos: TArray<string>): Boolean;
var
  qry     : TUniQuery;
  codigos : TList<string>;
  sArt    : string;
  dOrigen : Double;
begin
  Result := False;
  ANumInsertados := 0;
  ACodigos := nil;
  if (FSqlPreview <> nil) and FSqlPreview.Active and
     (FSqlPreview.RecordCount > 0) then
  begin
    qry := TUniQuery.Create(nil);
    codigos := TList<string>.Create;
    try
      qry.Connection := FConn;
      qry.SQL.Text :=
        'INSERT INTO fza_tarifas_cambios_lineas ' +
        ' (CODIGO_TARC_TARCLIN, CODIGO_ART_TARCLIN, ' +
        '  CODIGO_UNIDAD_SKU_TARCLIN, CODIGO_TAR_ORIGEN_TARCLIN, ' +
        '  CODIGO_TAR_DESTINO_TARCLIN, PRECIO_ORIGEN_TARCLIN, ' +
        '  PRECIO_COSTE_TARCLIN, PRECIO_SALIDA_ACTUAL_TARCLIN, ' +
        '  PRECIO_FINAL_ACTUAL_TARCLIN, PRECIO_DTO_ACTUAL_TARCLIN, ' +
        '  PORCENTAJE_DTO_ACTUAL_TARCLIN, PRECIO_NUEVO_TARCLIN, ' +
        '  PRECIO_FINAL_NUEVO_TARCLIN, PRECIO_DTO_NUEVO_TARCLIN, ' +
        '  PORCENTAJE_DTO_NUEVO_TARCLIN, ESAPLICAR_TARCLIN, ' +
        '  ESTADO_TARCLIN, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:TARC, :ART, '''', :TAR_ORIG, :TAR_DEST, :P_ORIG, ' +
        '        :P_COSTE, :P_SAL_ACT, :P_FIN_ACT, :P_DTO_ACT, ' +
        '        :P_PDTO_ACT, :P_NUEVO, :P_FIN_NUEVO, 0, 0, ' +
        '        ''S'', ''PENDIENTE'', :USUARIO, :USUARIO) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  PRECIO_ORIGEN_TARCLIN = VALUES(PRECIO_ORIGEN_TARCLIN), ' +
        '  PRECIO_COSTE_TARCLIN = VALUES(PRECIO_COSTE_TARCLIN), ' +
        '  PRECIO_SALIDA_ACTUAL_TARCLIN = ' +
        'VALUES(PRECIO_SALIDA_ACTUAL_TARCLIN), ' +
        '  PRECIO_FINAL_ACTUAL_TARCLIN = ' +
        'VALUES(PRECIO_FINAL_ACTUAL_TARCLIN), ' +
        '  PRECIO_DTO_ACTUAL_TARCLIN = VALUES(PRECIO_DTO_ACTUAL_TARCLIN), ' +
        '  PORCENTAJE_DTO_ACTUAL_TARCLIN = ' +
        'VALUES(PORCENTAJE_DTO_ACTUAL_TARCLIN), ' +
        '  USUARIO_MODIF = VALUES(USUARIO_MODIF), ' +
        '  INSTANTE_MODIF = NOW()';
      FConn.StartTransaction;
      try
        FSqlPreview.DisableControls;
        try
          FSqlPreview.First;
          while not FSqlPreview.Eof do
          begin
            if FSqlPreview.FieldByName('YA_CARGADO').AsString <> 'S' then
            begin
              sArt := FSqlPreview.FieldByName('CODIGO_ART_ART').AsString;
              dOrigen := FSqlPreview.FieldByName('PRECIO_ORIGEN').AsFloat;
              qry.ParamByName('TARC').AsInteger := FCodigoTarc;
              qry.ParamByName('ART').AsString := sArt;
              qry.ParamByName('TAR_ORIG').AsString := FCodigoTarOrig;
              qry.ParamByName('TAR_DEST').AsString := FCodigoTarDest;
              qry.ParamByName('P_ORIG').AsFloat := dOrigen;
              qry.ParamByName('P_COSTE').AsFloat :=
                FSqlPreview.FieldByName('PRECIO_COSTE').AsFloat;
              qry.ParamByName('P_SAL_ACT').AsFloat :=
                FSqlPreview.FieldByName('PRECIO_SALIDA_ACT').AsFloat;
              qry.ParamByName('P_FIN_ACT').AsFloat :=
                FSqlPreview.FieldByName('PRECIO_FINAL_ACT').AsFloat;
              qry.ParamByName('P_DTO_ACT').AsFloat :=
                FSqlPreview.FieldByName('PRECIO_DTO_ACT').AsFloat;
              qry.ParamByName('P_PDTO_ACT').AsFloat :=
                FSqlPreview.FieldByName('PORC_DTO_ACT').AsFloat;
              qry.ParamByName('P_NUEVO').AsFloat := dOrigen;
              qry.ParamByName('P_FIN_NUEVO').AsFloat := dOrigen;
              qry.ParamByName('USUARIO').AsString := oUser;
              qry.Execute;
              codigos.Add(sArt);
              Inc(ANumInsertados);
            end;
            FSqlPreview.Next;
          end;
        finally
          FSqlPreview.EnableControls;
        end;
        FConn.Commit;
        Result := True;
        ACodigos := codigos.ToArray;
        FResultado.Aceptado := True;
        FResultado.NumInsertados := ANumInsertados;
      except
        on E: Exception do
        begin
          FConn.Rollback;
          ShowMessage('Error al cargar la sesion: ' + E.Message);
          Result := False;
        end;
      end;
    finally
      FreeAndNil(codigos);
      FreeAndNil(qry);
    end;
  end;
end;

end.
