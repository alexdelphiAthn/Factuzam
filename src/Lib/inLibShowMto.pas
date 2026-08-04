{******************************************************************************}
{                                                                              }
{  Módulo:       inLibShowMto                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Apertura genérica de formularios de mantenimiento. Resuelve las clases  }
{    por el registro de pantallas (inLibRegistroPantallas) y habla con el     }
{    anfitrión y con los mantenimientos a través de interfaces: esta         }
{    unidad ya no conoce TfrmMtoPrincipal ni TfrmMtoGen.                      }
{******************************************************************************}
unit inLibShowMto;

interface

uses
  Classes, Forms, Menus, Controls, Data.DB, System.SysUtils,
  Vcl.Dialogs, cxPC, inLibUnitForm, inLibFormManager,
  inLibDestinoFacturaPersistenciaIntf;

type
  // Lo que ShowMto necesita del formulario principal. TfrmMtoPrincipal
  // lo implementa; así esta librería no depende de la unidad inMto*.
  IAnfitrionPantallas = interface
    ['{3C56E82E-C2DB-418B-8850-5F548E7C9114}']
    // Gestor de ventanas embebidas (lo crea si aún no existe).
    function GestorVentanas: TEmbeddedFormManager;
    // Registro de pantallas cargado de fza_winforms.
    function RegistroPantallas: TfzaWinF;
    // Crea la pantalla con el contexto explícito que decida la composición.
    function CrearPantalla(AClase: TFormClass): TForm;
    // Restaurar la ventana principal y minimizar el menú de caja.
    procedure PrepararAperturaPantalla;
  end;

  procedure ShowMto(AOwner: TComponent;
                    ACall:String;
                    ABusq:string = '');
  function CodigoMtoDataSet(ADataSet: TDataSet;
    const ACampoCodigo: string): string;
  function ClaveMtoDataSet(ADataSet: TDataSet;
    const ACampoSerie, ACampoNumero: string): string;
  procedure ShowMtoCodigoDataSet(AOwner: TComponent;
    const ACall: string; ADataSet: TDataSet;
    const ACampoCodigo: string);
  procedure ShowMtoDocumentoDataSet(AOwner: TComponent;
    const ACall: string; ADataSet: TDataSet;
    const ACampoSerie, ACampoNumero: string;
    const AMensajeVacio: string = '');
  function ResolverCallFactura(
    const AResolutor: IResolutorDestinoFactura;
    const ANumero, ASerie: string): string;
  // Crea el data module de la pantalla desde el registro de clases. El
  // cableado con el form (FCurrentForm, dsTablaG, SQL de perfil) vive
  // ahora en TfrmMtoGen.CrearTablaPrincipal.
  function CrearDataModule(const ADataUnit: string;
                           AOwner: TComponent): TDataModule;

implementation

 uses
      inLibAnfitrionMtoIntf,
  inLibMsgComun,
      inLibLogIntf,
      inLibRegistroPantallas,
      inLibVentanaEmbebidaIntf;

function CodigoMtoDataSet(ADataSet: TDataSet;
  const ACampoCodigo: string): string;
begin
  Result := '';
  if Assigned(ADataSet) and ADataSet.Active and
     (not ADataSet.IsEmpty) then
    Result := Trim(ADataSet.FieldByName(ACampoCodigo).AsString);
end;

function ClaveMtoDataSet(ADataSet: TDataSet;
  const ACampoSerie, ACampoNumero: string): string;
var
  sNumero: string;
  sSerie: string;
begin
  Result := '';
  sSerie := CodigoMtoDataSet(ADataSet, ACampoSerie);
  sNumero := CodigoMtoDataSet(ADataSet, ACampoNumero);
  if (sSerie <> '') and (sNumero <> '') then
    Result := sSerie + ',' + sNumero;
end;

procedure ShowMtoCodigoDataSet(AOwner: TComponent;
  const ACall: string; ADataSet: TDataSet;
  const ACampoCodigo: string);
begin
  ShowMto(AOwner, ACall,
    CodigoMtoDataSet(ADataSet, ACampoCodigo));
end;

procedure ShowMtoDocumentoDataSet(AOwner: TComponent;
  const ACall: string; ADataSet: TDataSet;
  const ACampoSerie, ACampoNumero: string;
  const AMensajeVacio: string);
var
  sClave: string;
begin
  sClave := ClaveMtoDataSet(
    ADataSet, ACampoSerie, ACampoNumero);
  if sClave <> '' then
    ShowMto(AOwner, ACall, sClave)
  else if AMensajeVacio <> '' then
    ShowMessage(AMensajeVacio);
end;

// Numero de instancia (2..N) de la pantalla ACall que hay en la
// pestania activa; 0 si la pestania activa no es de esta pantalla. Se
// usa para rotar el foco entre las instancias abiertas con Ctrl+K.
function NumInstanciaActiva(AGestor: TEmbeddedFormManager;
                            const ACall: string): Integer;
var
  oForm: TForm;
  sClaveAct, sPrefijo: string;
begin
  Result := 0;
  oForm := AGestor.FormActivo;
  if oForm <> nil then
  begin
    sClaveAct := AGestor.ClaveDeForm(oForm);
    sPrefijo := ACall + '#';
    if Copy(sClaveAct, 1, Length(sPrefijo)) = sPrefijo then
      Result := StrToIntDef(
        Copy(sClaveAct, Length(sPrefijo) + 1, Length(sClaveAct)), 0);
  end;
end;

resourcestring
  SErrorAnfitrionPantallasNoDisponible =
    'El propietario no proporciona el servicio de apertura de ' +
    'pantallas (IAnfitrionPantallas).';
  SErrorMantenimientoEmbebidoNoDisponible =
    'La pantalla registrada no implementa IMantenimientoEmbebido.';

// Descubre el anfitrion o falla ruidosamente (PLAN_SOLID Fase 4):
// abrir una pantalla sin anfitrion era antes un no-op silencioso.
function ExigirAnfitrionPantallas(
  AOwner: TComponent): IAnfitrionPantallas;
begin
  if not Supports(AOwner, IAnfitrionPantallas, Result) then
    raise EServicioNoDisponible.Create(
      SErrorAnfitrionPantallasNoDisponible);
end;

function ExigirRegistroLog(AOwner: TComponent): IRegistroLog;
var
  Proveedor: IProveedorRegistroLog;
begin
  if not Supports(AOwner, IProveedorRegistroLog, Proveedor) then
    raise EServicioNoDisponible.Create(
      'El propietario no proporciona IRegistroLog.');
  Result := Proveedor.RegistroLog;
end;

type
  TContextoAperturaPantalla = record
    Anfitrion: IAnfitrionPantallas;
    Gestor: TEmbeddedFormManager;
    Pantalla: TfzaForm;
    RegistroLog: IRegistroLog;
    Busqueda: string;
  end;

  TDestinoAperturaPantalla = record
    Formulario: TForm;
    Clave: string;
    Titulo: string;
  end;

function ResolverPantallaAccesible(
  const AContexto: TContextoAperturaPantalla;
  const ACall: string): Boolean;
begin
  Result := Assigned(AContexto.Pantalla);
  if not Result then
    ShowMessageFmt(SResWinFNotFnd, [ACall])
  else if Assigned(AContexto.Pantalla.mnMenuItem) and
          (not AContexto.Pantalla.mnMenuItem.Visible) then
  begin
    AContexto.RegistroLog.RegistrarAviso(
      'Intento de acceso a menú oculto: ' + ACall);
    Result := False;
  end;
end;

function CalcularNumeroInstancia(
  const AContexto: TContextoAperturaPantalla): Integer;
var
  iActiva: Integer;
  iHueco: Integer;
  iInstancia: Integer;
  iPrimera: Integer;
  iSiguiente: Integer;
begin
  iActiva := NumInstanciaActiva(
    AContexto.Gestor, AContexto.Pantalla.Call);
  iPrimera := 0;
  iSiguiente := 0;
  iHueco := 0;
  for iInstancia := 2 to AContexto.Pantalla.NumVentanas do
  begin
    if Assigned(AContexto.Gestor.FormPorClave(
      AContexto.Pantalla.Call + '#' + IntToStr(iInstancia))) then
    begin
      if iPrimera = 0 then
        iPrimera := iInstancia;
      if (iSiguiente = 0) and (iInstancia > iActiva) then
        iSiguiente := iInstancia;
    end
    else if iHueco = 0 then
      iHueco := iInstancia;
  end;
  if iPrimera = 0 then
    Result := 2
  else if iActiva = 0 then
    Result := iPrimera
  else if iSiguiente > 0 then
    Result := iSiguiente
  else if iHueco > 0 then
    Result := iHueco
  else
    Result := iPrimera;
end;

function ResolverDestinoApertura(
  const AContexto: TContextoAperturaPantalla):
  TDestinoAperturaPantalla;
var
  iInstancia: Integer;
begin
  Result.Formulario := nil;
  Result.Clave := AContexto.Pantalla.Call;
  Result.Titulo := AContexto.Pantalla.Caption;
  if AContexto.Pantalla.NumVentanas > 1 then
  begin
    if AContexto.Busqueda <> '' then
      iInstancia := 1
    else
      iInstancia := CalcularNumeroInstancia(AContexto);
    Result.Clave := AContexto.Pantalla.Call + '#' +
      IntToStr(iInstancia);
    Result.Titulo := AContexto.Pantalla.Caption + ' ' +
      IntToStr(iInstancia);
  end;
  Result.Formulario := AContexto.Gestor.FormPorClave(Result.Clave);
end;

function PrepararModoBusqueda(
  const AContexto: TContextoAperturaPantalla;
  const ADestino: TDestinoAperturaPantalla;
  const AMantenimiento: IMantenimientoEmbebido): Boolean;
begin
  Result := False;
  if AContexto.Busqueda <> '' then
  begin
    if (AContexto.Pantalla.NumVentanas > 1) and
       (ADestino.Clave = AContexto.Pantalla.Call + '#1') then
      AMantenimiento.ActivarModoBusqueda(True)
    else
    begin
      AMantenimiento.ActivarModoBusqueda(False);
      Result := True;
    end;
  end;
end;

function CrearMantenimiento(
  const AContexto: TContextoAperturaPantalla;
  var ADestino: TDestinoAperturaPantalla): IMantenimientoEmbebido;
var
  bBusquedaTemporal: Boolean;
  oClaseFormulario: TFormClass;
begin
  Result := nil;
  oClaseFormulario := ClasePantalla(AContexto.Pantalla.UnitForm);
  if not Assigned(oClaseFormulario) then
  begin
    AContexto.RegistroLog.RegistrarError(
      'Pantalla sin clase registrada: ' + AContexto.Pantalla.UnitForm);
    ShowMessageFmt(SClassRttiNotFnd, [AContexto.Pantalla.UnitForm]);
  end
  else
  begin
    ADestino.Formulario :=
      AContexto.Anfitrion.CrearPantalla(oClaseFormulario);
    try
      Result := ADestino.Formulario as IMantenimientoEmbebido;
    except
      FreeAndNil(ADestino.Formulario);
      raise EServicioNoDisponible.Create(
        SErrorMantenimientoEmbebidoNoDisponible);
    end;
    ADestino.Formulario.Hide;
    bBusquedaTemporal := PrepararModoBusqueda(
      AContexto, ADestino, Result);
    try
      AContexto.Gestor.EmbedForm(
        ADestino.Formulario, Result, ADestino.Titulo,
        ADestino.Clave, True);
    finally
      if bBusquedaTemporal then
        Result.DesactivarModoBusqueda;
    end;
    AContexto.RegistroLog.RegistrarInformacion(
      'Pantalla abierta: ' + AContexto.Pantalla.Caption);
  end;
end;

function ActivarMantenimiento(
  const AContexto: TContextoAperturaPantalla;
  const ADestino: TDestinoAperturaPantalla): IMantenimientoEmbebido;
begin
  Result := AContexto.Gestor.MantenimientoDeForm(
    ADestino.Formulario);
  if not Assigned(Result) then
    raise EServicioNoDisponible.Create(
      SErrorMantenimientoEmbebidoNoDisponible);
  if ADestino.Formulario.Parent is TcxTabSheet then
  begin
    (ADestino.Formulario.Parent as TcxTabSheet).PageControl.ActivePage :=
      ADestino.Formulario.Parent as TcxTabSheet;
  end;
end;

procedure AbrirMantenimiento(
  const AContexto: TContextoAperturaPantalla;
  const AMantenimiento: IMantenimientoEmbebido);
begin
  if Assigned(AMantenimiento) then
  begin
    if AContexto.Busqueda <> '' then
    begin
      AMantenimiento.PrepararBusquedaExterna(AContexto.Busqueda);
      AMantenimiento.AbrirTablaPrincipal(True);
      if not AMantenimiento.LocalizarYEnfocar(AContexto.Busqueda) then
      begin
        ShowMessageFmt(SLocateNotFnd,
          [AContexto.Busqueda, AContexto.Pantalla.Caption]);
      end;
    end
    else
      AMantenimiento.AbrirTablaPrincipal(False);
  end;
end;

procedure ShowMto(AOwner: TComponent;
                  ACall: String;
                  ABusq:string = '');
var
  oContexto: TContextoAperturaPantalla;
  oDestino: TDestinoAperturaPantalla;
  oMto: IMantenimientoEmbebido;
begin
  oContexto.Anfitrion := ExigirAnfitrionPantallas(AOwner);
  oContexto.RegistroLog := ExigirRegistroLog(AOwner);
  oContexto.Anfitrion.PrepararAperturaPantalla;
  oContexto.Gestor := oContexto.Anfitrion.GestorVentanas;
  oContexto.Pantalla :=
    oContexto.Anfitrion.RegistroPantallas.GetElement(ACall);
  oContexto.Busqueda := ABusq;
  if ResolverPantallaAccesible(oContexto, ACall) then
  begin
    oDestino := ResolverDestinoApertura(oContexto);
    if Assigned(oDestino.Formulario) then
      oMto := ActivarMantenimiento(oContexto, oDestino)
    else
      oMto := CrearMantenimiento(oContexto, oDestino);
    AbrirMantenimiento(oContexto, oMto);
  end;
end;

function CrearDataModule(const ADataUnit: string;
                         AOwner: TComponent): TDataModule;
var
  Clase: TComponentClass;
  RegistroLog: IRegistroLog;
begin
  Result := nil;
  RegistroLog := ExigirRegistroLog(AOwner);
  Clase := ClaseDataModule(ADataUnit);
  if Clase = nil then
    RegistroLog.RegistrarError(
      'Data module sin clase registrada: ' + ADataUnit)
  else
    Result := TDataModule(Clase.Create(AOwner));
end;

function ResolverCallFactura(
  const AResolutor: IResolutorDestinoFactura;
  const ANumero, ASerie: string): string;
begin
  Result := 'Facturas';
  if Assigned(AResolutor) then
    Result := AResolutor.Resolver(ANumero, ASerie);
end;

end.
