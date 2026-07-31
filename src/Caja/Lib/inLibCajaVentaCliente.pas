{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajaVentaCliente                                         }
{    Tipo:       Dominio                                                       }
{ Version:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Reglas del cambio de cliente en la venta de caja: limpieza de las         }
{    lineas de deposito del cliente anterior, cabecera de venta al             }
{    contado, volcado del cliente a la cabecera y decision de autocarga        }
{    de depositos.                                                             }
{                                                                              }
{    Sale de TfrmMtoOpeCaja.btnCodigoClientePropertiesValidate, donde          }
{    vivia mezclado con el grid y las etiquetas. No conoce formularios,        }
{    DevExpress ni UniDAC: trabaja sobre TDataSet y records de                 }
{    inLibCajaVentaIntf, y se prueba con un TClientDataSet en memoria          }
{    (PLAN_SOLID.md Fase 3; LIBRO_DE_ESTILO_DELPHI.md 14.4).                   }
{******************************************************************************}
unit inLibCajaVentaCliente;

interface

uses
  Data.DB,
  inLibCajaVentaIntf;

// Una linea vino de deposito cuando VIENE_DE_DEPOSITO es 'S' o 'A'.
// La misma regla protege el borrado por atajo en la ventana de caja.
function EsLineaDeposito(const AVieneDeDeposito: string): Boolean;

// Cierra la linea pendiente (cancela la vacia, graba la que tiene
// articulo) y borra las lineas de deposito del cliente anterior.
procedure LimpiarLineasDeposito(ALineas: TDataSet);

// Deja la cabecera como venta al contado: datos del cliente vacios,
// tarifa por defecto e impuestos incluidos.
procedure EscribirCabeceraVentaContado(
  ACabecera: TDataSet;
  const ATarifaDefault: string);

// Vuelca el cliente a la cabecera de la venta. La forma de pago del
// cliente solo pisa la de la cabecera cuando viene informada.
procedure EscribirCabeceraClienteVenta(
  ACabecera: TDataSet;
  const ACliente: TClienteCaja);

// Los depositos solo se cargan solos si el cliente permite deuda y el
// parametro de autocarga esta activo.
function DebeCargarDepositosCliente(
  const AEsPermiteDeuda: string;
  AAutoCargar: Boolean): Boolean;

implementation

uses
  System.SysUtils;

function EsLineaDeposito(const AVieneDeDeposito: string): Boolean;
begin
  Result := (AVieneDeDeposito = 'S') or (AVieneDeDeposito = 'A');
end;

procedure LimpiarLineasDeposito(ALineas: TDataSet);
begin
  if Assigned(ALineas) and ALineas.Active then
  begin
    // Linea a medio meter: la vacia se cancela para evitar el Abort de
    // BeforePost; la que ya tiene articulo se graba.
    if ALineas.State in [dsInsert, dsEdit] then
    begin
      if Trim(ALineas.FieldByName('CODIGO_ART_FACLIN').AsString) = '' then
        ALineas.Cancel
      else
        ALineas.Post;
    end;
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        if EsLineaDeposito(
             ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString) then
          ALineas.Delete
        else
          ALineas.Next;
      end;
    finally
      ALineas.EnableControls;
    end;
  end;
end;

procedure EscribirCabeceraVentaContado(
  ACabecera: TDataSet;
  const ATarifaDefault: string);
begin
  ACabecera.Edit;
  ACabecera.FieldByName('CODIGO_CLI_FAC').AsString := '';
  ACabecera.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('NIF_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('MOVIL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('DIRECCION1_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('DIRECCION2_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('POBLACION_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('PROVINCIA_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString := '';
  ACabecera.FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString := '';
  ACabecera.FieldByName(
    'CODIGO_UNIDAD_TRAMITADORA_FAC').AsString := '';
  ACabecera.FieldByName(
    'TARIFA_ARTICULO_CLIENTE_FAC').AsString := ATarifaDefault;
  ACabecera.FieldByName(
    'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString := 'S';
end;

procedure EscribirCabeceraClienteVenta(
  ACabecera: TDataSet;
  const ACliente: TClienteCaja);
begin
  ACabecera.Edit;
  ACabecera.FieldByName('CODIGO_CLI_FAC').AsString :=
    ACliente.Codigo;
  ACabecera.FieldByName('RAZON_SOCIAL_CLIENTE_FAC').AsString :=
    ACliente.RazonSocial;
  ACabecera.FieldByName('NIF_CLIENTE_FAC').AsString :=
    ACliente.Nif;
  ACabecera.FieldByName('MOVIL_CLIENTE_FAC').AsString :=
    ACliente.Movil;
  ACabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString :=
    ACliente.Email;
  ACabecera.FieldByName('DIRECCION1_CLIENTE_FAC').AsString :=
    ACliente.Direccion1;
  ACabecera.FieldByName('DIRECCION2_CLIENTE_FAC').AsString :=
    ACliente.Direccion2;
  ACabecera.FieldByName('POBLACION_CLIENTE_FAC').AsString :=
    ACliente.Poblacion;
  ACabecera.FieldByName('PROVINCIA_CLIENTE_FAC').AsString :=
    ACliente.Provincia;
  ACabecera.FieldByName('CODIGO_POSTAL_CLIENTE_FAC').AsString :=
    ACliente.CodigoPostal;
  ACabecera.FieldByName('CODIGO_PAI_CLIENTE_FAC').AsString :=
    ACliente.CodigoPais;
  ACabecera.FieldByName('NOMBRE_PAI_CLIENTE_FAC').AsString :=
    ACliente.NombrePais;
  ACabecera.FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString :=
    ACliente.CodigoOficinaContable;
  ACabecera.FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString :=
    ACliente.CodigoOrganoGestor;
  ACabecera.FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString :=
    ACliente.CodigoUnidadTramitadora;
  ACabecera.FieldByName('ESIVA_RECARGO_CLIENTE_FAC').AsString :=
    ACliente.EsIvaRecargo;
  ACabecera.FieldByName('ESIVA_EXENTO_CLIENTE_FAC').AsString :=
    ACliente.EsIvaExento;
  ACabecera.FieldByName(
    'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC').AsString :=
    ACliente.EsRegimenEspecialAgricola;
  ACabecera.FieldByName('ESRETENCIONES_CLIENTE_FAC').AsString :=
    ACliente.EsRetenciones;
  ACabecera.FieldByName('ESINTRACOMUNITARIO_CLIENTE_FAC').AsString :=
    ACliente.EsIntracomunitario;
  if Trim(ACliente.CodigoFormaPago) <> '' then
    ACabecera.FieldByName('FORMA_PAGO_FAC').AsString :=
      ACliente.CodigoFormaPago;
  ACabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString :=
    ACliente.TarifaArticulo;
end;

function DebeCargarDepositosCliente(
  const AEsPermiteDeuda: string;
  AAutoCargar: Boolean): Boolean;
begin
  Result := SameText(AEsPermiteDeuda, 'S') and AAutoCargar;
end;

end.
