{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalDistribuidor                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Modal "distribuidor por almacen" usado por sesiones de compra cuando      }
{    ESFORMATO_DISTRIBUIDO_SES='S'. Muestra un cuadrante almacenes x tallas    }
{    para una linea concreta de la sesion: el usuario reparte cantidades       }
{    por (almacen, talla) en vez de meter una cantidad unica por talla.        }
{                                                                              }
{    Lectura: fza_compras_sesiones_celdas filtrado por (serie, numero, linea). }
{    Escritura: upsert por (serie, numero, linea, almacen, talla).             }
{    Modelo de datos: aprovecha CODIGO_ALM_SESCEL ya existente en celdas, sin  }
{    cambios de esquema. La unica adicion en sesiones es la marca de cabecera  }
{    ESFORMATO_DISTRIBUIDO_SES (DESARROLLOS EN CURSO/ses_formato_distribuido.sql).}
{                                                                              }
{    Estado: esqueleto base. El cuadrante (TcxGrid en band-view) se completara }
{    en commit posterior con: lista de almacenes activos del usuario,          }
{    cabeceras T01..T20 segun ID_AC_PIVOT_SESLIN, INSERT/UPDATE por celda al   }
{    Aceptar, y suma agregada que el llamador (inMtoComprasSesiones) usa para  }
{    pintar el total por talla en el grid principal.                           }
{******************************************************************************}
unit inMtoModalDistribuidor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls,
  Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxLabel, cxButtons, cxClasses, cxLocalization,
  dxSkinsCore, dxSkinBlue,
  inMtoFrmBase;

type
  TfrmModalDistribuidor = class(TfrmBase)
    pnlCab        : TPanel;
    lblTitulo     : TcxLabel;
    lblLinea      : TcxLabel;
    edtLinea      : TcxTextEdit;
    pnlCuadrante  : TPanel;
    pnlBot        : TPanel;
    btnAceptar    : TcxButton;
    btnCancelar   : TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FConfirmado : Boolean;
  public
    SerieSes  : string;
    NumeroSes : string;
    LineaSes  : Integer;
    IdAcPivot : Integer;
    property Confirmado: Boolean read FConfirmado;
    // Llamar tras Create para inicializar el cuadrante.
    procedure Preparar(const ASerie, ANumero: string;
                       ALinea, AIdAcPivot: Integer);
  end;

implementation

{$R *.dfm}

procedure TfrmModalDistribuidor.FormCreate(Sender: TObject);
begin
  inherited;
  FConfirmado := False;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalDistribuidor.Preparar(const ASerie, ANumero: string;
                                          ALinea, AIdAcPivot: Integer);
begin
  SerieSes  := ASerie;
  NumeroSes := ANumero;
  LineaSes  := ALinea;
  IdAcPivot := AIdAcPivot;
  edtLinea.Text := IntToStr(ALinea);
  // TODO commit posterior: poblar pnlCuadrante con un TcxGrid de
  //   almacenes (filas) x tallas (columnas T01..T20) cargando las
  //   celdas existentes de fza_compras_sesiones_celdas filtradas por
  //   (SerieSes, NumeroSes, LineaSes). La query base es la misma que
  //   usa CargarCantidadesUnaLinea del gestor de tallas pero
  //   agrupando por CODIGO_ALM_SESCEL.
end;

procedure TfrmModalDistribuidor.btnAceptarClick(Sender: TObject);
begin
  inherited;
  // TODO commit posterior: persistir el cuadrante editado en
  //   fza_compras_sesiones_celdas usando upsert (INSERT ... ON
  //   DUPLICATE KEY UPDATE) por cada celda con cantidad <> 0. Borrar
  //   las que pasen a 0.
  FConfirmado := True;
  ModalResult := mrOk;
end;

procedure TfrmModalDistribuidor.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FConfirmado := False;
  ModalResult := mrCancel;
end;

end.
