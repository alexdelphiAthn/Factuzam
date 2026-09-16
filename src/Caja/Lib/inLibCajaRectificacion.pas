{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaRectificacion                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Carga una factura origen como rectificativa o devolución de caja.         }
{******************************************************************************}
unit inLibCajaRectificacion;

interface

uses
  Data.DB, inLibCajaTipos, inLibCajaVentaIntf;

type
  TServicioRectificacionCaja = class(
    TInterfacedObject,
    IServicioRectificacionCaja)
  private
    FRepositorio: IRepositorioConsultasCaja;
    procedure CopiarCliente(
      AOrigen, ADestino: TDataSet);
    procedure CopiarLineas(
      AOrigen, ADestino: TDataSet;
      ASigno: Double);
    procedure CopiarAtributos(AOrigen, ADestino: TDataSet);
    procedure CopiarCampoAtributo(AOrigen, ADestino: TDataSet;
      const ANombre: string);
    procedure CargarOrigen(
      const ASerie, ANumero: string;
      ASigno: Double;
      ACabecera, ALineas: TDataSet);
  public
    constructor Create(
      const ARepositorio: IRepositorioConsultasCaja);
    procedure CargarDevolucion(
      const ASerie, ANumero: string;
      ACabecera, ALineas: TDataSet);
    function Cargar(
      const ASerie, ANumero: string;
      ATipo: TTipoRectificativaCaja;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa;
      ACabecera, ALineas: TDataSet
    ): TResultadoRectificacionCaja;
  end;

implementation

uses
  System.SysUtils, inLibMsgCaja;

constructor TServicioRectificacionCaja.Create(
  const ARepositorio: IRepositorioConsultasCaja);
begin
  inherited Create;
  FRepositorio := ARepositorio;
end;

procedure TServicioRectificacionCaja.CopiarCliente(
  AOrigen, ADestino: TDataSet);
var
  Indice: Integer;
  CampoOrigen: TField;
  CampoDestino: TField;
begin
  if not (ADestino.State in [dsEdit, dsInsert]) then
  begin
    ADestino.Edit;
  end;
  for Indice := 0 to AOrigen.FieldCount - 1 do
  begin
    CampoOrigen := AOrigen.Fields[Indice];
    CampoDestino := ADestino.FindField(
      CampoOrigen.FieldName);
    if Assigned(CampoDestino) and
       (Pos('CLIENTE', CampoOrigen.FieldName) > 0) then
    begin
      CampoDestino.Value := CampoOrigen.Value;
    end;
  end;
  ADestino.FieldByName('CODIGO_CLI_FAC').AsString :=
    AOrigen.FieldByName('CODIGO_CLI_FAC').AsString;
  ADestino.Post;
end;

procedure TServicioRectificacionCaja.CopiarCampoAtributo(
  AOrigen, ADestino: TDataSet; const ANombre: string);
var
  CampoOrigen, CampoDestino: TField;
begin
  CampoOrigen := AOrigen.FindField(ANombre + '_FACLIN');
  CampoDestino := ADestino.FindField(ANombre);
  if Assigned(CampoOrigen) and Assigned(CampoDestino) and
     not CampoOrigen.IsNull then
    CampoDestino.Value := CampoOrigen.Value;
end;

procedure TServicioRectificacionCaja.CopiarAtributos(
  AOrigen, ADestino: TDataSet);
var
  Partes: TArray<string>;
  Campo: TField;
  Indice, NumeroAtributos: Integer;
  Nombre: string;
begin
  // La factura guarda ATTR*_FACLIN; Caja usa ATTR* sin ese sufijo.
  // El SKU permite recuperar el desglose de tickets antiguos.
  Partes := nil;
  Campo := AOrigen.FindField('CODIGO_UNIDAD_FACLIN');
  if Assigned(Campo) then
    Partes := Campo.AsString.Split(['/']);
  NumeroAtributos := 0;
  Campo := AOrigen.FindField('NUM_ATRIBUTOS_FACLIN');
  if Assigned(Campo) then
    NumeroAtributos := Campo.AsInteger;
  for Indice := 1 to 5 do
  begin
    Nombre := 'ATTR' + IntToStr(Indice);
    CopiarCampoAtributo(AOrigen, ADestino, Nombre + '_NOMBRE');
    CopiarCampoAtributo(AOrigen, ADestino, Nombre + '_VALOR');
    Campo := ADestino.FindField(Nombre + '_VALOR');
    if Assigned(Campo) then
    begin
      if (Trim(Campo.AsString) = '') and (Indice < Length(Partes)) then
        Campo.AsString := Partes[Indice];
      if (Trim(Campo.AsString) <> '') and (Indice > NumeroAtributos) then
        NumeroAtributos := Indice;
    end;
  end;
  Campo := ADestino.FindField('NUM_ATRIBUTOS_REQ_FACTURA_LINEA');
  if Assigned(Campo) then
    Campo.AsInteger := NumeroAtributos;
end;

procedure TServicioRectificacionCaja.CopiarLineas(
  AOrigen, ADestino: TDataSet;
  ASigno: Double);
var
  Indice: Integer;
  CampoOrigen: TField;
  CampoDestino: TField;
begin
  ADestino.DisableControls;
  try
    while not AOrigen.Eof do
    begin
      ADestino.Append;
      for Indice := 0 to AOrigen.FieldCount - 1 do
      begin
        CampoOrigen := AOrigen.Fields[Indice];
        CampoDestino := ADestino.FindField(
          CampoOrigen.FieldName);
        if Assigned(CampoDestino) and
           (not CampoOrigen.IsNull) then
        begin
          CampoDestino.Value := CampoOrigen.Value;
        end;
      end;
      CopiarAtributos(AOrigen, ADestino);
      // La sustitutiva conserva ventas, devoluciones y líneas gratuitas.
      // Sólo diferencias y devoluciones fuerzan el signo negativo.
      if (ASigno < 0) and
         (ADestino.FindField('CANTIDAD_FACLIN') <> nil) then
      begin
        ADestino.FieldByName('CANTIDAD_FACLIN').AsFloat :=
          ASigno *
          Abs(
            AOrigen.FieldByName(
              'CANTIDAD_FACLIN').AsFloat);
      end;
      if (ASigno < 0) and Assigned(
           ADestino.FindField('TOTAL_FACLIN')) and
         Assigned(
           AOrigen.FindField('TOTAL_FACLIN')) then
      begin
        ADestino.FieldByName('TOTAL_FACLIN').AsCurrency :=
          ASigno *
          Abs(
            AOrigen.FieldByName(
              'TOTAL_FACLIN').AsCurrency);
      end;
      if (ASigno < 0) and Assigned(
           ADestino.FindField(
             'TOTAL_FAC_SIVA_FACLIN')) and
         Assigned(
           AOrigen.FindField(
             'TOTAL_FAC_SIVA_FACLIN')) then
      begin
        ADestino.FieldByName(
          'TOTAL_FAC_SIVA_FACLIN').AsCurrency :=
          ASigno *
          Abs(
            AOrigen.FieldByName(
              'TOTAL_FAC_SIVA_FACLIN').AsCurrency);
      end;
      ADestino.Post;
      AOrigen.Next;
    end;
  finally
    ADestino.EnableControls;
  end;
end;

procedure TServicioRectificacionCaja.CargarOrigen(
  const ASerie, ANumero: string;
  ASigno: Double;
  ACabecera, ALineas: TDataSet);
var
  ConsultaCabecera: IResultadoConsultaCaja;
  ConsultaLineas: IResultadoConsultaCaja;
begin
  if (not Assigned(ACabecera)) or
     (not Assigned(ALineas)) then
  begin
    raise Exception.Create(
      'Los datos de la operación de caja no están configurados');
  end;
  ConsultaCabecera :=
    FRepositorio.ConsultarCabeceraFactura(
      ASerie,
      ANumero);
  if ConsultaCabecera.DataSet.IsEmpty then
  begin
    raise Exception.Create(
      Format(
        SErrorBorradorRectificarCajaNoEncontrado,
        [ASerie, ANumero]));
  end;
  CopiarCliente(
    ConsultaCabecera.DataSet,
    ACabecera);
  ConsultaLineas :=
    FRepositorio.ConsultarLineasFactura(
      ASerie,
      ANumero);
  CopiarLineas(
    ConsultaLineas.DataSet,
    ALineas,
    ASigno);
end;

procedure TServicioRectificacionCaja.CargarDevolucion(
  const ASerie, ANumero: string;
  ACabecera, ALineas: TDataSet);
begin
  CargarOrigen(
    ASerie,
    ANumero,
    -1,
    ACabecera,
    ALineas);
end;

function TServicioRectificacionCaja.Cargar(
  const ASerie, ANumero: string;
  ATipo: TTipoRectificativaCaja;
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa;
  ACabecera, ALineas: TDataSet
): TResultadoRectificacionCaja;
var
  Signo: Double;
  DescripcionTipo: string;
begin
  case ATipo of
    trcDiferencias:
      begin
        Signo := -1;
        DescripcionTipo := 'POR DIFERENCIAS';
      end;
    trcSustitutiva:
      begin
        Signo := 1;
        DescripcionTipo := 'SUSTITUTIVA';
      end;
  else
    begin
      raise Exception.Create(
        SErrorTipoRectificativaCajaNoIndicado);
    end;
  end;
  CargarOrigen(
    ASerie,
    ANumero,
    Signo,
    ACabecera,
    ALineas);
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Tipo := ATipo;
  Result.TratamientoMovimientos :=
    ATratamientoMovimientos;
  Result.DescripcionTipo := DescripcionTipo;
end;

end.
