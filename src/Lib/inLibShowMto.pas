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
  function ResolverCallFactura(AConexion: TUniConnection;
    const ANumero, ASerie: string): string;
  // Crea el data module de la pantalla desde el registro de clases. El
  // cableado con el form (FCurrentForm, dsTablaG, SQL de perfil) vive
  // ahora en TfrmMtoGen.CrearTablaPrincipal.
  function CrearDataModule(const ADataUnit: string;
                           AOwner: TComponent): TDataModule;

implementation

 uses
      inLibMsg,
      inLibLog,
      inLibRegistroPantallas,
      inLibVentanaEmbebidaIntf;

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
  sClave: string;
  NewCaption: string;
  bBusquedaTemporal: Boolean;
begin
  if not Supports(AOwner, IAnfitrionPantallas, oAnfitrion) then Exit;
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
  TargetForm := nil;
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
      // Apertura normal del usuario: empieza en la 2 para dejar la 1
      // reservada como instancia de búsqueda.
      iNum := 2;
      sClave := ofzaF.Call + '#2';
      NewCaption := ofzaF.Caption + ' 2';
      while (iNum <= ofzaF.NumVentanas) and
            (oGestor.FormPorClave(sClave) <> nil) do
      begin
        Inc(iNum);
        sClave := ofzaF.Call + '#' + IntToStr(iNum);
        NewCaption := ofzaF.Caption + ' ' + IntToStr(iNum);
      end;
      if iNum > ofzaF.NumVentanas then
      begin
        sClave := ofzaF.Call + '#2';
        NewCaption := ofzaF.Caption + ' 2';
        TargetForm := oGestor.FormPorClave(sClave);
      end;
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
