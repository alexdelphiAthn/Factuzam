{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasListado                                        }
{    Tipo:       Adaptador de persistencia (UniDAC)                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sentencia del listado de facturas y disponibilidad de la cola AEAT.       }
{******************************************************************************}
unit UniDataFacturasListado;

interface

uses
  Data.DB, Uni,
  inLibFacturasPresentadorListado;

function CrearPreparadorListadoFacturasUniDAC(
  AConexion: TUniConnection): IPreparadorListadoFacturas;

implementation

uses
  System.SysUtils,
  inLibSqlSeguro,
  inLibVerifactuEsquemaIntf,
  UniDataVerifactuEsquema;

const
  // Vistas de listado admitidas: la base y las dos filtradas por TIPO_FAC.
  cVistasListadoFacturas: array[0..2] of string = (
    'vi_facturas',
    'vi_facturas_normales',
    'vi_facturas_simplificadas');

type
  TPreparadorListadoFacturasUniDAC = class(TInterfacedObject,
    IPreparadorListadoFacturas)
  private
    FConexion: TUniConnection;
    function SentenciaConEstadoCola(const AVista: string): string;
    function SentenciaSinEstadoCola(const AVista: string): string;
  public
    constructor Create(AConexion: TUniConnection);
    function EstadoColaDisponible(out AMensaje: string): Boolean;
    procedure PrepararListado(
      AConsulta: TDataSet;
      const AVista: string;
      AIncluirEstadoCola: Boolean);
  end;

constructor TPreparadorListadoFacturasUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TPreparadorListadoFacturasUniDAC.EstadoColaDisponible(
  out AMensaje: string): Boolean;
var
  oRepositorio: IRepositorioEsquemaVerifactu;
begin
  oRepositorio := CrearRepositorioEsquemaVerifactuUniDAC(FConexion);
  Result := oRepositorio.ColaDisponible(AMensaje);
end;

function TPreparadorListadoFacturasUniDAC.SentenciaConEstadoCola(
  const AVista: string): string;
begin
  // Columna Cola Verifactu: último estado en fza_verifactu_cola de cada
  // factura (PENDIENTE/PROCESANDO/ENVIADA/ERROR; NULL si nunca se encoló).
  Result :=
    'SELECT v.*, ' +
    '       (SELECT c.ESTADO_VFCOLA ' +
    '          FROM fza_verifactu_cola c ' +
    '         WHERE c.SERIE_FAC_VFCOLA  = v.SERIE_FAC ' +
    '           AND c.NUMERO_FAC_VFCOLA = v.NUMERO_FAC ' +
    '         ORDER BY c.ID_VFCOLA DESC ' +
    '         LIMIT 1) AS ESTADO_VFCOLA ' +
    '  FROM ' + AVista + ' v ' +
    ' ORDER BY v.FECHA_FAC DESC, v.NUMERO_FAC DESC';
end;

function TPreparadorListadoFacturasUniDAC.SentenciaSinEstadoCola(
  const AVista: string): string;
begin
  Result :=
    'SELECT v.*, '''' AS ESTADO_VFCOLA ' +
    '  FROM ' + AVista + ' v ' +
    ' ORDER BY v.FECHA_FAC DESC, v.NUMERO_FAC DESC';
end;

procedure TPreparadorListadoFacturasUniDAC.PrepararListado(
  AConsulta: TDataSet;
  const AVista: string;
  AIncluirEstadoCola: Boolean);
var
  sVista: string;
begin
  if AConsulta is TUniQuery then
  begin
    // Lista blanca: el nombre de la vista nunca llega de datos externos,
    // pero se valida igual antes de componer la sentencia.
    sVista := DelimitarIdentificadorSql(AVista, cVistasListadoFacturas);
    if AIncluirEstadoCola then
      TUniQuery(AConsulta).SQL.Text := SentenciaConEstadoCola(sVista)
    else
      TUniQuery(AConsulta).SQL.Text := SentenciaSinEstadoCola(sVista);
  end;
end;

function CrearPreparadorListadoFacturasUniDAC(
  AConexion: TUniConnection): IPreparadorListadoFacturas;
begin
  Result := TPreparadorListadoFacturasUniDAC.Create(AConexion);
end;

end.
