{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalDistribuidor                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.3.0                                                         }
{   Fecha:       24/05/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Modal "distribuidor por almacen" para sesiones de compra en modo          }
{    ESFORMATO_DISTRIBUIDO_SES='S'. Pinta un cuadrante almacenes x tallas      }
{    para una linea concreta de la sesion. El usuario reparte cantidades       }
{    por (almacen, talla); al aceptar hace upsert en                           }
{    fza_compras_sesiones_celdas (clave compuesta por serie+numero+linea+      }
{    almacen+id_av_pivot, idfila=0 para distribuidor: el "color/fila" del      }
{    pivote en sesiones vive a nivel de linea, no a nivel de celda).           }
{                                                                              }
{    Implementacion: TcxGrid en band-view donde un dataset en memoria carga    }
{    una fila por almacen activo con columnas T01..T20. Al cargar leemos las   }
{    celdas existentes; al aceptar comparamos contra el snapshot inicial y     }
{    aplicamos INSERT / UPDATE / DELETE para cada cambio.                      }
{                                                                              }
{    Hereda de TfrmModalAceptCancel para reutilizar pnlBody + pnlButton con    }
{    los botones Aceptar/Cancelar (F12/ESC) estandar de la app.                }
{******************************************************************************}
unit inMtoModalDistribuidor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls,
  System.Actions, Vcl.ActnList,
  System.Generics.Collections,
  Data.DB, DBClient, MemDS, DBAccess, Uni,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxLabel, cxButtons, cxClasses, cxLocalization,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxStyles,
  dxSkinsCore, dxSkinBlue,
  inMtoModalAceptCancel, inLibGridTallasInline,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab;

type
  TfrmModalDistribuidor = class(TfrmModalAceptCancel)
    pnlCab        : TPanel;
    lblTitulo     : TcxLabel;
    lblLinea      : TcxLabel;
    edtLinea      : TcxTextEdit;
    pnlCuadrante  : TPanel;
    cdsCuadr      : TClientDataSet;
    dsCuadr       : TDataSource;
    cxgrdCuadr    : TcxGrid;
    cxlvlCuadr    : TcxGridLevel;
    tvCuadr       : TcxGridDBTableView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FConn         : TUniConnection;
    FUsuario      : string;
    FIdAcPivot    : Integer;
    FPosiciones   : TArrPosConjunto;
    // Snapshot inicial (almacen, posicion) -> cantidad para detectar
    // cambios al aceptar. Solo se persiste lo que cambia.
    FSnapshot     : TDictionary<string, Double>;
    procedure PrepararEstructura;
    procedure PoblarFilasYCantidades;
    procedure PersistirCambios;
    function  ClaveCelda(const ACodigoAlm: string;
                         APosicion: Integer): string; inline;
    function  GetConfirmado: Boolean;
  public
    SerieSes  : string;
    NumeroSes : string;
    LineaSes  : Integer;
    // Confirmado se deriva de sFicha ('S' tras Aceptar, 'N' tras Cancelar)
    // que gestiona el ancestro TfrmModalAceptCancel.
    property Confirmado: Boolean read GetConfirmado;
    procedure Preparar(AConn: TUniConnection;
                       const AUsuario, ASerie, ANumero: string;
                       ALinea, AIdAcPivot: Integer);
  end;

implementation

{$R *.dfm}

uses
  inLibGlobalVar;

procedure TfrmModalDistribuidor.FormCreate(Sender: TObject);
begin
  inherited;
  FSnapshot := TDictionary<string, Double>.Create;
end;

procedure TfrmModalDistribuidor.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FSnapshot);
  inherited;
end;

function TfrmModalDistribuidor.GetConfirmado: Boolean;
begin
  Result := sFicha = 'S';
end;

procedure TfrmModalDistribuidor.Preparar(AConn: TUniConnection;
                                          const AUsuario, ASerie,
                                                ANumero: string;
                                          ALinea, AIdAcPivot: Integer);
var
  oGestor : TGestorGridTallas;
  oCfg    : TGridTallasConfig;
begin
  FConn      := AConn;
  FUsuario   := AUsuario;
  SerieSes   := ASerie;
  NumeroSes  := ANumero;
  LineaSes   := ALinea;
  FIdAcPivot := AIdAcPivot;
  edtLinea.Text := IntToStr(ALinea);
  // Reusamos el helper de gestor de tallas para obtener las
  // posiciones del conjunto pivot (T01..T20 con su AV).
  oCfg := Default(TGridTallasConfig);
  oCfg.Conexion := AConn;
  oGestor := TGestorGridTallas.Create(oCfg);
  try
    FPosiciones := oGestor.GetPosicionesConjunto(AIdAcPivot);
  finally
    FreeAndNil(oGestor);
  end;
  PrepararEstructura;
  PoblarFilasYCantidades;
end;

procedure TfrmModalDistribuidor.PrepararEstructura;
var
  i: Integer;
begin
  // Construimos un ClientDataSet en memoria con columnas:
  //   CODIGO_ALM | NOMBRE_ALM | T01..TN (Float)
  // donde N = Length(FPosiciones). Las columnas talla llevan el caption
  // del valor (AV) del conjunto pivot para que el usuario las reconozca.
  cdsCuadr.Close;
  cdsCuadr.FieldDefs.Clear;
  cdsCuadr.FieldDefs.Add('CODIGO_ALM', ftString, 10);
  cdsCuadr.FieldDefs.Add('NOMBRE_ALM', ftString, 100);
  for i := 0 to High(FPosiciones) do
    cdsCuadr.FieldDefs.Add(Format('T%.2d', [i + 1]), ftFloat);
  cdsCuadr.CreateDataSet;
  // Recreamos las columnas del cxGrid bound al cds. La columna almacen
  // es read-only; las tallas editables.
  tvCuadr.ClearItems;
  with tvCuadr.CreateColumn do
  begin
    DataBinding.FieldName := 'CODIGO_ALM';
    Caption := 'Almacen';
    Options.Editing := False;
    Width := 70;
  end;
  with tvCuadr.CreateColumn do
  begin
    DataBinding.FieldName := 'NOMBRE_ALM';
    Caption := 'Nombre';
    Options.Editing := False;
    Width := 160;
  end;
  for i := 0 to High(FPosiciones) do
    with tvCuadr.CreateColumn do
    begin
      DataBinding.FieldName := Format('T%.2d', [i + 1]);
      Caption := FPosiciones[i].Valor;
      Width := 55;
    end;
end;

procedure TfrmModalDistribuidor.PoblarFilasYCantidades;
var
  oQry  : TUniQuery;
  sCod  : string;
  i     : Integer;
  iIdAv : Integer;
  rCant : Double;
  oPos  : TDictionary<Integer, Integer>; // ID_AV -> indice columna
begin
  // 1. Una fila por almacen activo. Si en el futuro hay un filtro por
  //    almacenes del usuario, basta cambiar el WHERE.
  cdsCuadr.DisableControls;
  try
    oQry := TUniQuery.Create(nil);
    try
      oQry.Connection := FConn;
      oQry.SQL.Text :=
        'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE ESACTIVO_ALM = ''S'' ' +
        ' ORDER BY CODIGO_ALM_ALM';
      oQry.Open;
      while not oQry.Eof do
      begin
        cdsCuadr.Append;
        cdsCuadr.FieldByName('CODIGO_ALM').AsString :=
          oQry.FieldByName('CODIGO_ALM_ALM').AsString;
        cdsCuadr.FieldByName('NOMBRE_ALM').AsString :=
          oQry.FieldByName('NOMBRE_ALM_ALM').AsString;
        for i := 0 to High(FPosiciones) do
          cdsCuadr.FieldByName(Format('T%.2d', [i + 1])).AsFloat := 0;
        cdsCuadr.Post;
        oQry.Next;
      end;
    finally
      FreeAndNil(oQry);
    end;
    // 2. Volcar las celdas existentes sobre las filas creadas y al
    //    snapshot para detectar cambios al aceptar.
    oPos := TDictionary<Integer, Integer>.Create;
    try
      for i := 0 to High(FPosiciones) do
        oPos.AddOrSetValue(FPosiciones[i].IdAv, i + 1);
      oQry := TUniQuery.Create(nil);
      try
        oQry.Connection := FConn;
        oQry.SQL.Text :=
          'SELECT CODIGO_ALM_SESCEL, ID_AV_PIVOT_SESCEL, CANTIDAD_SESCEL ' +
          '  FROM fza_compras_sesiones_celdas ' +
          ' WHERE SERIE_SES_SESCEL  = :s ' +
          '   AND NUMERO_SES_SESCEL = :n ' +
          '   AND LINEA_SES_SESCEL  = :l';
        oQry.ParamByName('s').AsString  := SerieSes;
        oQry.ParamByName('n').AsString  := NumeroSes;
        oQry.ParamByName('l').AsInteger := LineaSes;
        oQry.Open;
        while not oQry.Eof do
        begin
          sCod  := oQry.FieldByName('CODIGO_ALM_SESCEL').AsString;
          iIdAv := oQry.FieldByName('ID_AV_PIVOT_SESCEL').AsInteger;
          rCant := oQry.FieldByName('CANTIDAD_SESCEL').AsFloat;
          if (sCod = '') or (not oPos.ContainsKey(iIdAv)) then
          begin
            oQry.Next;
            Continue;
          end;
          if cdsCuadr.Locate('CODIGO_ALM', sCod, []) then
          begin
            cdsCuadr.Edit;
            cdsCuadr.FieldByName(Format('T%.2d', [oPos[iIdAv]])).AsFloat :=
              rCant;
            cdsCuadr.Post;
            FSnapshot.AddOrSetValue(ClaveCelda(sCod, oPos[iIdAv]), rCant);
          end;
          oQry.Next;
        end;
      finally
        FreeAndNil(oQry);
      end;
    finally
      FreeAndNil(oPos);
    end;
    cdsCuadr.First;
  finally
    cdsCuadr.EnableControls;
  end;
end;

function TfrmModalDistribuidor.ClaveCelda(const ACodigoAlm: string;
                                            APosicion: Integer): string;
begin
  Result := ACodigoAlm + '|' + IntToStr(APosicion);
end;

procedure TfrmModalDistribuidor.PersistirCambios;
var
  oQry    : TUniQuery;
  sCod    : string;
  i       : Integer;
  iIdAv   : Integer;
  rCantN  : Double;
  rCantO  : Double;
  sKey    : string;
begin
  // Diff snapshot inicial vs cds. Para cada celda con cambio:
  //   - cantidad > 0  : upsert
  //   - cantidad <= 0 : delete (si existia)
  oQry := TUniQuery.Create(nil);
  try
    oQry.Connection := FConn;
    cdsCuadr.DisableControls;
    try
      cdsCuadr.First;
      while not cdsCuadr.Eof do
      begin
        sCod := cdsCuadr.FieldByName('CODIGO_ALM').AsString;
        for i := 0 to High(FPosiciones) do
        begin
          iIdAv  := FPosiciones[i].IdAv;
          rCantN := cdsCuadr.FieldByName(Format('T%.2d', [i + 1])).AsFloat;
          sKey   := ClaveCelda(sCod, i + 1);
          if not FSnapshot.TryGetValue(sKey, rCantO) then
            rCantO := 0;
          if rCantN = rCantO then
            Continue;
          if rCantN > 0 then
          begin
            oQry.SQL.Text :=
              'INSERT INTO fza_compras_sesiones_celdas ' +
              '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, LINEA_SES_SESCEL, ' +
              '   ID_FILA_SES_SESCEL, ' +
              '   CODIGO_ALM_SESCEL, ID_AV_PIVOT_SESCEL, CANTIDAD_SESCEL, ' +
              '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
              'VALUES (:s, :n, :l, 0, :a, :p, :c, NOW(), :u, NOW(), :u) ' +
              'ON DUPLICATE KEY UPDATE CANTIDAD_SESCEL = :c, ' +
              '                        INSTANTE_MODIF  = NOW(), ' +
              '                        USUARIO_MODIF   = :u';
            oQry.ParamByName('c').AsFloat := rCantN;
            oQry.ParamByName('u').AsString := FUsuario;
          end
          else
          begin
            oQry.SQL.Text :=
              'DELETE FROM fza_compras_sesiones_celdas ' +
              ' WHERE SERIE_SES_SESCEL = :s AND NUMERO_SES_SESCEL = :n ' +
              '   AND LINEA_SES_SESCEL = :l AND CODIGO_ALM_SESCEL = :a ' +
              '   AND ID_AV_PIVOT_SESCEL = :p';
          end;
          oQry.ParamByName('s').AsString  := SerieSes;
          oQry.ParamByName('n').AsString  := NumeroSes;
          oQry.ParamByName('l').AsInteger := LineaSes;
          oQry.ParamByName('a').AsString  := sCod;
          oQry.ParamByName('p').AsInteger := iIdAv;
          oQry.ExecSQL;
        end;
        cdsCuadr.Next;
      end;
    finally
      cdsCuadr.EnableControls;
    end;
  finally
    FreeAndNil(oQry);
  end;
end;

procedure TfrmModalDistribuidor.btnAceptarClick(Sender: TObject);
begin
  // Persistir antes de delegar al ancestro: si algo falla aqui, no se
  // setea sFicha='S' ni se cierra el modal (el inherited del ancestro
  // hace ambas cosas), y el usuario puede reintentar.
  if cdsCuadr.State in [dsEdit, dsInsert] then
    cdsCuadr.Post;
  PersistirCambios;
  inherited;
end;

procedure TfrmModalDistribuidor.btnCancelarClick(Sender: TObject);
begin
  // El ancestro no asigna OnClick a btnCancelar (solo lo cubre via
  // Cancel:=True / Action2 con shortcut ESC); aqui lo enganchamos para
  // que el click del boton tambien cierre con sFicha='N'.
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

end.
