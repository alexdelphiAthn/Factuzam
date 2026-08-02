{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddBlockInventario                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de carga masiva de SKUs en un inventario.                           }
{    Hereda de AddBlockBase y aplica filtros propios de inventario.            }
{******************************************************************************}
unit inMtoModalAddBlockInventario;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  cxGraphics, cxControls, cxLookAndFeels, cxClasses, cxContainer, cxEdit,
  cxLabel, cxButtons, cxTextEdit, cxCheckBox, cxRadioGroup,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid,
  inMtoModalAddBlockBase, cxLookAndFeelPainters, Vcl.Menus, cxFilter,
  cxCustomData, cxStyles, dxScrollbarAnnotations, cxTL, cxMaskEdit, cxDBData,
  cxCurrencyEdit, Vcl.ComCtrls, dxCore, cxDateUtils, JvComponentBase,
  JvEnterTab, cxLocalization, cxSplitter, cxSpinEdit, cxDropDownEdit,
  cxCalendar, cxCustomListBox, cxCheckListBox, cxGroupBox, cxInplaceContainer,
  cxDBTL, cxTLData, cxPC,
  inLibCargaMasivaArticulosPersistenciaIntf;

type
  TAddBlockInventarioResult = record
    Aceptado          : Boolean;
    NumLineas         : Integer;        // SKUs (lineas) insertadas
    NumArticulos      : Integer;        // articulos distintos cubiertos
    ArticulosCodigos  : TArray<string>;
    Empresa, Almacen, Serie, Nro: string;
  end;

  TfrmModalAddBlockInventario = class(TfrmModalAddBlockBase)
    lblInventarioInfo: TcxLabel;
    lblNotaCarga: TcxLabel;

    // Columnas extra del preview
    colPrevSkusConStock: TcxGridDBColumn;
    colPrevPMPActual: TcxGridDBColumn;

    procedure FormCreate(Sender: TObject);

  protected
    FResultadoInv : TAddBlockInventarioResult;
    FEmpresa, FAlmacen, FSerie, FNro: string;

    function  ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
    override;
    function ContextoCargaMasiva: TContextoCargaMasivaArticulos; override;
    function  TextoConfirmacion(ANumPendientes: Integer): string; override;
    function  TextoExito(ANumInsertados: Integer): string; override;
    function  TextoExcluirYaCargados: string; override;

    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean; override;

  public
    class function Ejecutar(
      AOwner: TComponent;
      const AEmpresa, AAlmacen, ASerie,
      ANro: string): TAddBlockInventarioResult;
    property ResultadoInv: TAddBlockInventarioResult read FResultadoInv;
  end;

implementation

{$R *.dfm}

uses
  inLibUser, inLibMsgArticulos;

class function TfrmModalAddBlockInventario.Ejecutar(
  AOwner: TComponent;
  const AEmpresa, AAlmacen, ASerie, ANro: string): TAddBlockInventarioResult;
var
  frm: TfrmModalAddBlockInventario;
  i  : Integer;
begin
  frm := TfrmModalAddBlockInventario.Create(AOwner);
  try
    frm.FEmpresa := AEmpresa;
    frm.FAlmacen := AAlmacen;
    frm.FSerie   := ASerie;
    frm.FNro     := ANro;
    frm.Inicializar;

    // Pre-marcar el almacen del inventario en la pestana de stock.
    // En inventario el filtro de stock se aplica SIEMPRE en el almacen
    // del propio inventario.
    for i := 0 to frm.chkLstAlmacenes.Items.Count - 1 do
      if (frm.chkLstAlmacenes.Items[i].ItemObject is TStringList) and
         (TStringList(frm.chkLstAlmacenes.Items[i].ItemObject).Count > 0) and
         (TStringList(
           frm.chkLstAlmacenes.Items[i].ItemObject)[0] = AAlmacen) then
      begin
        frm.chkLstAlmacenes.Items[i].Checked := True;
        Break;
      end;

    frm.lblInventarioInfo.Caption :=
      Format(SCaptionInventarioDestino,
             [AEmpresa, AAlmacen, ASerie, ANro]);

    frm.ShowModal;
    Result := frm.FResultadoInv;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalAddBlockInventario.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Caption := STituloAnadirBloqueInventario;

  // En inventario el stock importa siempre — lo activamos por defecto
  chkSoloConStock.Checked := True;

  FResultadoInv.Aceptado := False;
end;

// ============================================================================
//   Overrides de la base
// ============================================================================

function TfrmModalAddBlockInventario.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  Result := True;
  AMensaje := '';
  if (FEmpresa = '') or (FAlmacen = '') or (FSerie = '') or (FNro = '') then
  begin
    Result := False;
    AMensaje := SErrorDestinoInventarioAddBlock;
  end;
end;

function TfrmModalAddBlockInventario.ContextoCargaMasiva:
  TContextoCargaMasivaArticulos;
begin
  Result.Modo := mcInventario;
  Result.EmpresaInventario := FEmpresa;
  Result.AlmacenInventario := FAlmacen;
  Result.SerieInventario := FSerie;
  Result.NumeroInventario := FNro;
end;

function TfrmModalAddBlockInventario.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(SPreguntaConfirmarInventarioAddBlock,
    [ANumPendientes, FEmpresa, FAlmacen, FSerie, FNro]);
end;

function TfrmModalAddBlockInventario.TextoExito(
  ANumInsertados: Integer): string;
begin
  Result := Format(SInfoLineasInventarioAddBlock,
    [ANumInsertados]);
end;

function TfrmModalAddBlockInventario.TextoExcluirYaCargados: string;
begin
  Result := 'Excluir articulos ya en el inventario';
end;

// ============================================================================
//   Insercion real
// ============================================================================

function TfrmModalAddBlockInventario.EjecutarInsercion(
  out ANumInsertados: Integer;
  out ACodigos: TArray<string>): Boolean;
var
  oParametros: TParametrosInsercionInventario;
  oResultado: TResultadoInsercionCargaMasiva;
begin
  Result := False;
  ANumInsertados := 0;
  SetLength(ACodigos, 0);
  if Assigned(DatosPreview) and DatosPreview.Active and
     (DatosPreview.RecordCount > 0) then
  begin
    oParametros.Empresa := FEmpresa;
    oParametros.Almacen := FAlmacen;
    oParametros.Serie := FSerie;
    oParametros.Numero := FNro;
    oParametros.Usuario := IdentidadSesion.Usuario;
    try
      oResultado := InsercionesCargaMasiva.InsertarInventario(
        ConsultaPreview,
        oParametros);
      ANumInsertados := oResultado.NumeroLineas;
      ACodigos := oResultado.CodigosArticulo;
      FResultadoInv.Aceptado := True;
      FResultadoInv.NumLineas := oResultado.NumeroLineas;
      FResultadoInv.NumArticulos := oResultado.NumeroArticulos;
      FResultadoInv.ArticulosCodigos := ACodigos;
      FResultadoInv.Empresa := FEmpresa;
      FResultadoInv.Almacen := FAlmacen;
      FResultadoInv.Serie := FSerie;
      FResultadoInv.Nro := FNro;
      Result := True;
    except
      on E: Exception do
      begin
        ShowMessage(SErrorInsertarLineasInventarioAddBlock + E.Message);
      end;
    end;
  end;
end;

end.
