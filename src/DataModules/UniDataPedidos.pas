unit UniDataPedidos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, inMtoPrincipal, frxClass, frxDBSet;

type
  TdmPedidos = class(TdmBase)
    unqryPedidosLineas: TUniQuery;
    dsPedidosLineas: TDataSource;
    unqryLinPedido: TUniQuery;
    dsLinPedido: TDataSource;
    unqryEmpDataPedido: TUniQuery;
    unqryCliDataPedido: TUniQuery;
    unqryArtDataLinPedido: TUniQuery;
    unstrdprcCrearPedido: TUniStoredProc;
    unstrdprcGetContadorPedido: TUniStoredProc;
    unstrdprcGetContador: TUniStoredProc;
    fxdsPrintPed: TfrxDBDataset;
    fxdstPrintLinPed: TfrxDBDataset;
    unqryTablaG: TUniQuery;
    unqryPerfiles: TUniQuery;
    dsPerfiles: TDataSource;

    procedure DataModuleCreate(Sender: TObject);
    procedure unqryPedidosAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosBeforePost(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoPedido;
    procedure GetCodigoAutoCliente;
    procedure CopiarPedidoaFactura;
    procedure CrearPedido;
    procedure CalcularTotalesPedido;
  end;

var
  dmPedidos: TdmPedidos;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TdmPedidos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryPedidosLineas.Connection := inLibGlobalVar.oConn;
  unqryPedidosLineas.Open;
end;

procedure TdmPedidos.unqryPedidosAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FieldByName('FECHA_PED').AsDateTime := Date;
    FieldByName('CODIGO_EMP_PED').AsString := '0';
    FieldByName('CODIGO_CLI_PED').AsString := '0';
    // Inicializar otros campos según sea necesario
  end;
end;

procedure TdmPedidos.unqryPedidosBeforePost(DataSet: TDataSet);
begin
  inherited;
  if (unqryTablaG.FieldByName('NUMERO_PED').AsString = '0') then
    GetCodigoAutoPedido;
  if (unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString = '0') then
    GetCodigoAutoPedido;
  CalcularTotalesPedido;
end;

procedure TdmPedidos.unqryPedidosLineasAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryPedidosLineas do
  begin
    FieldByName('NUMERO_PED_PEDLIN').AsString :=
                                 unqryTablaG.FieldByName('NUMERO_PED').AsString;
    FieldByName('SERIE_PED_PEDLIN').AsString :=
                               unqryTablaG.FieldByName('SERIE_PED').AsString;

  end;
end;

procedure TdmPedidos.unqryPedidosLineasBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Cálculos para la línea del pedido
end;

procedure TdmPedidos.GetCodigoAutoPedido;
begin
  with unstrdprcGetContadorPedido do
  begin
    ParamByName('ptipodoc').AsString := 'PE';
    ParamByName('pUSUARIO').AsString := oUser;
    ExecProc;
    unqryTablaG.FieldByName('NUMERO_PED').AsString := ParamByName('pcont').AsString;
  end;
end;

procedure TdmPedidos.GetCodigoAutoCliente;
begin
  with unstrdprcGetContador do
  begin
    ParamByName('ptipodoc').AsString := 'CL';
    ParamByName('pUSUARIO').AsString := oUser;
    ExecProc;
    unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString :=
                            ParamByName('pcont').AsString;
  end;
end;

procedure TdmPedidos.CopiarPedidoaFactura;
begin
  // Implementar la lógica para copiar un pedido a una factura
end;

procedure TdmPedidos.CrearPedido;
begin
  with unstrdprcCrearPedido do
  begin
    // Configurar los parámetros necesarios
    ExecProc;
  end;
end;

procedure TdmPedidos.CalcularTotalesPedido;
begin
  // Implementar la lógica para calcular los totales del pedido
end;

end.