{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaParam                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de configuración del punto de venta.                           }
{    Definición, carga desde BBDD y acceso tipado a opciones de caja.          }
{******************************************************************************}
unit inLibCajaParam;

interface

uses
  inLibParametrosIntf, inLibParametrosBase, inLibPerfilesUsuarioIntf;

type
  TParametrosCaja = class(
    TParametrosBase,
    IParametrosCaja
  )
  private
    procedure InicializarParametrosCaja(
      const AUsuario, AGrupo: string);
  public
    constructor Create(const APerfilesUsuario: IPerfilesUsuario);
    function NivelesFamiliaArqueo: Integer;
    function TarifaDefecto: string;
  end;

function CrearParametrosCaja(
  const APerfilesUsuario: IPerfilesUsuario;
  const AUsuario, AGrupo: string
): IParametrosCaja;

implementation

uses
  System.SysUtils;

{ TParametrosCaja }

constructor TParametrosCaja.Create(
  const APerfilesUsuario: IPerfilesUsuario);
begin
  inherited Create(
    APerfilesUsuario,
    'frmMtoCajaParam',
    TArray<string>.Create(
      'WindowState',
      'Left',
      'Top',
      'Width',
      'Height',
      'Divider'
    )
  );
end;

procedure TParametrosCaja.InicializarParametrosCaja(
  const AUsuario, AGrupo: string);
begin
  // --- Control de Artículos ---
  RegistrarParametro('Control de Artículos',
                     'vgerChkExistOnly',
                     'Permitir sólo artículos que existan',
                     tpBoolean,
                     'True');
  RegistrarParametro('Control de Artículos',
                     'vgerChkStockOnly',
                     'Permitir sólo artículos con stock',
                     tpBoolean,
                     'False');

  // --- Configuración de Caja ---
  RegistrarParametro('Configuración de Caja',
                     'vgerShowCajaSelection',
                     'Presentar selección de caja',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerFillEmpleadoDefecto',
                     'Rellenar empleado por defecto al abrir',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerDefTarifa',
                     'Tarifa por defecto en caja',
                     tpString,
                     'PVP');
  RegistrarParametro('Configuración de Caja',
                     'vgerMaxOpPending',
                     'Número de operaciones pendientes',
                     tpInteger,
                     '5');
  RegistrarParametro('Configuración de Caja',
                     'vgerAutoLoadDepositos',
                     'Cargar depósitos automáticamente al seleccionar cliente',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerAgruparUnidadesIguales',
                     'Agrupar unidades iguales en una sola línea',
                     tpBoolean,
                     'False');
  RegistrarParametro('Servicios web',
                     'vgerEnviarVentasWS',
                     'Enviar ventas completas al webservice de respaldo',
                     tpBoolean,
                     'False');

  // --- Devoluciones y Vales ---
  RegistrarParametro('Devoluciones y Vales',
                     'vgerReqRefDevolucion',
                     'Pedir referencia en devoluciones',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerRecuperaValePIN',
                     'Recuperar Vale sólo con PIN',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerCaducidadDefVale',
                     'Caducidad por defecto en vale',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerDiasCaducidadVale',
                     'Días hasta caducidad en vale',
                     tpInteger,
                     '365');


  // --- Avisos y Búsquedas ---
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerAvisoStockWarning',
                     'Aviso en artículos sin stock',
                     tpString,
                     'Artículo sin stock. Compruebe stock en almacén.');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtStockOnly',
                     'Búsqueda de artículos sólo con stock',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtTarifaOnly',
                     'Búsqueda de artículos sólo con tarifa',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerStockTodosColores',
                     'Mostrar todos los colores por separado en el stock',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerMoverLineaIdentif',
                     'Mover linea al identificar artículo',
                     tpBoolean,
                     'False');

  // --- Lector de Código de Barras ---
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanVelActivo',
                     'Detectar lecturas por velocidad de tecleo (código + CR)',
                     tpBoolean,
                     'True');
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanVelMs',
                     'Máx. ms entre teclas para considerarlo lectura',
                     tpInteger,
                     '40');
  RegistrarParametro('Lector de Código de Barras',
                     'vgerScanMinLong',
                     'Longitud mínima del código para aceptar la lectura',
                     tpInteger,
                     '4');

  // --- Impresión ---
  RegistrarParametro('Impresión',
                     'vgerDefPrinter',
                     'Nombre impresora de tickets',
                     tpString,
                     '');
  RegistrarParametro('Impresión',
                     'vgerTipoImpresion',
                     'Tipo de Impresión tickets',
                     tpString,
                     'ESC POS');
  RegistrarParametro('Impresión',
                     'vgerFormatoImpPredet',
                     'Formato de impresión predeterminado',
                     tpString,
                     '');

  // --- Empleado ---
  RegistrarParametro('Empleado',
                     'vgerCodEmpleadoDefecto',
                     'Código de empleado por defecto',
                     tpString,
                     '');
  RegistrarParametro('Empleado',
                     'vgerShowEmpleadoLinea',
                     'Mostrar empleado en linea de caja',
                     tpBoolean,
                     'True');

  // --- Permisos Extra ---
  RegistrarParametro('Permisos Extra',
                     'vgerArqueoTarjetas',
                     'Permitir Arqueo de Tarjetas',
                     tpBoolean,
                     'False');
  RegistrarParametro('Permisos Extra',
                     'vgerVentasCredito',
                     'Permitir Ventas a Crédito',
                     tpBoolean,
                     'True');
  RegistrarParametro('Permisos Extra',
                     'vgerDescuentos',
                     'Permite descuentos en ventas',
                     tpBoolean,
                     'True');

  // --- Arqueo ---
  RegistrarParametro('Arqueo',
                     'vgerArqueoNivelesFamilia',
                     'Niveles de familia en resumen por sección (1=sección)',
                     tpInteger,
                     '2');

  // ----------------------------------------------------------------------------------
  // Una vez registrada toda la estructura en memoria, le decimos a la librería
  // que se conecte a la base de datos y cargue los valores reales del usuario.
  // ----------------------------------------------------------------------------------
  Inicializar(AUsuario, AGrupo);
end;

function TParametrosCaja.NivelesFamiliaArqueo: Integer;
begin
  Result := GetInt('vgerArqueoNivelesFamilia', 2);
  if Result < 1 then
    Result := 1;
  if Result > 9 then
    Result := 9;
end;

function TParametrosCaja.TarifaDefecto: string;
begin
  Result := GetString('vgerDefTarifa', 'PVP');
end;

function CrearParametrosCaja(
  const APerfilesUsuario: IPerfilesUsuario;
  const AUsuario, AGrupo: string
): IParametrosCaja;
var
  Parametros: TParametrosCaja;
begin
  Parametros := TParametrosCaja.Create(APerfilesUsuario);
  // Mismo orden que en la factoria de aplicacion: el interfaz gobierna
  // la vida del objeto antes de inicializar, por si algun hook toma una
  // referencia temporal a Self durante la carga.
  Result := Parametros;
  Parametros.InicializarParametrosCaja(AUsuario, AGrupo);
end;

end.
