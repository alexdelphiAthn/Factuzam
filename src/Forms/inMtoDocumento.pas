{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDocumento                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ancestro común para mantenimientos de documentos de compra y venta.       }
{******************************************************************************}
unit inMtoDocumento;

interface

uses
  Data.DB, cxGridDBTableView, inMtoGen, inLibDocumentoIntf,
  inLibValidacionDocumento;

type
  TfrmMtoDocumento = class(TfrmMtoGen)
  private
    FConfiguracionDocumento: TConfiguracionDocumento;
    FEstrategiaDocumento: IEstrategiaDocumento;
    FVistaLineasDocumento: TcxGridDBTableView;
  protected
    procedure InicializarDocumento(
      const AConfiguracion: TConfiguracionDocumento);
    function ConfiguracionPersistenciaDocumento(
      const AMensajeCabeceraNoDisponible: string
    ): TConfiguracionDocumento;
    function ConfiguracionTallasDocumento:
      TConfiguracionDocumento;
    procedure AsignarVistaLineasDocumento(
      AVista: TcxGridDBTableView);
    property ConfiguracionDocumento: TConfiguracionDocumento
      read FConfiguracionDocumento;
    property EstrategiaDocumento: IEstrategiaDocumento
      read FEstrategiaDocumento;
  public
    destructor Destroy; override;
    procedure ResolverArtSkuActivo(
      out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
    function SqlRestriccionUsuario: string; override;
  end;

implementation

uses
  System.SysUtils, inLibColumnasDocumento, inLibDocumento,
  inLibFiltroUsuario, inLibMsgCompras, inLibMsgComun;

destructor TfrmMtoDocumento.Destroy;
begin
  FEstrategiaDocumento := nil;
  FVistaLineasDocumento := nil;
  inherited;
end;

procedure TfrmMtoDocumento.InicializarDocumento(
  const AConfiguracion: TConfiguracionDocumento);
begin
  ValidarConfiguracionDocumento(AConfiguracion);
  FConfiguracionDocumento := AConfiguracion;
  FEstrategiaDocumento :=
    CrearEstrategiaDocumento(FConfiguracionDocumento);
end;

procedure TfrmMtoDocumento.AsignarVistaLineasDocumento(
  AVista: TcxGridDBTableView);
begin
  FVistaLineasDocumento := AVista;
end;

function TfrmMtoDocumento.ConfiguracionPersistenciaDocumento(
  const AMensajeCabeceraNoDisponible: string
): TConfiguracionDocumento;
begin
  Result := FConfiguracionDocumento;
  Result.MensajeCabeceraNoDisponible :=
    AMensajeCabeceraNoDisponible;
end;

function TfrmMtoDocumento.ConfiguracionTallasDocumento:
  TConfiguracionDocumento;
begin
  Result := FConfiguracionDocumento;
  Result.MensajeCabeceraNoDisponible := Format(
    SErrorCrearSeleccionarDocumentoAntesLineas,
    [FConfiguracionDocumento.NombreSingular]);
  Result.DocumentoConArticulo :=
    FConfiguracionDocumento.NombreSingular;
  Result.CampoEstadoCabecera :=
    FConfiguracionDocumento.CampoPivoteCabecera;
  Result.ValorEstadoCabecera := 'N';
  Result.CancelarLineaSoloSinNumero := True;
end;

procedure TfrmMtoDocumento.ResolverArtSkuActivo(
  out ACodArt, ACodSku: string);
begin
  ResolverArtSkuActivoDocumento(
    FVistaLineasDocumento, ACodArt, ACodSku);
end;

function TfrmMtoDocumento.DataSourcesParaFoto:
  TArray<TDataSource>;
begin
  Result := DataSourcesParaFotoDocumento(
    dsTablaG, FVistaLineasDocumento);
end;

function TfrmMtoDocumento.SqlRestriccionUsuario: string;
begin
  Result := SqlFiltroDocumento(
    ContextoSesion,
    ParametrosApp,
    FConfiguracionDocumento.PrefijoCabecera,
    FConfiguracionDocumento.FiltraCaja);
end;

end.
