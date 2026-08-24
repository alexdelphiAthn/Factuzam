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
  inLibCorreoTickets,
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

function TextoResumenCorreoLote(
  ACorreoSolicitado: Boolean;
  AEnviados, ASinDestinatario, AConError: Integer;
  const ADetalle: string): string;
begin
  if not ACorreoSolicitado then
  begin
    Result := 'Email solicitado: No' + sLineBreak;
    Exit;
  end;
  Result :=
    'Email solicitado: Sí' + sLineBreak +
    Format('Emails enviados: %d', [AEnviados]) + sLineBreak +
    Format('Sin EMAIL_CLIENTE_FAC: %d', [ASinDestinatario]) + sLineBreak +
    Format('Errores de envío: %d', [AConError]) + sLineBreak;
  if Trim(ADetalle) <> '' then
    Result := Result + sLineBreak +
      'Detalle de envíos:' + sLineBreak + ADetalle + sLineBreak;
end;

function TieneIncidenciasCorreoLote(
  ACorreoSolicitado: Boolean;
  ASinDestinatario, AConError: Integer): Boolean;
begin
  Result := ACorreoSolicitado and
    ((ASinDestinatario > 0) or (AConError > 0));
end;

function EnviarPdfFacturaVcl(
  const AParametros: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const AReferencia, ANombreEmpresa, AEmail, ARutaPdf: string;
  out AMensaje: string): Boolean;
var
  oRutas: TStringList;
begin
  oRutas := TStringList.Create;
  try
    oRutas.Add(ARutaPdf);
    Result := EnviarDocumentosPorCorreo(
      AParametros,
      tdcFactura,
      AReferencia,
      ANombreEmpresa,
      AEmail,
      oRutas,
      ARegistroLog,
      AMensaje);
  finally
    oRutas.Free;
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
    if AResultado.EsError or TieneIncidenciasCorreoLote(
      AResultado.CorreoSolicitado,
      AResultado.CorreosSinDestinatario,
      AResultado.CorreosConError) then
      sEstado := 'CON INCIDENCIAS'
    else
      sEstado := 'CORRECTO';
    sContenido :=
      'Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + sLineBreak +
      'Proceso: generación de PDF de facturas filtradas' + sLineBreak +
      'Formato: ' + AFormato + sLineBreak +
      'Carpeta destino: ' + ADirectorio + sLineBreak +
      'Estado: ' + sEstado + sLineBreak +
      'Resultado: ' + AResultado.Mensaje + sLineBreak +
      TextoResumenCorreoLote(
        AResultado.CorreoSolicitado,
        AResultado.CorreosEnviados,
        AResultado.CorreosSinDestinatario,
        AResultado.CorreosConError,
        AResultado.DetalleCorreo);
    TFile.WriteAllText(ARuta, sContenido, TEncoding.UTF8);
    Result := True;
  except
    on E: Exception do
      AError := E.ClassName + ': ' + E.Message;
  end;
end;

function GuardarTrabajoLoteImpresion(
  const ADirectorio, AFormato, AImpresora: string;
  const AResultado: TResultadoLoteImpresionFacturas;
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
    if (AResultado.Error <> '') or TieneIncidenciasCorreoLote(
      AResultado.CorreoSolicitado,
      AResultado.CorreosSinDestinatario,
      AResultado.CorreosConError) then
      sEstado := 'CON INCIDENCIAS'
    else
      sEstado := 'CORRECTO';
    sContenido :=
      'Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + sLineBreak +
      'Proceso: impresión de facturas filtradas' + sLineBreak +
      'Formato: ' + AFormato + sLineBreak +
      'Impresora: ' + AImpresora + sLineBreak +
      'Estado: ' + sEstado + sLineBreak +
      Format('Solicitadas: %d', [AResultado.Solicitadas]) + sLineBreak +
      Format('Impresas: %d', [AResultado.Impresas]) + sLineBreak +
      Format('Omitidas no consolidadas: %d',
        [AResultado.OmitidasNoConsolidadas]) + sLineBreak;
    if AResultado.Error <> '' then
      sContenido := sContenido +
        'Incidencia de impresión: ' + AResultado.Error + sLineBreak;
    sContenido := sContenido + TextoResumenCorreoLote(
      AResultado.CorreoSolicitado,
      AResultado.CorreosEnviados,
      AResultado.CorreosSinDestinatario,
      AResultado.CorreosConError,
      AResultado.DetalleCorreo);
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
  sEmailFactura: string;
  sNombreEmpresa: string;
  sReferencia: string;
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
    Formulario.ConfigurarDataModule(AFacturas);
    sEmailFactura := Trim(
      ACabecera.FieldByName('EMAIL_CLIENTE_FAC').AsString);
    sNombreEmpresa := Trim(
      ACabecera.FieldByName('RAZON_SOCIAL_EMPRESA_FAC').AsString);
    sReferencia :=
      ACabecera.FieldByName(fseriefac).AsString + '\' +
      ACabecera.FieldByName(fnrofac).AsString;
    Formulario.ConfigurarCorreo(
      sEmailFactura,
      function(
        const ARutaPdf, AEmail: string;
        out AMensaje: string): Boolean
      begin
        Result := EnviarPdfFacturaVcl(
          AParametros,
          ARegistroLog,
          sReferencia,
          sNombreEmpresa,
          AEmail,
          ARutaPdf,
          AMensaje);
      end);
    Formulario.ConfigurarLote(
      bPuedeUsarActual,
      AObtenerFiltradas,
      function(
        const AReferencias: TReferenciasComandoFactura;
        const AFormato: string;
        AEnviarEmail: Boolean): Boolean
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
              ARegistroLog,
              AEnviarEmail);
          except
            on E: Exception do
            begin
              oResultado := Default(TResultadoComandoImprimirFacturas);
              oResultado.CodigoSalida := 1;
              oResultado.EsError := True;
              oResultado.Mensaje := E.ClassName + ': ' + E.Message;
              oResultado.CorreoSolicitado := AEnviarEmail;
            end;
          end;
          sMensaje := oResultado.Mensaje;
          if oResultado.CorreoSolicitado then
            sMensaje := sMensaje + sLineBreak + sLineBreak +
              Format(
                'Emails enviados: %d. Sin email: %d. Errores de envío: %d.',
                [oResultado.CorreosEnviados,
                 oResultado.CorreosSinDestinatario,
                 oResultado.CorreosConError]);
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
        if oResultado.EsError or
           (oResultado.CorreosConError > 0) or
           (oResultado.CorreosSinDestinatario > 0) then
          oTipoMensaje := mtError
        else
          oTipoMensaje := mtInformation;
        MessageDlg(sMensaje, oTipoMensaje, [mbOK], 0);
        Result := True;
      end,
      function(
        const AReferencias: TReferenciasComandoFactura;
        const AFormato: string;
        AEnviarEmail: Boolean): Boolean
      var
        sDirectorioTrabajo: string;
        sErrorTrabajo: string;
        sImpresora: string;
        sRutaTrabajo: string;
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
          AEnviarEmail,
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
            end
            else
            begin
              sMensaje := Format(
                SInfoLoteImpresionFacturas,
                [AResultado.Impresas,
                 AResultado.OmitidasNoConsolidadas]);
            end;
            if AResultado.CorreoSolicitado then
            begin
              sMensaje := sMensaje + sLineBreak + sLineBreak +
                Format(
                  'Emails enviados: %d. Sin email: %d. Errores de envío: %d.',
                  [AResultado.CorreosEnviados,
                   AResultado.CorreosSinDestinatario,
                   AResultado.CorreosConError]);
              sDirectorioTrabajo := AParametros.GetPath('appDirPDF');
              if Trim(sDirectorioTrabajo) = '' then
                sDirectorioTrabajo := TPath.Combine(
                  TPath.GetDocumentsPath,
                  'Factuzam');
              if GuardarTrabajoLoteImpresion(
                sDirectorioTrabajo,
                AFormato,
                sImpresora,
                AResultado,
                sRutaTrabajo,
                sErrorTrabajo) then
                sMensaje := sMensaje + sLineBreak + sLineBreak +
                  Format(SInfoTrabajoLoteGuardado, [sRutaTrabajo])
              else
              begin
                sMensaje := sMensaje + sLineBreak + sLineBreak +
                  Format(SErrorGuardarTrabajoLote, [sErrorTrabajo]);
                if Assigned(ARegistroLog) then
                  ARegistroLog.RegistrarError(sMensaje);
              end;
            end;
            if (AResultado.Error <> '') or
               (AResultado.CorreosConError > 0) or
               (AResultado.CorreosSinDestinatario > 0) then
              MessageDlg(sMensaje, mtError, [mbOK], 0)
            else
              MessageDlg(sMensaje, mtInformation, [mbOK], 0);
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
