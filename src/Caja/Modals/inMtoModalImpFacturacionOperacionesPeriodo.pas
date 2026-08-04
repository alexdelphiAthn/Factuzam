{******************************************************************************}
{  Módulo: inMtoModalImpFacturacionOperacionesPeriodo                         }
{  Tipo: Formulario de informe                                                }
{  Descripción: Informe con banda visible por documento y fecha.              }
{******************************************************************************}
unit inMtoModalImpFacturacionOperacionesPeriodo;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, Vcl.Forms,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxCalendar, cxLabel, frxClass, frxDBSet,
  inMtoModalGenImp,
  inLibFacturacionOperacionesPeriodoPersistenciaIntf;

type
  TfrmPrintFacturacionOperacionesPeriodo = class(TfrmPrint)
    lblContexto: TcxLabel;
    edtContexto: TcxTextEdit;
    lblDesde: TcxLabel;
    dteDesde: TcxDateEdit;
    lblHasta: TcxLabel;
    dteHasta: TcxDateEdit;
    dsFacturacionPeriodo: TDataSource;
    fxdsFacturacionPeriodo: TfrxDBDataset;
  private
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FInicializado: Boolean;
    FRepositorio: IRepositorioInformeFacturacionOperacionesPeriodo;
    FResultado: IResultadoInformeFacturacionOperacionesPeriodo;
    FDatos: TDataSet;
    procedure ComponerDependencias;
  protected
    procedure DoShow; override;
  public
    class procedure Ejecutar(
      AOwner: TComponent;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDateTime);
    procedure preparar_consulta; override;
  end;

implementation

uses
  System.SysUtils,
  inLibMsgFacturacionOperacionesPeriodo,
  UniDataFacturacionOperacionesPeriodoRepositorio;

{$R *.dfm}

class procedure TfrmPrintFacturacionOperacionesPeriodo.Ejecutar(
  AOwner: TComponent;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDateTime);
var
  oFormulario: TfrmPrintFacturacionOperacionesPeriodo;
begin
  oFormulario := TfrmPrintFacturacionOperacionesPeriodo.Create(AOwner);
  try
    oFormulario.FEmpresa := AEmpresa;
    oFormulario.FAlmacen := AAlmacen;
    oFormulario.FCaja := ACaja;
    oFormulario.dteDesde.Date := AFechaDesde;
    oFormulario.dteHasta.Date := AFechaHasta;
    oFormulario.ShowModal;
  finally
    oFormulario.dsFacturacionPeriodo.DataSet := nil;
    oFormulario.FDatos := nil;
    oFormulario.FResultado := nil;
    oFormulario.FRepositorio := nil;
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmPrintFacturacionOperacionesPeriodo.DoShow;
begin
  inherited;
  ComponerDependencias;
  if not FInicializado then
  begin
    Caption := STituloInformeFacturacionOperacionesPeriodo;
    edtContexto.Text := FEmpresa + ' / ' + FAlmacen + ' / ' + FCaja;
    if dteDesde.Date <= 0 then
    begin
      dteDesde.Date := Date;
    end;
    if dteHasta.Date <= 0 then
    begin
      dteHasta.Date := Date;
    end;
    FInicializado := True;
  end;
end;

procedure TfrmPrintFacturacionOperacionesPeriodo.ComponerDependencias;
begin
  if not Assigned(FRepositorio) then
  begin
    FRepositorio := CrearRepositorioInformeFacturacionOperacionesPeriodoUniDAC(
      ConexionPrincipal);
  end;
end;

procedure TfrmPrintFacturacionOperacionesPeriodo.preparar_consulta;
var
  oSolicitud: TSolicitudInformeFacturacionOperacionesPeriodo;
begin
  inherited;
  oSolicitud.Empresa := FEmpresa;
  oSolicitud.Almacen := FAlmacen;
  oSolicitud.Caja := FCaja;
  oSolicitud.FechaDesde := Trunc(dteDesde.Date);
  oSolicitud.FechaHasta := Trunc(dteHasta.Date);
  dsFacturacionPeriodo.DataSet := nil;
  FDatos := nil;
  FResultado := FRepositorio.Consultar(oSolicitud);
  FDatos := FResultado.DataSet;
  dsFacturacionPeriodo.DataSet := FDatos;
  fxdsFacturacionPeriodo.UpdateBounds;
end;

end.
