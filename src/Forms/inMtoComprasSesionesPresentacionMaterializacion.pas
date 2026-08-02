{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionMaterializacion               }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Cablea el caso de uso de materializacion de una sesion de compra con      }
{    sus modales y datasets. Recibe un entorno explicito: nunca el             }
{    formulario completo ni un contexto general de repositorios.               }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionMaterializacion;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  Uni,
  inLibComprasSesiones,
  inLibComprasSesionesAplicacionIntf;

type
  // Piezas minimas que necesita el cableado. Cada campo es una
  // capacidad concreta; no hay bolsa de servicios ni referencia visual
  // a la pantalla salvo el propietario de los modales.
  TEntornoMaterializacionCompraSesion = record
    Propietario: TComponent;
    Conexion: TUniConnection;
    Servicio: TServicioComprasSesiones;
    Usuario: string;
    Cabecera: TDataSet;
    Lineas: TDataSet;
    Documentos: TDataSet;
    FuenteAlmacenes: TDataSource;
    FuenteTarifas: TDataSource;
    FuenteTemporadas: TDataSource;
    Registrar: TProc<string>;
    RefrescarFotos: TProc;
  end;

function CrearAplicacionMaterializacionCompraSesionVcl(
  const AEntorno: TEntornoMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;

implementation

uses
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  inLibComprasSesionesAplicacion,
  inLibComprasSesionesCreacion,
  inLibComprasSesionesCreacionDataSet,
  inLibComprasSesionesIntf,
  inLibMsgCompras,
  inLibShowMto,
  inLibValoresAutomaticos,
  inMtoComprasSesionesMaterializacionVcl,
  inMtoModalCrearAlbaranSesion,
  inMtoModalDocsCreados,
  inMtoModalIncidencias;

// Los callbacks se construyen por bloques para que ninguno supere el
// tamano admitido y para que se lean las cuatro responsabilidades:
// lecturas, escrituras, avisos y dialogos.
// El entorno viaja POR VALOR a proposito: los metodos anonimos capturan
// el parametro y una copia propia evita depender del ciclo de vida del
// registro del llamador.
procedure ComponerLecturas(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.LeerEstado :=
    function: TEstadoSesionCreacion
    begin
      Result := LeerEstadoSesionCreacion(AEntorno.Cabecera);
    end;
  ACallbacks.GuardarEdicion :=
    procedure
    begin
      if AEntorno.Cabecera.State in [dsEdit, dsInsert] then
        AEntorno.Cabecera.Post;
      if AEntorno.Lineas.State in [dsEdit, dsInsert] then
        AEntorno.Lineas.Post;
    end;
  ACallbacks.NormalizarDuplicados :=
    function(const AEstado: TEstadoSesionCreacion): Integer
    begin
      Result := AEntorno.Servicio.NormalizarDuplicadosIntraSesion(
        AEntorno.Usuario,
        AEstado.Serie,
        AEstado.Numero);
    end;
  ACallbacks.Validar :=
    function(out AIncidencias: TIncidenciasMaterializacionSesion): Boolean
    var
      iIncidencia: Integer;
      Lista: TStringList;
    begin
      Lista := TStringList.Create;
      try
        Result := AEntorno.Servicio.ValidarSesionDetallado(Lista);
        SetLength(AIncidencias, Lista.Count);
        for iIncidencia := 0 to Lista.Count - 1 do
          AIncidencias[iIncidencia] := Lista[iIncidencia];
      finally
        FreeAndNil(Lista);
      end;
    end;
end;

procedure ComponerEscrituras(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.CalcularDefectos :=
    function(const AEstado: TEstadoSesionCreacion):
      TDefectosDialogoCreacion
    begin
      Result := CalcularDefectosDialogoCreacion(
        AEstado,
        ObtenerSerieDefecto(
          AEntorno.Conexion,
          AEstado.Empresa,
          'AB'),
        ObtenerSerieDefecto(
          AEntorno.Conexion,
          AEstado.Empresa,
          'PC'));
    end;
  ACallbacks.ActualizarCabecera :=
    procedure(const AAjustes: TAjustesCreacionElegidos)
    var
      Cabecera: TCabeceraSesionActualizada;
    begin
      Cabecera := ComponerCabeceraActualizada(AAjustes);
      EscribirCabeceraSesionCreacion(AEntorno.Cabecera, Cabecera);
    end;
  ACallbacks.Materializar :=
    function(
      const AAjustes: TAjustesCreacionElegidos;
      out AResultado: TResultadoMaterializacionSesion): Boolean
    var
      Parametros: TParametrosMaterializacionSesion;
    begin
      Parametros := ComponerParametrosMaterializacion(
        AEntorno.Usuario,
        AAjustes);
      Screen.Cursor := crHourGlass;
      try
        Result := AEntorno.Servicio.EjecutarMaterializacion(
          Parametros,
          AResultado);
      finally
        Screen.Cursor := crDefault;
      end;
    end;
  ACallbacks.Refrescar :=
    procedure
    begin
      AEntorno.Cabecera.Refresh;
      if AEntorno.Documentos.Active then
        AEntorno.Documentos.Refresh
      else
        AEntorno.Documentos.Open;
      if Assigned(AEntorno.RefrescarFotos) then
        AEntorno.RefrescarFotos();
    end;
end;

procedure ComponerAvisos(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.Registrar :=
    procedure(const ATexto: string)
    begin
      if Assigned(AEntorno.Registrar) then
        AEntorno.Registrar(ATexto);
    end;
  ACallbacks.MostrarBloqueo :=
    procedure(AMotivo: TMotivoBloqueoCreacion)
    begin
      case AMotivo of
        mbcSinCabecera:
          ShowMessage(SErrorSesionCompraNoActiva);
        mbcYaMaterializada:
          ShowMessage(SErrorSesionYaMaterializada);
      end;
    end;
  ACallbacks.InformarDuplicados :=
    procedure(ACantidad: Integer)
    begin
      ShowMessage(Format(
        SInfoDuplicadosSesionMarcadosReusar,
        [ACantidad]));
      AEntorno.Lineas.Refresh;
    end;
  ACallbacks.MostrarIncidencias :=
    procedure(const AIncidencias: TIncidenciasMaterializacionSesion)
    var
      sIncidencia: string;
      Lista: TStringList;
    begin
      Lista := TStringList.Create;
      try
        for sIncidencia in AIncidencias do
          Lista.Add(sIncidencia);
        TfrmModalIncidencias.Mostrar(
          AEntorno.Propietario,
          'Hay incidencias que impiden materializar la sesion:',
          Lista);
      finally
        FreeAndNil(Lista);
      end;
    end;
end;

procedure ComponerDialogos(
  AEntorno: TEntornoMaterializacionCompraSesion;
  var ACallbacks: TCallbacksMaterializacionCompraSesion);
begin
  ACallbacks.SolicitarAjustes :=
    function(
      const AEstado: TEstadoSesionCreacion;
      const ADefectos: TDefectosDialogoCreacion;
      out AAjustes: TAjustesCreacionElegidos): Boolean
    begin
      Result := TfrmModalCrearAlbaranSesion.Solicitar(
        AEntorno.Propietario,
        AEntorno.FuenteAlmacenes,
        AEntorno.FuenteTarifas,
        AEntorno.FuenteTemporadas,
        AEstado,
        ADefectos,
        AAjustes);
    end;
  ACallbacks.MostrarResultado :=
    procedure(const AResultado: TResultadoMaterializacionSesion)
    var
      DocumentoSeleccionado: TDocumentoMaterializado;
    begin
      if Length(AResultado.Documentos) = 0 then
        ShowMessage(SInfoSesionMaterializadaSinDocumentos)
      else if TfrmModalDocsCreados.Seleccionar(
        AEntorno.Propietario,
        AResultado.Documentos,
        DocumentoSeleccionado) then
      begin
        if SameText(DocumentoSeleccionado.Tipo, 'Albaran') then
          ShowMto(
            Application.MainForm,
            'AlbaranesCompra',
            DocumentoSeleccionado.Serie + ',' +
              DocumentoSeleccionado.Numero)
        else if SameText(DocumentoSeleccionado.Tipo, 'Pedido') then
          ShowMto(
            Application.MainForm,
            'PedidosCompra',
            DocumentoSeleccionado.Serie + ',' +
              DocumentoSeleccionado.Numero);
      end;
    end;
  ACallbacks.MostrarError :=
    procedure(const AMensaje: string)
    begin
      TfrmModalIncidencias.MostrarMensaje(
        AEntorno.Propietario,
        'No se pudo materializar la sesion:',
        '[MATERIALIZAR] ' + AMensaje);
    end;
end;

function CrearAplicacionMaterializacionCompraSesionVcl(
  const AEntorno: TEntornoMaterializacionCompraSesion):
  IAplicacionMaterializacionCompraSesion;
var
  Callbacks: TCallbacksMaterializacionCompraSesion;
  Adaptador: TAdaptadorMaterializacionCompraSesionVcl;
  Operaciones: IOperacionesMaterializacionCompraSesion;
  Vista: IVistaMaterializacionCompraSesion;
begin
  if not Assigned(AEntorno.Servicio) then
    raise EArgumentNilException.Create('AEntorno.Servicio');
  if not Assigned(AEntorno.Cabecera) then
    raise EArgumentNilException.Create('AEntorno.Cabecera');
  Callbacks := Default(TCallbacksMaterializacionCompraSesion);
  ComponerLecturas(AEntorno, Callbacks);
  ComponerEscrituras(AEntorno, Callbacks);
  ComponerAvisos(AEntorno, Callbacks);
  ComponerDialogos(AEntorno, Callbacks);
  Adaptador := TAdaptadorMaterializacionCompraSesionVcl.Create(Callbacks);
  Operaciones := Adaptador;
  Vista := Adaptador;
  Result := CrearAplicacionMaterializacionCompraSesion(
    Operaciones,
    Vista);
end;

end.
