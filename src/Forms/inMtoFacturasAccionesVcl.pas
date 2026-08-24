{******************************************************************************}
{                                                                              }
{  Acciones modales de impresion, rectificacion y sustitucion de facturas.     }
{                                                                              }
{******************************************************************************}
unit inMtoFacturasAccionesVcl;

interface

uses
  System.Classes, Data.DB, Uni,
  inLibComandoImprimirFacturas, inLibConexionesIntf,
  inLibContextoSesionIntf, inLibParametrosIntf, inLibPermisosIntf,
  inLibLogIntf, UniDataFacturas;

type
  TGuardarPendienteFacturaVcl = reference to procedure;
  TObtenerFacturasFiltradasVcl = reference to function:
    TReferenciasComandoFactura;

procedure ArchivarFacturaConsolidadaVcl(
  AFacturas: TdmFacturas;
  const ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
procedure ImprimirFacturaVcl(
  AOwnerSesion: TComponent;
  AFacturas: TdmFacturas;
  ACabecera: TDataSet;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  APuedeImprimir: Boolean;
  const AGuardarPendiente: TGuardarPendienteFacturaVcl;
  const AObtenerFiltradas: TObtenerFacturasFiltradasVcl);
procedure RectificarFacturaVcl(
  AOwner: TComponent;
  AFacturas: TdmFacturas);
procedure FacturarTicketVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion);

implementation

uses
  System.IOUtils, System.SysUtils, System.UITypes,
  Vcl.Forms, Vcl.Dialogs,
  inLibFacturas, inLibVerifactu, inLibVerifactuTipos,
  inLibMsgFacturas, inMtoComandoImprimirFacturas,
  inMtoModalFacRec, inMtoModalImpFac, inMtoModalFacturarTicket;

procedure ArchivarFacturaConsolidadaVcl(
  AFacturas: TdmFacturas;
  const ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
begin
  try
    TfrmPrintFac.ArchivarFacturaConsolidada(AFacturas, ASerie, ANumero);
  except
    on E: Exception do
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarError(
          'No se pudo archivar el PDF al consolidar ' +
          ASerie + '\' + ANumero + ': ' + E.Message);
  end;
end;

function GuardarTrabajoLotePdf(
  const ADirectorio, AFormato: string;
  const AResultado: TResultadoComandoImprimirFacturas;
  out ARuta, AError: string): Boolean;
var
  sContenido: string;
  sEstado: string;
begin
  Result := False;
  ARuta := '';
  AError := '';
  try
    if not System.SysUtils.DirectoryExists(ADirectorio) and
       not System.SysUtils.ForceDirectories(ADirectorio) then
      raise Exception.CreateFmt(
        'No se puede preparar la carpeta "%s".',
        [ADirectorio]);
    ARuta := TPath.Combine(ADirectorio, 'trabajo_lote.txt');
    if AResultado.EsError then
      sEstado := 'CON INCIDENCIAS'
    else
      sEstado := 'CORRECTO';
    sContenido :=
      'Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + sLineBreak +
      'Proceso: generación de PDF de facturas filtradas' + sLineBreak +
      'Formato: ' + AFormato + sLineBreak +
      'Carpeta destino: ' + ADirectorio + sLineBreak +
      'Estado: ' + sEstado + sLineBreak +
      'Resultado: ' + AResultado.Mensaje + sLineBreak;
    TFile.WriteAllText(ARuta, sContenido, TEncoding.UTF8);
    Result := True;
  except
    on E: Exception do
      AError := E.ClassName + ': ' + E.Message;
  end;
end;

procedure ImprimirFacturaVcl(
  AOwnerSesion: TComponent;
  AFacturas: TdmFacturas;
  ACabecera: TDataSet;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  APuedeImprimir: Boolean;
  const AGuardarPendiente: TGuardarPendienteFacturaVcl;
  const AObtenerFiltradas: TObtenerFacturasFiltradasVcl);
var
  bPuedeUsarActual: Boolean;
  Fase: string;
  Formulario: TfrmPrintFac;
  oOwnerFormulario: TComponent;
  oOwnerLote: TComponent;
begin
  if not APuedeImprimir then
    Abort;
  if SinVerifactuActivo(AParametros) and
     Assigned(AGuardarPendiente) then
    AGuardarPendiente();
  Fase := ACabecera.FieldByName(ffasefac).AsString;
  bPuedeUsarActual :=
    not (
      ((Fase = '') or SameText(Fase, 'BORRADOR')) and
      (ACabecera.FieldByName(fescon).AsString <> 'S') and
      (ModoVerifactu(AParametros) <> mvSinVerifactu));
  if not bPuedeUsarActual and not Assigned(AObtenerFiltradas) then
  begin
    ShowMessage(SAvisoBorradorPendienteImpresionFiscal);
    Abort;
  end;
  oOwnerFormulario := AOwnerSesion;
  if oOwnerFormulario = nil then
    oOwnerFormulario := Application;
  oOwnerLote := Application.MainForm;
  if oOwnerLote = nil then
    oOwnerLote := oOwnerFormulario;
  Formulario := TfrmPrintFac.Create(oOwnerFormulario);
  try
    Formulario.edtNroFac.Text :=
      ACabecera.FindField(fnrofac).AsString;
    Formulario.edtSerie.Text :=
      ACabecera.FindField(fseriefac).AsString;
    Formulario.dmFac := AFacturas;
    Formulario.ConfigurarLote(
      bPuedeUsarActual,
      AObtenerFiltradas,
      function(
        const AReferencias: TReferenciasComandoFactura;
        const AFormato: string): Boolean
      var
        oDialogo: TFileOpenDialog;
        oResultado: TResultadoComandoImprimirFacturas;
        oTipoMensaje: TMsgDlgType;
        sDirectorio: string;
        sErrorTrabajo: string;
        sMensaje: string;
        sRutaTrabajo: string;
      begin
        Result := False;
        sDirectorio := AParametros.GetPath('appDirPDF');
        oDialogo := TFileOpenDialog.Create(nil);
        try
          oDialogo.Title := 'Seleccione una carpeta';
          oDialogo.Options :=
            [fdoPickFolders, fdoForceFileSystem, fdoPathMustExist];
          if DirectoryExists(sDirectorio) then
            oDialogo.DefaultFolder := sDirectorio;
          // El modal de impresion es fsStayOnTop: el dialogo debe ser suyo
          // para que Windows lo mantenga visible por encima.
          if not oDialogo.Execute(Formulario.Handle) then
            Exit;
          sDirectorio := oDialogo.FileName;
        finally
          oDialogo.Free;
        end;
        Screen.Cursor := crHourGlass;
        try
          try
            oResultado := EjecutarComandoImprimirFacturas(
              TArray<string>.Create(
                '/imprimirfacturas',
                SerializarReferenciasComandoFacturas(AReferencias),
                AFormato,
                sDirectorio),
              oOwnerFormulario,
              AConexiones.ConexionPrincipal,
              AContextoSesion,
              AParametros,
              APermisos,
              ARegistroLog);
          except
            on E: Exception do
            begin
              oResultado := Default(TResultadoComandoImprimirFacturas);
              oResultado.CodigoSalida := 1;
              oResultado.EsError := True;
              oResultado.Mensaje := E.ClassName + ': ' + E.Message;
            end;
          end;
          sMensaje := oResultado.Mensaje;
          if GuardarTrabajoLotePdf(
            sDirectorio,
            AFormato,
            oResultado,
            sRutaTrabajo,
            sErrorTrabajo) then
          begin
            sMensaje := sMensaje + sLineBreak + sLineBreak +
              Format(SInfoTrabajoLoteGuardado, [sRutaTrabajo]);
          end
          else
          begin
            sMensaje := sMensaje + sLineBreak + sLineBreak +
              Format(SErrorGuardarTrabajoLote, [sErrorTrabajo]);
            oResultado.EsError := True;
            if Assigned(ARegistroLog) then
              ARegistroLog.RegistrarError(sMensaje);
          end;
        finally
          Screen.Cursor := crDefault;
        end;
        if oResultado.EsError then
          oTipoMensaje := mtError
        else
          oTipoMensaje := mtInformation;
        MessageDlg(sMensaje, oTipoMensaje, [mbOK], 0);
        Result := True;
      end,
      function(
        const AReferencias: TReferenciasComandoFactura;
        const AFormato: string): Boolean
      var
        sImpresora: string;
      begin
        sImpresora := AParametros.GetString(
          'appImpresoraInformes', '');
        IniciarLoteImpresionFacturas(
          AReferencias,
          AFormato,
          sImpresora,
          oOwnerLote,
          AConexiones.ConexionPrincipal,
          AConexiones,
          AContextoSesion,
          AParametros,
          APermisos,
          ARegistroLog,
          procedure(
            const AResultado: TResultadoLoteImpresionFacturas)
          var
            sMensaje: string;
          begin
            if AResultado.Error <> '' then
            begin
              sMensaje := Format(
                SErrorLoteImpresionFacturas,
                [AResultado.Impresas,
                 AResultado.Solicitadas,
                 AResultado.Error]);
              MessageDlg(sMensaje, mtError, [mbOK], 0);
            end
            else
            begin
              sMensaje := Format(
                SInfoLoteImpresionFacturas,
                [AResultado.Impresas,
                 AResultado.OmitidasNoConsolidadas]);
              MessageDlg(sMensaje, mtInformation, [mbOK], 0);
            end;
          end);
        Result := True;
      end);
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

procedure RectificarFacturaVcl(
  AOwner: TComponent;
  AFacturas: TdmFacturas);
var
  Formulario: TfrmGenFacRec;
begin
  Formulario := TfrmGenFacRec.Create(AOwner);
  try
    Formulario.Preparar(AFacturas);
    Formulario.ShowModal;
  finally
    Formulario.Free;
  end;
end;

procedure FacturarTicketVcl(
  AOwner: TComponent;
  ACabecera: TDataSet;
  const AParametros: IParametrosAplicacion);
var
  Resultado: TFacturarTicketResult;
  Serie: string;
  Numero: string;
begin
  Serie := ACabecera.FieldByName('SERIE_FAC').AsString;
  Numero := ACabecera.FieldByName('NUMERO_FAC').AsString;
  if Trim(Numero) = '' then
    ShowMessage(SErrorBorradorListaNoSeleccionado)
  else if not SameText(
    ACabecera.FieldByName('TIPO_FAC').AsString,
    'SIMPLIFICADA') then
    ShowMessage(SErrorFacturarTicketRequiereSimplificado)
  else
  begin
    Resultado := TfrmModalFacturarTicket.Ejecutar(
      AOwner,
      Serie,
      Numero,
      ACabecera.FieldByName('CODIGO_EMP_FAC').AsString,
      ACabecera.FieldByName('CODIGO_ALM_FAC').AsString,
      ACabecera.FieldByName('FECHA_FAC').AsDateTime);
    if Resultado.Aceptado then
    begin
      ShowMessage(Format(
        SInfoBorradorSustitucionTicketCreado,
        [Resultado.SerieNueva, Resultado.NumeroNueva,
         Serie, Numero, ModoVerifactuTexto(AParametros)]));
      ACabecera.Refresh;
    end;
  end;
end;

end.
