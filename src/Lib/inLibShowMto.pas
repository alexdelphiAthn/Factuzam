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
  Classes, Forms, Menus, Controls, Data.DB, Uni, System.SysUtils,
  Vcl.Dialogs, cxPC, inLibUnitForm, inLibFormManager;

type
  // Lo que ShowMto necesita del formulario principal. TfrmMtoPrincipal
  // lo implementa; así esta librería no depende de la unidad inMto*.
  IAnfitrionPantallas = interface
    ['{3C56E82E-C2DB-418B-8850-5F548E7C9114}']
    // Gestor de ventanas embebidas (lo crea si aún no existe).
    function GestorVentanas: TEmbeddedFormManager;
    // Registro de pantallas cargado de fza_winforms.
    function RegistroPantallas: TfzaWinF;
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
  function ResolverCallFactura(AConexion: TUniConnection;
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
      inLibLog,
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

// Descubre el anfitrion o falla ruidosamente (PLAN_SOLID Fase 4):
// abrir una pantalla sin anfitrion era antes un no-op silencioso.
function ExigirAnfitrionPantallas(
  AOwner: TComponent): IAnfitrionPantallas;
begin
  if not Supports(AOwner, IAnfitrionPantallas, Result) then
    raise EServicioNoDisponible.Create(
      SErrorAnfitrionPantallasNoDisponible);
end;

procedure ShowMto(AOwner: TComponent;
                  ACall: String;
                  ABusq:string = '');
var
  oAnfitrion: IAnfitrionPantallas;
  oGestor: TEmbeddedFormManager;
  ofzaF: TfzaForm;
  TargetForm: TForm;
  FormClass: TFormClass;
  oMto: IMantenimientoEmbebido;
  iNum : Integer;
  iActiva, iSiguiente, iPrimera, iHueco: Integer;
  sClave: string;
  NewCaption: string;
  bBusquedaTemporal: Boolean;
begin
  oAnfitrion := ExigirAnfitrionPantallas(AOwner);
  oAnfitrion.PrepararAperturaPantalla;
  oGestor := oAnfitrion.GestorVentanas;
  ofzaF := oAnfitrion.RegistroPantallas.GetElement(ACall);
  if ofzaF = nil then
  begin
    ShowMessageFmt(SResWinFNotFnd, [ACall]);
    Exit;
  end;
  if (ofzaF.mnMenuItem <> nil) and (not ofzaF.mnMenuItem.Visible) then
  begin
    inLibLog.Log.LogWarning('Intento de acceso a menú oculto: ' + ACall);
    Exit;
  end;
  // Identidad de la ventana: clave estable CALL[#instancia] separada
  // del caption visible (antes se buscaba por caption y cambiar un
  // título rompía la detección de instancias).
  NewCaption := ofzaF.Caption;
  sClave := ofzaF.Call;
  if ofzaF.NumVentanas > 1 then
  begin
    if ABusq <> '' then
    begin
      // Ctrl+A: la instancia 1 es la de búsquedas (filtro Todos).
      // Si no existe la creamos; si existe la reutilizamos.
      sClave := ofzaF.Call + '#1';
      NewCaption := ofzaF.Caption + ' 1';
      TargetForm := oGestor.FormPorClave(sClave);
    end
    else
    begin
      // Apertura normal (Ctrl+K / menu) con rotacion. Las instancias van
      // de 2..NumVentanas (la 1 se reserva para busquedas). Regla:
      //  - ninguna abierta -> crea la #2.
      //  - estas en otra pantalla -> trae al frente la mas baja abierta.
      //  - estas en una instancia y hay otra abierta por encima -> saltas
      //    a ella (rota el foco).
      //  - estas en la ultima abierta y queda hueco -> crea la siguiente.
      //  - todo lleno y estas en la ultima -> vuelves a la primera
      //    (rotacion circular 2->3->4->2).
      iActiva := NumInstanciaActiva(oGestor, ofzaF.Call);
      iPrimera := 0;
      iSiguiente := 0;
      iHueco := 0;
      for iNum := 2 to ofzaF.NumVentanas do
      begin
        if oGestor.FormPorClave(
             ofzaF.Call + '#' + IntToStr(iNum)) <> nil then
        begin
          if iPrimera = 0 then
            iPrimera := iNum;
          if (iSiguiente = 0) and (iNum > iActiva) then
            iSiguiente := iNum;
        end
        else if iHueco = 0 then
          iHueco := iNum;
      end;
      if iPrimera = 0 then
        iNum := 2
      else if iActiva = 0 then
        iNum := iPrimera
      else if iSiguiente > 0 then
        iNum := iSiguiente
      else if iHueco > 0 then
        iNum := iHueco
      else
        iNum := iPrimera;
      sClave := ofzaF.Call + '#' + IntToStr(iNum);
      NewCaption := ofzaF.Caption + ' ' + IntToStr(iNum);
      // Si la clave elegida existe -> se activa; si no -> se crea (el
      // bloque 'if TargetForm = nil' de abajo hace ambos casos).
      TargetForm := oGestor.FormPorClave(sClave);
    end;
  end
  else
    TargetForm := oGestor.FormPorClave(sClave);
  if TargetForm = nil then
  begin
    FormClass := ClasePantalla(ofzaF.UnitForm);
    if FormClass = nil then
    begin
      // Antes era un FindType RTTI que fallaba en runtime; ahora la
      // clase o está en el catálogo o se avisa (y el arranque ya lo
      // dejó en el log vía ComprobarRegistradas).
      inLibLog.Log.LogError('Pantalla sin clase registrada: ' +
                            ofzaF.UnitForm);
      ShowMessageFmt(SClassRttiNotFnd, [ofzaF.UnitForm]);
      Exit;
    end;
    TargetForm := FormClass.Create(AOwner);
    TargetForm.Hide;
    bBusquedaTemporal := False;
    // Si es la instancia 1 (reservada para busquedas), marcar el modo
    // y recortar el layout antes de embeber: sin Lista, sin Busqueda,
    // sin Precarga, sin Exportar a Excel; navegador con solo Insert/
    // Delete/Edit/Post/Cancel. Asi el Show muestra ya la UI reducida.
    if (ABusq <> '') and
       Supports(TargetForm, IMantenimientoEmbebido, oMto) then
    begin
      if (ofzaF.NumVentanas > 1) and
         (sClave = ofzaF.Call + '#1') then
        oMto.ActivarModoBusqueda(True)
      else
      begin
        oMto.ActivarModoBusqueda(False);
        bBusquedaTemporal := True;
      end;
    end;
    try
      oGestor.EmbedForm(TargetForm, NewCaption, sClave, True);
    finally
      if bBusquedaTemporal and
         Supports(TargetForm, IMantenimientoEmbebido, oMto) then
        oMto.DesactivarModoBusqueda;
    end;
    inLibLog.Log.LogInfo('Pantalla abierta: ' + ofzaF.Caption);
  end
  else
  begin
    if (TargetForm.Parent is TcxTabSheet) then
      (TargetForm.Parent as TcxTabSheet).PageControl.ActivePage :=
                                             (TargetForm.Parent as TcxTabSheet);
  end;
  // Carga inicial de la lista principal:
  // - Sin parametro de busqueda: async, asi el tab aparece de inmediato
  //   y se rellena en background mientras la UI sigue respondiendo.
  // - Con parametro de busqueda: sincrono, porque el Locate necesita la
  //   query activa al volver.
  if Supports(TargetForm, IMantenimientoEmbebido, oMto) then
  begin
    if ABusq <> '' then
    begin
      // Busqueda externa: filtrar a la clave recibida antes del Open.
      oMto.PrepararBusquedaExterna(ABusq);
      oMto.AbrirTablaPrincipal(True);
      if not oMto.LocalizarYEnfocar(ABusq) then
        ShowMessageFmt(SLocateNotFnd, [ABusq, ofzaF.Caption]);
    end
    else
      oMto.AbrirTablaPrincipal(False);
  end;
end;

function CrearDataModule(const ADataUnit: string;
                         AOwner: TComponent): TDataModule;
var
  Clase: TComponentClass;
begin
  Result := nil;
  Clase := ClaseDataModule(ADataUnit);
  if Clase = nil then
    inLibLog.Log.LogError('Data module sin clase registrada: ' + ADataUnit)
  else
    Result := TDataModule(Clase.Create(AOwner));
end;

function ResolverCallFactura(AConexion: TUniConnection;
  const ANumero, ASerie: string): string;
var
  qry: TUniQuery;
  sTipo: string;
begin
  Result := 'Facturas';
  if (AConexion = nil) or (not AConexion.Connected) then
    Exit;
  qry := TUniQuery.Create(nil);
  try
    qry.Connection := AConexion;
    qry.SQL.Text :=
      'SELECT TIPO_FAC FROM fza_facturas' +
      ' WHERE NUMERO_FAC = :NUM AND SERIE_FAC = :SER';
    qry.ParamByName('NUM').AsString := ANumero;
    qry.ParamByName('SER').AsString := ASerie;
    qry.Open;
    if not qry.IsEmpty then
    begin
      sTipo := qry.FieldByName('TIPO_FAC').AsString;
      if SameText(sTipo, 'SIMPLIFICADA') then
        Result := 'FacturasSimplif';
    end;
  finally
    FreeAndNil(qry);
  end;
end;

end.
