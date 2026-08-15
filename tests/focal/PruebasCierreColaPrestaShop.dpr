program PruebasCierreColaPrestaShop;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  inLibPrestaShopCierre;

type
  TColaCierreDoble = class(TInterfacedObject, ICierreColaPrestaShop)
  private
    FActiva: Boolean;
    FBloqueos: Integer;
    FCancelaciones: Integer;
    FForzados: Integer;
    FEsperas: Integer;
  public
    constructor Create(AActiva: Boolean);
    function BloquearNuevasReclamaciones: Boolean;
    procedure CancelarCierre;
    procedure DetenerTrasTrabajoActual;
    procedure DetenerLiberandoTrabajoActual;
    property Bloqueos: Integer read FBloqueos;
    property Cancelaciones: Integer read FCancelaciones;
    property Esperas: Integer read FEsperas;
    property Forzados: Integer read FForzados;
  end;

procedure Comprobar(ACondicion: Boolean; const AMensaje: string);
begin
  if not ACondicion then
    raise Exception.Create(AMensaje);
end;

constructor TColaCierreDoble.Create(AActiva: Boolean);
begin
  inherited Create;
  FActiva := AActiva;
end;

function TColaCierreDoble.BloquearNuevasReclamaciones: Boolean;
begin
  Inc(FBloqueos);
  Result := FActiva;
end;

procedure TColaCierreDoble.CancelarCierre;
begin
  Inc(FCancelaciones);
end;

procedure TColaCierreDoble.DetenerTrasTrabajoActual;
begin
  Inc(FEsperas);
end;

procedure TColaCierreDoble.DetenerLiberandoTrabajoActual;
begin
  Inc(FForzados);
end;

procedure ProbarPendientesSinTrabajoActivo;
var
  iConsultas: Integer;
  oDoble: TColaCierreDoble;
  oInterfaz: ICierreColaPrestaShop;
begin
  iConsultas := 0;
  oDoble := TColaCierreDoble.Create(False);
  oInterfaz := oDoble;
  Comprobar(
    IntentarCerrarColaPrestaShop(
      oInterfaz,
      function: TDecisionCierrePrestaShop
      begin
        Inc(iConsultas);
        Result := dcpCancelar;
      end),
    'Una cola sin artículo activo debe permitir cerrar');
  Comprobar(iConsultas = 0,
    'Los pendientes sin artículo activo no deben mostrar aviso');
  Comprobar(oDoble.Bloqueos = 1,
    'La consulta debe cerrar la puerta antes de comprobar la fila activa');
end;

procedure ProbarEspera;
var
  oDoble: TColaCierreDoble;
  oInterfaz: ICierreColaPrestaShop;
begin
  oDoble := TColaCierreDoble.Create(True);
  oInterfaz := oDoble;
  Comprobar(
    IntentarCerrarColaPrestaShop(
      oInterfaz,
      function: TDecisionCierrePrestaShop
      begin
        Result := dcpEsperar;
      end),
    'Esperar debe aprobar el cierre');
  Comprobar(oDoble.Esperas = 1,
    'Esperar debe terminar solamente el trabajo actual');
  Comprobar(oDoble.Forzados = 0,
    'Esperar no debe liberar la reclamación');
end;

procedure ProbarCierreDeTodosModos;
var
  oDoble: TColaCierreDoble;
  oInterfaz: ICierreColaPrestaShop;
begin
  oDoble := TColaCierreDoble.Create(True);
  oInterfaz := oDoble;
  Comprobar(
    IntentarCerrarColaPrestaShop(
      oInterfaz,
      function: TDecisionCierrePrestaShop
      begin
        Result := dcpCerrarDeTodosModos;
      end),
    'Cerrar de todos modos debe aprobar el cierre');
  Comprobar(oDoble.Forzados = 1,
    'Cerrar de todos modos debe liberar el trabajo en el punto seguro');
  Comprobar(oDoble.Esperas = 0,
    'Cerrar de todos modos no debe completar el resto del artículo');
end;

procedure ProbarCancelacion;
var
  oDoble: TColaCierreDoble;
  oInterfaz: ICierreColaPrestaShop;
begin
  oDoble := TColaCierreDoble.Create(True);
  oInterfaz := oDoble;
  Comprobar(
    not IntentarCerrarColaPrestaShop(
      oInterfaz,
      function: TDecisionCierrePrestaShop
      begin
        Result := dcpCancelar;
      end),
    'Cancelar debe impedir el cierre');
  Comprobar(oDoble.Cancelaciones = 1,
    'Cancelar debe reabrir el consumo de la cola');
end;

procedure ProbarFalloDelDialogo;
var
  bCapturada: Boolean;
  oDoble: TColaCierreDoble;
  oInterfaz: ICierreColaPrestaShop;
begin
  bCapturada := False;
  oDoble := TColaCierreDoble.Create(True);
  oInterfaz := oDoble;
  try
    IntentarCerrarColaPrestaShop(
      oInterfaz,
      function: TDecisionCierrePrestaShop
      begin
        raise Exception.Create('fallo simulado del diálogo');
      end);
  except
    on E: Exception do
      bCapturada := True;
  end;
  Comprobar(bCapturada,
    'El fallo simulado debe propagarse');
  Comprobar(oDoble.Cancelaciones = 1,
    'Un fallo del diálogo debe reabrir el consumo');
end;

procedure ProbarPuertaAtomica;
var
  oControl: TControlTrabajoPrestaShop;
begin
  oControl := TControlTrabajoPrestaShop.Create;
  try
    Comprobar(oControl.IntentarIniciarTrabajo,
      'La puerta abierta debe permitir reclamar');
    Comprobar(oControl.BloquearNuevasReclamaciones,
      'El cierre debe detectar el trabajo reservado');
    oControl.SolicitarCerrarDeTodosModos;
    Comprobar(oControl.DebeLiberarTrabajo,
      'El cierre forzado debe solicitar liberar el trabajo actual');
    oControl.FinalizarTrabajo;
    Comprobar(not oControl.DebeLiberarTrabajo,
      'No debe quedar liberación pendiente tras finalizar la fila');
    Comprobar(not oControl.IntentarIniciarTrabajo,
      'La puerta cerrada no debe permitir otra reclamación');
    oControl.CancelarCierre;
    Comprobar(oControl.PermiteNuevasReclamaciones,
      'Cancelar debe reabrir la puerta');
  finally
    FreeAndNil(oControl);
  end;
end;

begin
  try
    ProbarPendientesSinTrabajoActivo;
    ProbarEspera;
    ProbarCierreDeTodosModos;
    ProbarCancelacion;
    ProbarFalloDelDialogo;
    ProbarPuertaAtomica;
    Writeln('CIERRE_COLA_PRESTASHOP=OK');
  except
    on E: Exception do
    begin
      Writeln('CIERRE_COLA_PRESTASHOP=ERROR: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
