{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridTallasInline                                         }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       18/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Gestor reutilizable para grids cxGrid con tallas pivotadas inline. Los    }
{    clientes compran "en horizontal": una fila por articulo + N columnas de   }
{    cantidad por talla. Este patron aparece en todo el modulo de Compras      }
{    (Sesiones, Pedidos, Albaranes, Facturas) y esta libreria centraliza la    }
{    parte fragil para que cada Mto solo cuide su cabecera y sus campos        }
{    propios.                                                                  }
{                                                                              }
{    Lo que la libreria hace:                                                  }
{      - Cachea las posiciones (ID_AV, VALOR) de cada conjunto pivot.          }
{      - Calcula el numero maximo de columnas talla a mostrar a partir de los  }
{        sistemas referenciados por las lineas del documento.                  }
{      - Muestra / oculta columnas talla segun ese maximo                      }
{        (RecalcularMaxColumnas).                                              }
{      - Actualiza captions al sistema de la linea con foco                    }
{        (ActualizarCaptionsLineaActiva).                                      }
{      - Carga las cantidades desde la tabla de celdas a los Values[] de las   }
{        columnas no-bound del grid con DisableControls + bookmark             }
{        (CargarCantidadesTodasLineas / UnaLinea).                             }
{      - Persiste el cambio de una celda mediante el puerto inyectado.         }
{      - Recalcula totales de la linea sumando la tabla de celdas              }
{        (RefrescarTotalesLinea).                                              }
{      - Valida que el sistema seleccionado no exceda Cfg.MaxColumnas y, si    }
{        lo excede, muestra mtError y limpia el campo                          }
{        (ValidarSistemaSeleccionado).                                         }
{                                                                              }
{    Lo que el Mto consumidor sigue cuidando:                                  }
{      - Cabecera y settings.                                                  }
{      - Crear las N columnas no-bound (Tag = 1..N) y pasarlas al gestor en    }
{        la inicializacion.                                                    }
{      - Handlers de F3/familia, color, PVP, etc.                              }
{      - Eventos del propio grid (OnFocusedRecordChanged, OnInitEdit,          }
{        OnEditKeyDown, OnCustomDrawCell, OnEditValueChanged).                 }
{                                                                              }
{    Parametrizacion via TGridTallasConfig: cada Mto carga su record con los   }
{    nombres de tabla / campos / sufijos especificos:                          }
{      Sesiones:   SESCEL / SESLIN / SES                                       }
{      Pedidos:    PEDCEL / PEDLIN / PED (cuando existan)                      }
{      Albaranes:  ALBCEL / ALBLIN / ALB (cuando existan)                      }
{      Facturas:   FACCEL / FACLIN / FAC (cuando existan)                      }
{                                                                              }
{    Documentacion: DESARROLLOS EN CURSO/compras_sesiones.md                   }
{    (grid tallas inline).                                                     }
{******************************************************************************}
unit inLibGridTallasInline;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Variants,
  System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.UITypes,
  Data.DB, Uni,
  cxControls, cxClasses, cxEdit, cxTextEdit, cxCurrencyEdit, cxCustomData,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  JvEnterTab,
  inLibContextoSesionIntf, inLibModoTallasIntf;

type
  TPosConjunto = record
    IdAv  : Integer;
    Valor : string;
  end;
  TArrPosConjunto = TArray<TPosConjunto>;

  // Una opcion del selector "Sistema de tallas": un conjunto de
  // atributos (fza_atributos_conjuntos) con su nombre y el rango
  // (primera..ultima talla) que se muestran como tres columnas.
  TOpcionConjuntoTalla = record
    IdAc    : Integer;   // ID_AC (clave que devuelve el selector)
    Nombre  : string;    // NOMBRE_AC      -> columna 'Sistema'
    Primera : string;    // primera talla  -> columna 'Desde'
    Ultima  : string;    // ultima talla   -> columna 'Hasta'
  end;

  // Configuracion del gestor. Cada Mto consumidor rellena su instancia
  // con los nombres de tabla / campos especificos antes de crear el
  // gestor. Todos los nombres son SQL crudos (no constantes f*).
  TGridTallasConfig = record
    // -- objetos del form --
    Conexion         : TUniConnection;
    Persistencia     : IPersistenciaGridTallasInline;
    ContextoSesion   : IContextoSesionAplicacion;
    Usuario          : string;
    Grid             : TcxGridDBTableView;
    SourceMaster     : TDataSource;       // cabecera del documento
    SourceLineas     : TDataSource;       // detalle (line items)
    ColumnasTallas   : TArray<TcxGridDBColumn>;
                       // las N columnas no-bound creadas por el form;
                       // Tag = posicion 1..N en el conjunto

    // -- campos del master (cabecera) --
    FieldSerieMaster  : string;   // 'SERIE_SES'
    // NUMERO es OPCIONAL ('' = documento de clave simple, p.ej.
    // fza_documentos_trabajo con ID_DTR): la "serie" lleva la clave
    // completa y el par numero desaparece de los SQL de celdas.
    FieldNumeroMaster : string;   // 'NUMERO_SES' (puede ser '')

    // -- campos del detail (lineas) --
    FieldLinea        : string;   // 'LINEA_SESLIN'
    FieldConjuntoPivot: string;   // 'ID_AC_PIVOT_SESLIN'
    FieldPrecioBase   : string;   // 'PRECIO_COMPRA_SESLIN'
    FieldTotalUds     : string;   // 'TOTAL_UNIDADES_SESLIN'
    FieldTotalLinea   : string;   // 'TOTAL_LINEA_SESLIN'

    // -- tabla y campos de celdas --
    TablaCeldas      : string;    // 'fza_compras_sesiones_celdas'
    FieldSerieCel    : string;    // 'SERIE_SES_SESCEL'
    FieldNumeroCel   : string;    // 'NUMERO_SES_SESCEL'
    FieldLineaCel    : string;    // 'LINEA_SES_SESCEL'
    FieldFilaCel     : string;    // 'ID_FILA_SES_SESCEL'
    FieldAvPivotCel  : string;    // 'ID_AV_PIVOT_SESCEL'
    FieldCantidadCel : string;    // 'CANTIDAD_SESCEL'
    FieldAlmacenCel  : string;    // 'CODIGO_ALM_SESCEL' (puede ser '')
    // Clave de documento EXTRA (opcional): pares campo del MASTER ->
    // campo de la tabla de CELDAS, para documentos cuya clave excede
    // SERIE+NUMERO (inventarios: empresa y almacen del documento).
    // Arrays paralelos; vacios = comportamiento actual (sesiones).
    CamposDocExtraMaster : TArray<string>;
    CamposDocExtraCel    : TArray<string>;
    IdFilaFijo       : Integer;   // 1 — la prueba/Mtos por ahora usan una
                                  // fila logica por linea

    // -- limites --
    MaxColumnas      : Integer;   // 20 por defecto
  end;

  TGestorGridTallas = class
  private
    FCfg         : TGridTallasConfig;
    FConjuntoPos : TDictionary<Integer, TArrPosConjunto>;
    function  Lineas: TDataSet;
    procedure LogSes(const ATexto: string);
  public
    constructor Create(const ACfg: TGridTallasConfig);
    destructor  Destroy; override;

    // Cache de posiciones por conjunto.
    function GetPosicionesConjunto(AIdAc: Integer): TArrPosConjunto;
    procedure InvalidarCache;

    // Siembra un conjunto VIRTUAL (id negativo) en la cache de
    // posiciones. Lo usa el pivote de tallas como fallback cuando
    // ningun conjunto real de fza_atributos_conjuntos cubre las tallas
    // de un articulo: el id negativo nunca llega a SQL, solo vive en
    // la cache y GetPosicionesConjunto lo resuelve desde ella.
    procedure RegistrarConjuntoVirtual(AIdAc: Integer;
                                       const APosiciones: TArrPosConjunto);

    // Maximo de valores entre los conjuntos referenciados por
    // alguna linea de la sesion (capado a Cfg.MaxColumnas).
    function MaxLongConjuntos: Integer;

    // Muestra Cfg.ColumnasTallas[0..N-1] segun el maximo del documento
    // y oculta el resto. Setea captions genericos "Talla N" — la
    // captura del sistema activo la hace ActualizarCaptionsLineaActiva.
    procedure RecalcularMaxColumnas;

    // Al cambiar de fila con foco, escribe los valores del conjunto
    // activo en las captions de las columnas talla. Las posiciones
    // que no aplican al conjunto actual quedan con "Talla N" generico.
    procedure ActualizarCaptionsLineaActiva;

    // Lee la tabla de celdas y vuelca CANTIDAD a los Values[] de las
    // columnas no-bound del grid. Usa DisableControls + bookmark para
    // no perder los Values al cambiar de record durante el bucle.
    procedure CargarCantidadesTodasLineas;
    procedure CargarCantidadesUnaLinea(ARecordIndex, ALinea: Integer);

    // Persiste una cantidad mediante el puerto de celdas.
    procedure PersistirCantidad(ALinea, AIdAv: Integer; ACantidad: Double);

    // Recalcula totales de la linea actual: SUM(CANTIDAD) y
    // FieldTotalLinea = SUM * FieldPrecioBase. Solo actualiza el
    // dataset en memoria; el form decide cuando Postear.
    procedure RefrescarTotalesLineaActual;

    // Valida que el conjunto recien seleccionado no excede
    // Cfg.MaxColumnas. Si lo excede muestra mtError, limpia el campo
    // y devuelve False; True en caso correcto.
    function ValidarSistemaSeleccionado: Boolean;

    // Persiste el cambio de la celda talla activa en el grid.
    // Llamarlo desde el OnEditValueChanged de cada columna talla.
    procedure PersistirCeldaActiva(ASender: TObject);

    property Cfg: TGridTallasConfig read FCfg;
  end;

function CrearConfigPersistenciaTallasInline(
  const AConfig: TGridTallasConfig): TConfigPersistenciaTallas;

// =============================================================================
//   Helpers que no necesitan estado pero suelen ir junto al gestor
// =============================================================================

// Apaga / enciende todas las instancias de TJvEnterAsTab encontradas en
// AForm, AForm.Owner y Application.MainForm. Llamarlo desde
// cxGrid.OnEnter (apagar) / OnExit (encender) para que Enter navegue
// celda a celda dentro del grid en vez de saltar al siguiente control.
procedure ActivarEnterComoTab(AForm: TForm; AActivo: Boolean);

// SelectAll en el editor si soporta seleccion de texto. Estilo Excel.
// Llamarlo desde tvLineas.OnInitEdit para que al entrar a una celda
// el contenido quede seleccionado.
procedure SeleccionarTodoEnEditor(AEdit: TcxCustomEdit);

// Muestra un dropdown sin marco con un TListBox owner-drawn de TRES
// columnas (Sistema / Desde / Hasta) y una cabecera, para elegir un
// sistema de tallas imitando el selector de paleta de colores
// (inLibAtributosPaleta.SeleccionarAvConPaleta) pero con varias
// columnas. Un click selecciona y cierra; Esc o click fuera cancelan.
// Teclear dentro del popup busca siempre por NOMBRE_AC, nunca por ID_AC.
// Pasa AScreenLeft/AScreenTop = posicion en pantalla justo debajo del
// editor y AWidthHint = ancho minimo. Devuelve True y el ID_AC elegido
// en AIdAc; False si se cancela.
function SeleccionarConjuntoTalla(
                          const AOpciones: array of TOpcionConjuntoTalla;
                          const AIdAcActual: Integer;
                          out AIdAc: Integer;
                          AScreenLeft: Integer = -1;
                          AScreenTop: Integer = -1;
                          AWidthHint: Integer = 380;
                          const ABusquedaInicial: string = ''): Boolean;

implementation

uses
  System.Math, System.Types,
  Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  inLibMsgArticulos;

{ TGestorGridTallas }

function CrearConfigPersistenciaTallasInline(
  const AConfig: TGridTallasConfig): TConfigPersistenciaTallas;
begin
  Result := Default(TConfigPersistenciaTallas);
  if Assigned(AConfig.SourceMaster) then
    Result.Master := AConfig.SourceMaster.DataSet;
  Result.Usuario := AConfig.Usuario;
  Result.CampoSerieMaster := AConfig.FieldSerieMaster;
  Result.CampoNumeroMaster := AConfig.FieldNumeroMaster;
  Result.CamposDocExtraMaster := AConfig.CamposDocExtraMaster;
  Result.TablaCeldas := AConfig.TablaCeldas;
  Result.CampoSerieCel := AConfig.FieldSerieCel;
  Result.CampoNumeroCel := AConfig.FieldNumeroCel;
  Result.CampoLineaCel := AConfig.FieldLineaCel;
  Result.CampoFilaCel := AConfig.FieldFilaCel;
  Result.CampoAvPivotCel := AConfig.FieldAvPivotCel;
  Result.CampoCantidadCel := AConfig.FieldCantidadCel;
  Result.CampoAlmacenCel := AConfig.FieldAlmacenCel;
  Result.CamposDocExtraCel := AConfig.CamposDocExtraCel;
  Result.IdFilaFijo := AConfig.IdFilaFijo;
end;

constructor TGestorGridTallas.Create(const ACfg: TGridTallasConfig);
begin
  inherited Create;
  FCfg := ACfg;
  if not Assigned(FCfg.Persistencia) then
    raise EArgumentNilException.Create('ACfg.Persistencia');
  if FCfg.MaxColumnas <= 0 then FCfg.MaxColumnas := 20;
  if FCfg.IdFilaFijo  <= 0 then FCfg.IdFilaFijo  := 1;
  FConjuntoPos := TDictionary<Integer, TArrPosConjunto>.Create;
end;

function TGestorGridTallas.Lineas: TDataSet;
begin
  if Assigned(FCfg.SourceLineas) then
    Result := FCfg.SourceLineas.DataSet
  else
    Result := nil;
end;

procedure TGestorGridTallas.LogSes(const ATexto: string);
begin
  if Assigned(FCfg.ContextoSesion) then
    FCfg.ContextoSesion.LogSesion(ATexto);
end;

destructor TGestorGridTallas.Destroy;
begin
  FreeAndNil(FConjuntoPos);
  inherited;
end;

procedure TGestorGridTallas.InvalidarCache;
begin
  if FConjuntoPos <> nil then FConjuntoPos.Clear;
end;

procedure TGestorGridTallas.RegistrarConjuntoVirtual(AIdAc: Integer;
  const APosiciones: TArrPosConjunto);
begin
  // AddOrSetValue: el llamante re-registra en cada recarga porque las
  // tallas del articulo pueden crecer (alta de SKU desde una celda).
  if (FConjuntoPos <> nil) and (AIdAc < 0) then
    FConjuntoPos.AddOrSetValue(AIdAc, APosiciones);
end;

function TGestorGridTallas.GetPosicionesConjunto(AIdAc: Integer)
                                                : TArrPosConjunto;
var
  aPersistidas: TArray<TPosicionConjuntoTallas>;
  arr: TArrPosConjunto;
  i: Integer;
begin
  // Devuelve la lista ordenada de (ID_AV, VALOR) del conjunto pivot
  // indicado. Cacheado en FConjuntoPos para no re-consultar por cada
  // refresco / edicion.
  Result := nil;
  if FConjuntoPos = nil then Exit;
  if FConjuntoPos.TryGetValue(AIdAc, Result) then Exit;
  // Ids negativos = conjuntos VIRTUALES (RegistrarConjuntoVirtual):
  // solo existen en cache, no hay fila en BBDD que consultar.
  if AIdAc <= 0 then Exit;

  aPersistidas := FCfg.Persistencia.ConsultarPosicionesConjunto(AIdAc);
  SetLength(arr, Length(aPersistidas));
  for i := 0 to High(aPersistidas) do
  begin
    arr[i].IdAv := aPersistidas[i].IdAv;
    arr[i].Valor := aPersistidas[i].Valor;
  end;
  FConjuntoPos.Add(AIdAc, arr);
  Result := arr;
end;

function TGestorGridTallas.MaxLongConjuntos: Integer;
var
  ds     : TDataSet;
  bk     : TBookmark;
  vistos : TList<Integer>;
  iAc    : Integer;
  arr    : TArrPosConjunto;
begin
  // Recorre el dataset de lineas en memoria, recoge los ID_AC pivot
  // distintos y devuelve el tamano del conjunto mas grande. Iterar
  // el dataset abierto (con DisableControls + bookmark) es mucho mas
  // robusto que reformular el SQL — funciona para cualquier query y
  // no asume nombres de parametros del master.
  Result := 0;
  ds := Lineas;
  if (ds = nil) or not ds.Active or ds.IsEmpty then Exit;

  vistos := TList<Integer>.Create;
  bk := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      iAc := ds.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
      if (iAc > 0) and (not vistos.Contains(iAc)) then
      begin
        vistos.Add(iAc);
        arr := GetPosicionesConjunto(iAc);
        if Length(arr) > Result then Result := Length(arr);
      end;
      ds.Next;
    end;
  finally
    if Assigned(bk) then
    begin
      if ds.BookmarkValid(bk) then ds.GotoBookmark(bk);
      ds.FreeBookmark(bk);
    end;
    ds.EnableControls;
    FreeAndNil(vistos);
  end;
  if Result > FCfg.MaxColumnas then Result := FCfg.MaxColumnas;
end;

procedure TGestorGridTallas.RecalcularMaxColumnas;
var
  i, iMax : Integer;
begin
  iMax := MaxLongConjuntos;
  for i := 0 to High(FCfg.ColumnasTallas) do
  begin
    if FCfg.ColumnasTallas[i] = nil then Continue;
    FCfg.ColumnasTallas[i].Visible := (i < iMax);
    if i < iMax then
      FCfg.ColumnasTallas[i].Caption := Format(SCaptionColTallaN, [i + 1]);
  end;
end;

procedure TGestorGridTallas.ActualizarCaptionsLineaActiva;
var
  ds   : TDataSet;
  iAc  : Integer;
  arr  : TArrPosConjunto;
  i    : Integer;
begin
  ds := Lineas;
  if (ds = nil) or not ds.Active or ds.IsEmpty then Exit;
  iAc := ds.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
  // Linea sin sistema asignado todavia (linea nueva en blanco, p.ej.):
  // dejar las captions tal cual estaban. Si las sobrescribimos a la
  // generica 'Talla N' al pasar por una linea vacia, perdemos el
  // contexto visual de la linea anterior que el usuario seguia viendo.
  if iAc <= 0 then Exit;
  arr := GetPosicionesConjunto(iAc);
  for i := 0 to High(FCfg.ColumnasTallas) do
  begin
    if FCfg.ColumnasTallas[i] = nil then Continue;
    if not FCfg.ColumnasTallas[i].Visible then Continue;
    if i < Length(arr) then
      FCfg.ColumnasTallas[i].Caption := arr[i].Valor
    else
      FCfg.ColumnasTallas[i].Caption := Format(SCaptionColTallaN, [i + 1]);
  end;
end;

procedure TGestorGridTallas.CargarCantidadesTodasLineas;
var
  i, iLinea : Integer;
  colLinea  : TcxGridDBColumn;
  vLinea    : Variant;
begin
  // Estrategia correcta para columnas no-bound en cxGridDBTableView:
  // iterar el DataController del propio grid, NO el dataset subyacente.
  //   - ds.DisableControls/EnableControls sobre el dataset hace que
  //     cxGrid limpie los Values[] no-bound al EnableControls (resetea
  //     el DataController desde cero).
  //   - DataController.BeginUpdate/EndUpdate suspende solo el cxGrid
  //     sin tocar el dataset; al EndUpdate el grid repinta de una vez
  //     con todos los Values[] que hayamos asignado en memoria.
  //   - Leer LINEA por Values[recordIdx, colLinea.Index] saca el dato
  //     sin tocar el cursor del dataset y sin disparar refrescos.
  if (Lineas = nil) or not Lineas.Active or Lineas.IsEmpty then Exit;
  colLinea := FCfg.Grid.GetColumnByFieldName(FCfg.FieldLinea);
  if colLinea = nil then Exit;

  FCfg.Grid.DataController.BeginUpdate;
  try
    for i := 0 to FCfg.Grid.DataController.RecordCount - 1 do
    begin
      vLinea := FCfg.Grid.DataController.Values[i, colLinea.Index];
      if VarIsNull(vLinea) or VarIsEmpty(vLinea) then Continue;
      iLinea := vLinea;
      if iLinea > 0 then
        CargarCantidadesUnaLinea(i, iLinea);
    end;
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
end;

procedure TGestorGridTallas.CargarCantidadesUnaLinea(
  ARecordIndex, ALinea: Integer);
var
  aCeldas: TArray<TCeldaTallas>;
  arr: TArrPosConjunto;
  colAc: TcxGridDBColumn;
  i, iCelda, iAc: Integer;
  rCantidad: Double;
  vAc: Variant;
begin
  colAc := FCfg.Grid.GetColumnByFieldName(FCfg.FieldConjuntoPivot);
  if colAc = nil then Exit;
  vAc := FCfg.Grid.DataController.Values[ARecordIndex, colAc.Index];
  if VarIsNull(vAc) or VarIsEmpty(vAc) then Exit;
  iAc := vAc;
  arr := GetPosicionesConjunto(iAc);
  if Length(arr) = 0 then Exit;
  aCeldas := FCfg.Persistencia.ConsultarCeldasLinea(ALinea);
  for i := 0 to High(arr) do
  begin
    rCantidad := 0;
    for iCelda := 0 to High(aCeldas) do
      if aCeldas[iCelda].IdAv = arr[i].IdAv then
        rCantidad := rCantidad + aCeldas[iCelda].Cantidad;
    if (i <= High(FCfg.ColumnasTallas)) and
       Assigned(FCfg.ColumnasTallas[i]) then
      FCfg.Grid.DataController.Values[
        ARecordIndex, FCfg.ColumnasTallas[i].Index] := rCantidad;
  end;
end;
procedure TGestorGridTallas.PersistirCantidad(
  ALinea, AIdAv: Integer; ACantidad: Double);
begin
  LogSes(Format(
    'Tallas.PersistirCantidad: linea=%d idAv=%d cantidad=%g',
    [ALinea, AIdAv, ACantidad]));
  if (ALinea > 0) and (AIdAv > 0) then
    FCfg.Persistencia.FijarCantidadCelda(
      ALinea, AIdAv, ACantidad, '')
  else
    LogSes('  guard: ALinea<=0 o AIdAv<=0, salida');
end;
procedure TGestorGridTallas.RefrescarTotalesLineaActual;
var
  aCeldas: TArray<TCeldaTallas>;
  ds: TDataSet;
  i, iLinea: Integer;
  rPrecio, rTotal: Double;
begin
  ds := Lineas;
  if (ds = nil) or ds.IsEmpty then Exit;
  iLinea := ds.FieldByName(FCfg.FieldLinea).AsInteger;
  if iLinea <= 0 then Exit;
  aCeldas := FCfg.Persistencia.ConsultarCeldasLinea(iLinea);
  rTotal := 0;
  for i := 0 to High(aCeldas) do
    rTotal := rTotal + aCeldas[i].Cantidad;
  rPrecio := 0;
  if (FCfg.FieldPrecioBase <> '') and
     Assigned(ds.FindField(FCfg.FieldPrecioBase)) then
    rPrecio := ds.FieldByName(FCfg.FieldPrecioBase).AsFloat;
  FCfg.Grid.DataController.BeginUpdate;
  try
    if not (ds.State in [dsEdit, dsInsert]) then
      ds.Edit;
    if (FCfg.FieldTotalUds <> '') and
       Assigned(ds.FindField(FCfg.FieldTotalUds)) then
      ds.FieldByName(FCfg.FieldTotalUds).AsFloat := rTotal;
    if (FCfg.FieldTotalLinea <> '') and
       Assigned(ds.FindField(FCfg.FieldTotalLinea)) then
      ds.FieldByName(FCfg.FieldTotalLinea).AsFloat :=
        rTotal * rPrecio;
  finally
    FCfg.Grid.DataController.EndUpdate;
  end;
end;
function TGestorGridTallas.ValidarSistemaSeleccionado: Boolean;
var
  iAc : Integer;
  arr : TArrPosConjunto;
begin
  Result := True;
  if Lineas = nil then Exit;
  if Lineas.IsEmpty then Exit;
  iAc := Lineas.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
  if iAc <= 0 then Exit;
  arr := GetPosicionesConjunto(iAc);
  if Length(arr) <= FCfg.MaxColumnas then Exit;

  MessageDlg(Format(SAvisoSistemaTallasSuperaMaximo,
    [Length(arr), FCfg.MaxColumnas]),
    mtError, [mbOk], 0);
  if not (Lineas.State in [dsEdit, dsInsert]) then Lineas.Edit;
  Lineas.FieldByName(FCfg.FieldConjuntoPivot).Clear;
  Result := False;
end;

procedure TGestorGridTallas.PersistirCeldaActiva(ASender: TObject);
var
  ed     : TcxCustomEdit;
  item   : TcxCustomGridTableItem;
  iPos   : Integer;
  iLinea : Integer;
  iAc    : Integer;
  arr    : TArrPosConjunto;
  rCant  : Double;
  vEdit  : Variant;
  idxRec : Integer;
begin
  if not (ASender is TcxCustomEdit) then Exit;
  ed := TcxCustomEdit(ASender);
  ed.PostEditValue;

  // El FocusedItem del grid (TcxCustomGridTableItem) es la base de
  // todas las columnas; nos basta su Tag para identificar la posicion
  // de la celda. Asi evitamos depender del tipo concreto TcxGridColumn /
  // TcxGridDBColumn (que en este build no resuelve desde la libreria
  // por algun fallo de scope incluso con cxGridTableView en uses).
  item := FCfg.Grid.Controller.FocusedItem;
  if item = nil then Exit;
  iPos := item.Tag;
  if (iPos < 1) or (iPos > FCfg.MaxColumnas) then Exit;
  if Lineas = nil then Exit;
  if Lineas.IsEmpty then Exit;

  iLinea := Lineas.FieldByName(FCfg.FieldLinea).AsInteger;
  iAc    := Lineas.FieldByName(FCfg.FieldConjuntoPivot).AsInteger;
  arr    := GetPosicionesConjunto(iAc);
  LogSes(Format('Tallas.PersistirCeldaActiva: linea=%d pos=%d/%d iAc=%d Lineas.State=%d',
                [iLinea, iPos, Length(arr), iAc, Ord(Lineas.State)]));
  if iPos > Length(arr) then
  begin
    LogSes('  guard: iPos fuera del conjunto pivot, salida');
    Exit;
  end;

  vEdit := ed.EditValue;
  if VarIsNull(vEdit) or VarIsClear(vEdit) then
    rCant := 0
  else
    rCant := vEdit;

  // Capturamos el record idx visual ANTES de tocar totales: el
  // RefrescarTotales hace ds.Edit + asignaciones de campos bound,
  // y cxGrid reacciona repintando la fila desde el dataset, lo que
  // borra los Values[] no-bound de esa fila (tallas en blanco).
  // Re-inyectamos esa misma fila justo despues para neutralizarlo.
  idxRec := FCfg.Grid.Controller.FocusedRecordIndex;

  PersistirCantidad(iLinea, arr[iPos - 1].IdAv, rCant);
  RefrescarTotalesLineaActual;
  if idxRec >= 0 then
    CargarCantidadesUnaLinea(idxRec, iLinea);

  // Sin este Invalidate el valor queda correcto en el DataController
  // pero la celda no se repinta hasta el siguiente evento natural
  // (p.ej. cambiar de fila). Mismo patron que inLibGridPivoteCompra.pas.
  if Assigned(FCfg.Grid) and Assigned(FCfg.Grid.Site) then
    FCfg.Grid.Site.Invalidate;
end;

// =============================================================================
//   Helpers libres
// =============================================================================

procedure ActivarEnterComoTab(AForm: TForm; AActivo: Boolean);
  procedure CambiarEn(AOwner: TComponent);
  var
    i : Integer;
  begin
    if not Assigned(AOwner) then Exit;
    for i := 0 to AOwner.ComponentCount - 1 do
      if AOwner.Components[i] is TJvEnterAsTab then
        TJvEnterAsTab(AOwner.Components[i]).EnterAsTab := AActivo;
  end;
begin
  CambiarEn(AForm);
  if Assigned(AForm) then CambiarEn(AForm.Owner);
  CambiarEn(Application.MainForm);
end;

procedure SeleccionarTodoEnEditor(AEdit: TcxCustomEdit);
begin
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
end;

// =============================================================================
//   Selector "Sistema de tallas" (listbox owner-drawn de 3 columnas)
// =============================================================================
// Calca el patron de TfrmSelPalAvAux de inLibAtributosPaleta: dropdown sin
// marco anclado al form activo via PopupParent, click=selecciona+cierra,
// Esc/click-fuera=cancela. La diferencia es que pinta TRES columnas
// (Sistema / Desde / Hasta) con una cabecera rotulada arriba.

type
  TfrmSelConjTallaAux = class(TForm)
  private
    FListBox  : TListBox;
    FHeader   : TPaintBox;
    FOpciones : TArray<TOpcionConjuntoTalla>;
    FShown    : Boolean;
    FBusqueda : string;
    FUltimaTeclaBusqueda : Cardinal;
    procedure CalcularColumnas(AWidth: Integer;
                               out AInicioDesde, AInicioHasta: Integer);
    procedure SeleccionarPorNombre(const ATexto: string);
    procedure HeaderPaint(Sender: TObject);
    procedure ListBoxDrawItem(Control: TWinControl; Index: Integer;
                              ARect: TRect; State: TOwnerDrawState);
    procedure ListBoxMouseDown(Sender: TObject; Button: TMouseButton;
                               Shift: TShiftState; X, Y: Integer);
    procedure ListBoxKeyDown(Sender: TObject;
                             var Key: Word; Shift: TShiftState);
    procedure ListBoxKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor CreateConOpciones(
                  const AOpciones: array of TOpcionConjuntoTalla;
                  const AIdAcActual: Integer;
                  AScreenLeft, AScreenTop, AWidthHint: Integer;
                  const ABusquedaInicial: string);
  end;

const
  // Anchos fijos de las columnas de rango (la columna 'Sistema' ocupa
  // el resto). MARGEN_COL = padding interno de cada columna.
  ANCHO_COL_DESDE = 64;
  ANCHO_COL_HASTA = 64;
  MARGEN_COL      = 6;

procedure TfrmSelConjTallaAux.CalcularColumnas(AWidth: Integer;
                                  out AInicioDesde, AInicioHasta: Integer);
begin
  AInicioHasta := AWidth - ANCHO_COL_HASTA;     // x de inicio de 'Hasta'
  AInicioDesde := AInicioHasta - ANCHO_COL_DESDE; // x de inicio de 'Desde'
  // Garantizar un minimo para la columna 'Sistema' si el popup es muy
  // estrecho (no deberia pasar, AWidthHint manda).
  if AInicioDesde < 80 then
  begin
    AInicioDesde := 80;
    if AInicioHasta < AInicioDesde + 20 then
      AInicioHasta := AInicioDesde + 20;
  end;
end;

procedure TfrmSelConjTallaAux.SeleccionarPorNombre(const ATexto: string);
var
  i            : Integer;
  idxContiene  : Integer;
  sBuscar      : string;
  sNombre      : string;
  bEncontrado  : Boolean;
begin
  sBuscar := AnsiUpperCase(Trim(ATexto));
  if sBuscar <> '' then
  begin
    idxContiene := -1;
    bEncontrado := False;
    i := 0;
    while (i <= High(FOpciones)) and (not bEncontrado) do
    begin
      sNombre := AnsiUpperCase(FOpciones[i].Nombre);
      if Pos(sBuscar, sNombre) = 1 then
      begin
        FListBox.ItemIndex := i;
        FListBox.TopIndex := Max(0, i - 2);
        bEncontrado := True;
      end
      else if (idxContiene < 0) and (Pos(sBuscar, sNombre) > 0) then
        idxContiene := i;
      Inc(i);
    end;
    if (not bEncontrado) and (idxContiene >= 0) then
    begin
      FListBox.ItemIndex := idxContiene;
      FListBox.TopIndex := Max(0, idxContiene - 2);
    end;
  end;
end;

procedure TfrmSelConjTallaAux.HeaderPaint(Sender: TObject);
var
  cv : TCanvas;
  xD, xH : Integer;
  r : TRect;
begin
  cv := FHeader.Canvas;
  cv.Brush.Style := bsSolid;
  cv.Brush.Color := clBtnFace;
  cv.FillRect(FHeader.ClientRect);
  CalcularColumnas(FHeader.ClientWidth, xD, xH);
  cv.Font.Assign(Self.Font);
  cv.Font.Style := [fsBold];
  cv.Brush.Style := bsClear;
  r := Rect(MARGEN_COL, 0, xD - MARGEN_COL, FHeader.ClientHeight);
  DrawText(cv.Handle, 'Sistema', -1, r,
           DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
  r := Rect(xD + MARGEN_COL, 0, xH - MARGEN_COL, FHeader.ClientHeight);
  DrawText(cv.Handle, 'Desde', -1, r,
           DT_SINGLELINE or DT_VCENTER or DT_CENTER);
  r := Rect(xH + MARGEN_COL, 0, FHeader.ClientWidth - MARGEN_COL,
            FHeader.ClientHeight);
  DrawText(cv.Handle, 'Hasta', -1, r,
           DT_SINGLELINE or DT_VCENTER or DT_CENTER);
  // Separadores verticales + linea inferior.
  cv.Pen.Color := clBtnShadow;
  cv.MoveTo(xD, 2);
  cv.LineTo(xD, FHeader.ClientHeight - 2);
  cv.MoveTo(xH, 2);
  cv.LineTo(xH, FHeader.ClientHeight - 2);
  cv.MoveTo(0, FHeader.ClientHeight - 1);
  cv.LineTo(FHeader.ClientWidth, FHeader.ClientHeight - 1);
end;

procedure TfrmSelConjTallaAux.ListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  LB : TListBox;
  op : TOpcionConjuntoTalla;
  xD, xH : Integer;
  r : TRect;
begin
  LB := Control as TListBox;
  if (Index < 0) or (Index >= Length(FOpciones)) then Exit;
  op := FOpciones[Index];
  if odSelected in State then
    LB.Canvas.Brush.Color := clHighlight
  else
    LB.Canvas.Brush.Color := clWindow;
  LB.Canvas.Brush.Style := bsSolid;
  LB.Canvas.FillRect(ARect);
  CalcularColumnas(LB.ClientWidth, xD, xH);
  if odSelected in State then
    LB.Canvas.Font.Color := clHighlightText
  else
    LB.Canvas.Font.Color := clWindowText;
  LB.Canvas.Brush.Style := bsClear;
  r := Rect(ARect.Left + MARGEN_COL, ARect.Top,
            ARect.Left + xD - MARGEN_COL, ARect.Bottom);
  DrawText(LB.Canvas.Handle, PChar(op.Nombre), -1, r,
           DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
  r := Rect(ARect.Left + xD + MARGEN_COL, ARect.Top,
            ARect.Left + xH - MARGEN_COL, ARect.Bottom);
  DrawText(LB.Canvas.Handle, PChar(op.Primera), -1, r,
           DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_END_ELLIPSIS);
  r := Rect(ARect.Left + xH + MARGEN_COL, ARect.Top,
            ARect.Right - MARGEN_COL, ARect.Bottom);
  DrawText(LB.Canvas.Handle, PChar(op.Ultima), -1, r,
           DT_SINGLELINE or DT_VCENTER or DT_CENTER or DT_END_ELLIPSIS);
  // Separadores verticales tenues entre columnas.
  LB.Canvas.Pen.Color := clBtnFace;
  LB.Canvas.MoveTo(ARect.Left + xD, ARect.Top);
  LB.Canvas.LineTo(ARect.Left + xD, ARect.Bottom);
  LB.Canvas.MoveTo(ARect.Left + xH, ARect.Top);
  LB.Canvas.LineTo(ARect.Left + xH, ARect.Bottom);
  LB.Canvas.Brush.Style := bsSolid;
  if odFocused in State then
    LB.Canvas.DrawFocusRect(ARect);
end;

procedure TfrmSelConjTallaAux.ListBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Idx : Integer;
begin
  if Button <> mbLeft then Exit;
  Idx := FListBox.ItemAtPos(Point(X, Y), True);
  if Idx >= 0 then
  begin
    FListBox.ItemIndex := Idx;
    ModalResult := mrOk;
  end;
end;

procedure TfrmSelConjTallaAux.ListBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (FListBox.ItemIndex >= 0) then
  begin
    ModalResult := mrOk;
    Key := 0;
  end;
end;

procedure TfrmSelConjTallaAux.ListBoxKeyPress(Sender: TObject;
  var Key: Char);
const
  CADUCIDAD_BUSQUEDA_MS = 1200;
var
  iTick : Cardinal;
begin
  iTick := GetTickCount;
  if Key = #8 then
  begin
    if FBusqueda <> '' then
    begin
      Delete(FBusqueda, Length(FBusqueda), 1);
      SeleccionarPorNombre(FBusqueda);
    end;
    FUltimaTeclaBusqueda := iTick;
    Key := #0;
  end
  else if Key >= #32 then
  begin
    if (FBusqueda = '') or
       (iTick - FUltimaTeclaBusqueda > CADUCIDAD_BUSQUEDA_MS) then
      FBusqueda := Key
    else
      FBusqueda := FBusqueda + Key;
    FUltimaTeclaBusqueda := iTick;
    SeleccionarPorNombre(FBusqueda);
    Key := #0;
  end;
end;

procedure TfrmSelConjTallaAux.FormShow(Sender: TObject);
begin
  FShown := True;
end;

procedure TfrmSelConjTallaAux.FormDeactivate(Sender: TObject);
begin
  // Click fuera del popup -> cancela (como un combo).
  if FShown and (ModalResult = mrNone) then
    ModalResult := mrCancel;
end;

procedure TfrmSelConjTallaAux.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end;
end;

constructor TfrmSelConjTallaAux.CreateConOpciones(
              const AOpciones: array of TOpcionConjuntoTalla;
              const AIdAcActual: Integer;
              AScreenLeft, AScreenTop, AWidthHint: Integer;
              const ABusquedaInicial: string);
const
  ALTO_FILA = 22;
  ALTO_HDR  = 22;
  ANCHO_MIN = 260;
  ALTO_MAX  = 380;
var
  i, idxSel, W, H : Integer;
begin
  inherited CreateNew(nil);
  // Anclar el popup al form activo como PopupParent (mismo motivo que
  // TfrmSelPalAvAux: sin esto el ShowModal de un form sin borde devuelve
  // el foco al MainForm al cerrarse y hunde la cadena de ventanas).
  if Screen.ActiveForm <> nil then
  begin
    Self.PopupParent := Screen.ActiveForm;
    Self.PopupMode   := pmExplicit;
  end
  else
    Self.PopupMode := pmAuto;
  BorderStyle := bsNone;
  Position    := poDesigned;
  Caption     := '';
  KeyPreview  := True;
  FShown      := False;
  FBusqueda   := Trim(ABusquedaInicial);
  FUltimaTeclaBusqueda := GetTickCount;
  OnShow       := FormShow;
  OnDeactivate := FormDeactivate;
  OnKeyDown    := FormKeyDown;
  SetLength(FOpciones, Length(AOpciones));
  for i := 0 to High(AOpciones) do
    FOpciones[i] := AOpciones[i];
  // Cabecera con los rotulos de las tres columnas, anclada arriba.
  FHeader := TPaintBox.Create(Self);
  FHeader.Parent  := Self;
  FHeader.Align   := alTop;
  FHeader.Height  := ALTO_HDR;
  FHeader.OnPaint := HeaderPaint;
  FListBox := TListBox.Create(Self);
  FListBox.Parent      := Self;
  FListBox.Align       := alClient;
  FListBox.Style       := lbOwnerDrawFixed;
  FListBox.BorderStyle := bsSingle;
  FListBox.ItemHeight  := ALTO_FILA;
  FListBox.OnDrawItem  := ListBoxDrawItem;
  FListBox.OnMouseDown := ListBoxMouseDown;
  FListBox.OnKeyDown   := ListBoxKeyDown;
  FListBox.OnKeyPress  := ListBoxKeyPress;
  idxSel := -1;
  for i := 0 to High(AOpciones) do
  begin
    // El TListBox necesita una entrada por fila (aunque el texto real
    // lo pinta ListBoxDrawItem desde FOpciones). Guardamos el nombre.
    FListBox.Items.Add(AOpciones[i].Nombre);
    if (idxSel < 0) and (AOpciones[i].IdAc = AIdAcActual) then
      idxSel := i;
  end;
  if (idxSel < 0) and (FListBox.Items.Count > 0) then
    idxSel := 0;
  if idxSel >= 0 then
    FListBox.ItemIndex := idxSel;
  if FBusqueda <> '' then
    SeleccionarPorNombre(FBusqueda);
  ActiveControl := FListBox;
  W := AWidthHint;
  if W < ANCHO_MIN then W := ANCHO_MIN;
  Width := W;
  H := ALTO_HDR + Length(AOpciones) * ALTO_FILA + 4;
  if H > ALTO_MAX then H := ALTO_MAX;
  Height := H;
  if (AScreenLeft >= 0) and (AScreenTop >= 0) then
  begin
    Left := AScreenLeft;
    Top  := AScreenTop;
  end
  else
    Position := poScreenCenter;
end;

function SeleccionarConjuntoTalla(
                          const AOpciones: array of TOpcionConjuntoTalla;
                          const AIdAcActual: Integer;
                          out AIdAc: Integer;
                          AScreenLeft, AScreenTop, AWidthHint: Integer;
                          const ABusquedaInicial: string): Boolean;
var
  F : TfrmSelConjTallaAux;
begin
  AIdAc  := 0;
  Result := False;
  if Length(AOpciones) = 0 then Exit;
  F := TfrmSelConjTallaAux.CreateConOpciones(AOpciones, AIdAcActual,
                                             AScreenLeft, AScreenTop,
                                             AWidthHint, ABusquedaInicial);
  try
    if F.ShowModal = mrOk then
    begin
      if (F.FListBox.ItemIndex >= 0) and
         (F.FListBox.ItemIndex < Length(F.FOpciones)) then
      begin
        AIdAc  := F.FOpciones[F.FListBox.ItemIndex].IdAc;
        Result := True;
      end;
    end;
  finally
    F.Free;
  end;
end;

end.
