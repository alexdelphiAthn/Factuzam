{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFacturarTicket                                      }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Crea una factura NORMAL en sustitución de un ticket (factura              }
{    simplificada): pide cliente, serie (por defecto la del almacén) y         }
{    fecha (por defecto la del ticket), copia cabecera y líneas, enlaza        }
{    con el ticket y la encola en Verifactu como F3.                           }
{******************************************************************************}
unit inMtoModalFacturarTicket;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox, cxCalendar, cxLabel,
  cxButtons, cxButtonEdit, dxCore, cxDateUtils,
  inMtoFrmBase, dxCoreGraphics, Vcl.ComCtrls, Vcl.Menus, Vcl.StdCtrls,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization;

type
  TFacturarTicketResult = record
    Aceptado:    Boolean;
    SerieNueva:  string;
    NumeroNueva: string;
  end;

  TfrmModalFacturarTicket = class(TfrmBase)
    lblTicket:   TcxLabel;
    edtTicket:   TcxTextEdit;
    lblCliente:  TcxLabel;
    btnCliente:  TcxButtonEdit;
    lblSerie:    TcxLabel;
    cbbSerie:    TcxLookupComboBox;
    lblFecha:    TcxLabel;
    dtFecha:     TcxDateEdit;
    pnlButton:   TPanel;
    btnGenerar:  TcxButton;
    btnCancelar: TcxButton;
    qrySeries:   TUniQuery;
    dsSeries:    TDataSource;
    procedure btnGenerarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnClientePropertiesButtonClick(Sender: TObject;
                                              AButtonIndex: Integer);
  private
    FResultado:    TFacturarTicketResult;
    FSerieTicket:  string;
    FNumeroTicket: string;
    FEmpresa:      string;
    FCliente:      string;
    // Búsqueda de cliente con el buscador genérico heredado de
    // inMtoGenSearch (mismo formulario que usa la caja), no un combo
    procedure BuscarCliente;
    procedure ValidarClienteFacturaNormal(const ACliente: string);
    procedure CrearFacturaNormal(const ASerie: string;
                                 const ACliente: string;
                                 AFecha: TDateTime);
  public
    class function Ejecutar(AOwner: TComponent;
                            const ASerieTicket, ANumeroTicket,
                            AEmpresa, AAlmacen: string;
                            AFechaTicket: TDateTime)
                            : TFacturarTicketResult;
  end;

implementation

uses
  inLibGlobalVar, inLibtb, inLibVerifactu, inLibVerifactuCola,
  inMtoGenSearch, inLibDocumentoFiscal;

{$R *.dfm}

class function TfrmModalFacturarTicket.Ejecutar(AOwner: TComponent;
                                                const ASerieTicket,
                                                ANumeroTicket,
                                                AEmpresa, AAlmacen: string;
                                                AFechaTicket: TDateTime)
                                                : TFacturarTicketResult;
var
  frm:    TfrmModalFacturarTicket;
  sSerie: string;
begin
  frm := TfrmModalFacturarTicket.Create(AOwner);
  try
    frm.FSerieTicket  := ASerieTicket;
    frm.FNumeroTicket := ANumeroTicket;
    frm.FEmpresa      := AEmpresa;
    frm.edtTicket.Text := ASerieTicket + '\' + ANumeroTicket;
    frm.qrySeries.Connection := inLibGlobalVar.oConn;
    frm.qrySeries.Open;
    // Serie por defecto: la ligada al almacén del ticket; si no tiene,
    // la primera serie FC activa (DEFAULT_CON primero)
    sSerie := ObtenerSeriePropiaAlmacen(AEmpresa, 'FC', AAlmacen);
    if sSerie = '' then
      sSerie := frm.qrySeries.FieldByName('SERIE_CON').AsString;
    frm.cbbSerie.EditValue := sSerie;
    // Fecha por defecto: la del ticket
    if AFechaTicket > 0 then
      frm.dtFecha.Date := Trunc(AFechaTicket)
    else
      frm.dtFecha.Date := Trunc(Now);
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalFacturarTicket.btnCancelarClick(Sender: TObject);
begin
  FResultado.Aceptado := False;
  Close;
end;

procedure TfrmModalFacturarTicket.btnClientePropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  BuscarCliente;
end;

procedure TfrmModalFacturarTicket.BuscarCliente;
var
  formulario:    TfrmMtoSearch;
  unqryClientes: TUniQuery;
begin
  // Mismo buscador genérico (y mismo nombre de form, para compartir
  // perfiles de columnas) que la búsqueda de clientes de la caja
  unqryClientes := TUniQuery.Create(nil);
  try
    unqryClientes.Connection := inLibGlobalVar.oConn;
    unqryClientes.SQL.Text :=
      'SELECT CODIGO_CLI_CLI as `Código`, ' +
      '       RAZON_SOCIAL_CLI as `Razón Social`, ' +
      '       NIF_CLI as `NIF Cliente`, ' +
      '       MOVIL_CLI as `Teléfono Cliente`, ' +
      '       POBLACION_CLI as `Población` ' +
      '  FROM fza_clientes ' +
      ' WHERE ESACTIVO_CLI = ' + QuotedStr('S') +
      ' ORDER BY RAZON_SOCIAL_CLI';
    formulario := TfrmMtoSearch.Create(nil);
    try
      formulario.Name := 'frmMtoCliSearch';
      formulario.Caption := 'Búsqueda de Clientes';
      formulario.dsTablaG.DataSet := unqryClientes;
      unqryClientes.Open;
      formulario.ProcesarPerfiles;
      formulario.ShowModal;
      if formulario.sFicha = 'S' then
      begin
        FCliente := unqryClientes.FieldByName('Código').AsString;
        btnCliente.Text := FCliente + ' - ' +
          unqryClientes.FieldByName('Razón Social').AsString;
      end;
    finally
      FreeAndNil(formulario);
    end;
  finally
    FreeAndNil(unqryClientes);
  end;
end;

procedure TfrmModalFacturarTicket.btnGenerarClick(Sender: TObject);
var
  sCliente: string;
  sSerie:   string;
begin
  sCliente := FCliente;
  sSerie   := VarToStr(cbbSerie.EditValue);
  if Trim(sCliente) = '' then
    ShowMessage('Seleccione el cliente del borrador.')
  else if Trim(sSerie) = '' then
    ShowMessage('Seleccione la serie del borrador.')
  else if dtFecha.Date <= 0 then
    ShowMessage('Indique la fecha del borrador.')
  else
  begin
    ValidarClienteFacturaNormal(sCliente);
    CrearFacturaNormal(sSerie, sCliente, dtFecha.Date);
    FResultado.Aceptado := True;
    Close;
  end;
end;

procedure TfrmModalFacturarTicket.ValidarClienteFacturaNormal(
  const ACliente: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := inLibGlobalVar.oConn;
    Qry.SQL.Text :=
      ' SELECT RAZON_SOCIAL_CLI, NIF_CLI, CODIGO_PAI_CLI, NOMBRE_PAI_CLI ' +
      ' FROM fza_clientes ' +
      ' WHERE CODIGO_CLI_CLI = :CLIENTE ';
    Qry.ParamByName('CLIENTE').AsString := ACliente;
    Qry.Open;
    if Qry.IsEmpty then
      raise Exception.Create('El cliente seleccionado no existe.');
    if Trim(Qry.FieldByName('RAZON_SOCIAL_CLI').AsString) = '' then
      raise Exception.Create('La F3 necesita la razon social del cliente.');
    if PaisEsEspana(Qry.FieldByName('CODIGO_PAI_CLI').AsString,
                    Qry.FieldByName('NOMBRE_PAI_CLI').AsString) and
       (not DocumentoFiscalValido(Qry.FieldByName('NIF_CLI').AsString)) then
      raise Exception.Create('El NIF/CIF/NIE del cliente no es valido: ' +
        MensajeDocumentoFiscalInvalido(Qry.FieldByName('NIF_CLI').AsString));
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TfrmModalFacturarTicket.CrearFacturaNormal(const ASerie: string;
                                                     const ACliente: string;
                                                     AFecha: TDateTime);
var
  Qry:     TUniQuery;
  Usp:     TUniStoredProc;
  sNumero: string;
begin
  inLibGlobalVar.oConn.StartTransaction;
  Usp := TUniStoredProc.Create(nil);
  Qry := TUniQuery.Create(nil);
  try
    try
      Usp.Connection     := inLibGlobalVar.oConn;
      Usp.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      Usp.Prepare;
      Usp.ParamByName('pserie').AsString            := ASerie;
      Usp.ParamByName('pTipoDoc').AsString          := 'FC';
      Usp.ParamByName('pEMPRESA_CONTADOR').AsString := FEmpresa;
      Usp.ParamByName('pUSUARIOMODIF').AsString     := oUser;
      Usp.Execute;
      sNumero := Usp.ParamByName('pcont').AsString;
      Qry.Connection := inLibGlobalVar.oConn;
      // Cabecera: empresa, configuración fiscal y totales del ticket;
      // identidad del cliente desde su ficha; enlace al ticket en las
      // columnas ABONO (de ahí sale el F3 con FacturasSustituidas)
      Qry.SQL.Text :=
        ' INSERT INTO fza_facturas ' +
        ' (NUMERO_FAC, SERIE_FAC, FECHA_FAC, TIPO_FAC, FASE_FAC, ' +
        '  ESCONSOLIDADA_FAC, CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, ' +
        '  NIF_EMPRESA_FAC, MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, ' +
        '  DIRECCION1_EMPRESA_FAC, DIRECCION2_EMPRESA_FAC, ' +
        '  POBLACION_EMPRESA_FAC, PROVINCIA_EMPRESA_FAC, ' +
        '  NOMBRE_PAI_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
        '  CODIGO_POSTAL_EMPRESA_FAC, ESRETENCIONES_EMPRESA_FAC, ' +
        '  GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
        '  ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, ' +
        '  CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, ' +
        '  MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC, ' +
        '  DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC, ' +
        '  POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC, ' +
        '  CODIGO_POSTAL_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
        '  CODIGO_PAI_CLIENTE_FAC, CODIGO_OFICINA_CONTABLE_FAC, ' +
        '  CODIGO_ORGANO_GESTOR_FAC, CODIGO_UNIDAD_TRAMITADORA_FAC, ' +
        '  ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC, ' +
        '  ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
        '  ESRETENCIONES_CLIENTE_FAC, TARIFA_ARTICULO_CLIENTE_FAC, ' +
        '  ESIMP_INCL_TARIFA_CLIENTE_FAC, ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
        '  ESIRPF_IMP_INCL_ZONA_IVA_FAC, ESAPLICA_RE_ZONA_IVA_FAC, ' +
        '  ESIVAAGRICOLA_ZONA_IVA_FAC, PALABRA_REPORTS_ZONA_IVA_FAC, ' +
        '  CODIGO_IVA_FAC, ESVENTA_ACTIVO_FIJO_FAC, ' +
        '  PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, PORCENTAJE_REN_FAC, ' +
        '  TOTAL_REN_FAC, TOTAL_BASEI_IVAN_FAC, ' +
        '  PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
        '  TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC, ' +
        '  PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, PORCENTAJE_RES_FAC, ' +
        '  TOTAL_RES_FAC, TOTAL_BASEI_IVAS_FAC, ' +
        '  PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, PORCENTAJE_REE_FAC, ' +
        '  TOTAL_REE_FAC, TOTAL_BASEI_IVAE_FAC, ' +
        '  TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, FORMA_PAGO_FAC, ' +
        '  PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC, ' +
        '  TOTAL_LIQUIDO_FAC, ' +
        '  TEXTO_LEGAL_CLIENTE_FAC, TEXTO_LEGAL_EMPRESA_FAC, ' +
        '  COMENTARIOS_FAC, CONTADOR_LINEAS_FAC, ESCREARARTICULOS_FAC, ' +
        '  ESDESCRIPCIONES_AMP_FAC, ESFECHADEENTREGA_FAC, ' +
        '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        ' SELECT :NUMERO, :SERIE, :FECHA, ''NORMAL'', ''BORRADOR'', ' +
        '        ''N'', t.CODIGO_EMP_FAC, t.RAZON_SOCIAL_EMPRESA_FAC, ' +
        '        t.NIF_EMPRESA_FAC, t.MOVIL_EMPRESA_FAC, ' +
        '        t.EMAIL_EMPRESA_FAC, ' +
        '        t.DIRECCION1_EMPRESA_FAC, t.DIRECCION2_EMPRESA_FAC, ' +
        '        t.POBLACION_EMPRESA_FAC, t.PROVINCIA_EMPRESA_FAC, ' +
        '        t.NOMBRE_PAI_EMPRESA_FAC, t.CODIGO_PAI_EMPRESA_FAC, ' +
        '        t.CODIGO_POSTAL_EMPRESA_FAC, ' +
        '        t.ESRETENCIONES_EMPRESA_FAC, ' +
        '        t.GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
        '        t.ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, ' +
        '        c.CODIGO_CLI_CLI, c.RAZON_SOCIAL_CLI, c.NIF_CLI, ' +
        '        c.MOVIL_CLI, c.EMAIL_CLI, ' +
        '        c.DIRECCION1_CLI, c.DIRECCION2_CLI, ' +
        '        c.POBLACION_CLI, c.PROVINCIA_CLI, ' +
        '        c.CODIGO_POSTAL_CLI, c.NOMBRE_PAI_CLI, ' +
        '        c.CODIGO_PAI_CLI, c.CODIGO_OFICINA_CONTABLE_CLI, ' +
        '        c.CODIGO_ORGANO_GESTOR_CLI, ' +
        '        c.CODIGO_UNIDAD_TRAMITADORA_CLI, ' +
        '        t.ESIVA_RECARGO_CLIENTE_FAC, t.ESIVA_EXENTO_CLIENTE_FAC, ' +
        '        t.ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
        '        t.ESRETENCIONES_CLIENTE_FAC, ' +
        '        t.TARIFA_ARTICULO_CLIENTE_FAC, ' +
        '        t.ESIMP_INCL_TARIFA_CLIENTE_FAC, ' +
        '        t.ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
        '        t.ESIRPF_IMP_INCL_ZONA_IVA_FAC, ' +
        '        t.ESAPLICA_RE_ZONA_IVA_FAC, ' +
        '        t.ESIVAAGRICOLA_ZONA_IVA_FAC, ' +
        '        t.PALABRA_REPORTS_ZONA_IVA_FAC, ' +
        '        t.CODIGO_IVA_FAC, t.ESVENTA_ACTIVO_FIJO_FAC, ' +
        '        t.PORCENTAJE_IVAN_FAC, t.TOTAL_IVAN_FAC, ' +
        '        t.PORCENTAJE_REN_FAC, t.TOTAL_REN_FAC, ' +
        '        t.TOTAL_BASEI_IVAN_FAC, ' +
        '        t.PORCENTAJE_IVAR_FAC, t.TOTAL_IVAR_FAC, ' +
        '        t.PORCENTAJE_RER_FAC, t.TOTAL_RER_FAC, ' +
        '        t.TOTAL_BASEI_IVAR_FAC, ' +
        '        t.PORCENTAJE_IVAS_FAC, t.TOTAL_IVAS_FAC, ' +
        '        t.PORCENTAJE_RES_FAC, t.TOTAL_RES_FAC, ' +
        '        t.TOTAL_BASEI_IVAS_FAC, ' +
        '        t.PORCENTAJE_IVAE_FAC, t.TOTAL_IVAE_FAC, ' +
        '        t.PORCENTAJE_REE_FAC, t.TOTAL_REE_FAC, ' +
        '        t.TOTAL_BASEI_IVAE_FAC, ' +
        '        t.TOTAL_BASES_FAC, t.TOTAL_IMPUESTOS_FAC, ' +
        '        t.FORMA_PAGO_FAC, t.PORCENTAJE_RETENCION_FAC, ' +
        '        t.TOTAL_RETENCION_FAC, ' +
        '        t.TOTAL_LIQUIDO_FAC, ' +
        '        t.TEXTO_LEGAL_CLIENTE_FAC, t.TEXTO_LEGAL_EMPRESA_FAC, ' +
        '        TRIM(CONCAT(IFNULL(t.COMENTARIOS_FAC, ''''), ' +
        '                    :COMENTARIO)), ' +
        '        t.CONTADOR_LINEAS_FAC, ' +
        '        t.ESCREARARTICULOS_FAC, t.ESDESCRIPCIONES_AMP_FAC, ' +
        '        t.ESFECHADEENTREGA_FAC, ' +
        '        NOW(), NOW(), :USUARIO, :USUARIO ' +
        ' FROM fza_facturas t ' +
        ' JOIN fza_clientes c ' +
        '   ON c.CODIGO_CLI_CLI = :CLIENTE ' +
        ' WHERE t.SERIE_FAC  = :STICKET ' +
        '   AND t.NUMERO_FAC = :NTICKET';
      Qry.ParamByName('NUMERO').AsString  := sNumero;
      Qry.ParamByName('SERIE').AsString   := ASerie;
      Qry.ParamByName('FECHA').AsDate     := AFecha;
      Qry.ParamByName('USUARIO').AsString := oUser;
      Qry.ParamByName('CLIENTE').AsString := ACliente;
      Qry.ParamByName('STICKET').AsString := FSerieTicket;
      Qry.ParamByName('NTICKET').AsString := FNumeroTicket;
      Qry.ParamByName('COMENTARIO').AsString :=
        ' ESTA FACTURA SE EMITE EN SUSTITUCIÓN DE LA FACTURA ' +
        'SIMPLIFICADA ' + FSerieTicket + '\' + FNumeroTicket;
      Qry.Execute;
      if Qry.RowsAffected = 0 then
        raise Exception.Create('No se pudo crear el borrador: ticket o ' +
                               'cliente no encontrados.');
      // Líneas: copia tal cual del ticket (importes en positivo)
      Qry.SQL.Text :=
        ' INSERT INTO fza_facturas_lineas ' +
        ' (NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN, ' +
        '  CODIGO_ART_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
        '  ESIMP_INCL_TARIFA_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
        '  DESCRIPCION_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
        '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
        '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
        '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        ' SELECT :NUMERO, :SERIE, LINEA_FACLIN, ' +
        '        CODIGO_ART_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
        '        ESIMP_INCL_TARIFA_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
        '        DESCRIPCION_ARTICULO_FACLIN, CANTIDAD_FACLIN, ' +
        '        PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
        '        PORCENTAJE_IVA_FACLIN, ' +
        '        PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
        '        NOW(), NOW(), :USUARIO, :USUARIO ' +
        ' FROM fza_facturas_lineas ' +
        ' WHERE SERIE_FAC_FACLIN  = :STICKET ' +
        '   AND NUMERO_FAC_FACLIN = :NTICKET';
      Qry.ParamByName('NUMERO').AsString  := sNumero;
      Qry.ParamByName('SERIE').AsString   := ASerie;
      Qry.ParamByName('USUARIO').AsString := oUser;
      Qry.ParamByName('STICKET').AsString := FSerieTicket;
      Qry.ParamByName('NTICKET').AsString := FNumeroTicket;
      Qry.Execute;
      // El ticket sustituido apunta a la factura nueva en sus columnas
      // ABONO (mismo convenio que las rectificativas: el documento
      // antecesor enlaza a su sucesor)
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET SERIE_FAC_ABONO_FAC  = :SERIE, ' +
        '     NUMERO_FAC_ABONO_FAC = :NUMERO, ' +
        '     INSTANTE_MODIF = NOW(), ' +
        '     USUARIO_MODIF  = :USUARIO ' +
        ' WHERE SERIE_FAC  = :STICKET ' +
        '   AND NUMERO_FAC = :NTICKET';
      Qry.ParamByName('SERIE').AsString   := ASerie;
      Qry.ParamByName('NUMERO').AsString  := sNumero;
      Qry.ParamByName('USUARIO').AsString := oUser;
      Qry.ParamByName('STICKET').AsString := FSerieTicket;
      Qry.ParamByName('NTICKET').AsString := FNumeroTicket;
      Qry.Execute;
      // Recalcular netos de la factura nueva
      Qry.SQL.Text := 'CALL PRC_CALCULAR_FACTURA_NETOS(:SERIE, :NUMERO)';
      Qry.ParamByName('SERIE').AsString  := ASerie;
      Qry.ParamByName('NUMERO').AsString := sNumero;
      Qry.Execute;
      ValidarRequisitosFiscalesEmision(inLibGlobalVar.oConn,
        ASerie, sNumero);
      // Histórico N:1 de relaciones (la F3 sustituye al ticket)
      TVerifactuCola.RegistrarRelacionFactura(
        inLibGlobalVar.oConn, ASerie, sNumero,
        FSerieTicket, FNumeroTicket, 'SUSTITUYE');
      inLibGlobalVar.oConn.Commit;
    except
      on E: Exception do
      begin
        inLibGlobalVar.oConn.Rollback;
        raise;
      end;
    end;
    // Encolar el alta en Verifactu (saldrá como F3 con el bloque
    // FacturasSustituidas apuntando al ticket)
    case ModoVerifactu of
      mvVerifactu:
        begin
          TVerifactuCola.EncolarFactura(Qry, ASerie, sNumero);
          RegistrarEventoVerifactu(inLibGlobalVar.oConn,
            cEventoVerifactuEncolado,
            'Borrador en sustitución del ticket ' + FSerieTicket + '\' +
            FNumeroTicket + ' encolada', '', ASerie, sNumero);
        end;
      mvNoVerifactu:
        TVerifactuCola.RegistrarFacturaNoVerifactu(Qry, ASerie, sNumero);
    else
      TVerifactuCola.MarcarFacturaSinVerifactu(Qry, ASerie, sNumero);
    end;
  finally
    FreeAndNil(Qry);
    FreeAndNil(Usp);
  end;
  FResultado.SerieNueva  := ASerie;
  FResultado.NumeroNueva := sNumero;
end;

end.
