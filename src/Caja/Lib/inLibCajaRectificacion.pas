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
{    Carga una factura origen como operación rectificativa de caja.            }
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
  public
    constructor Create(
      const ARepositorio: IRepositorioConsultasCaja);
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
      if ADestino.FindField('CANTIDAD_FACLIN') <> nil then
      begin
        ADestino.FieldByName('CANTIDAD_FACLIN').AsFloat :=
          ASigno *
          Abs(
            AOrigen.FieldByName(
              'CANTIDAD_FACLIN').AsFloat);
      end;
      if Assigned(
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
      if Assigned(
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

function TServicioRectificacionCaja.Cargar(
  const ASerie, ANumero: string;
  ATipo: TTipoRectificativaCaja;
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa;
  ACabecera, ALineas: TDataSet
): TResultadoRectificacionCaja;
var
  ConsultaCabecera: IResultadoConsultaCaja;
  ConsultaLineas: IResultadoConsultaCaja;
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
    Signo);
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Tipo := ATipo;
  Result.TratamientoMovimientos :=
    ATratamientoMovimientos;
  Result.DescripcionTipo := DescripcionTipo;
end;

end.
