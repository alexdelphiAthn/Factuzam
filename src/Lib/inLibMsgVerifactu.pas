{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgVerifactu                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de emisión fiscal, firma y comunicaciones Verifactu.             }
{******************************************************************************}
unit inLibMsgVerifactu;

interface

resourcestring
  SErrorRespuestaNtpNoValida =
    'sin respuesta NTP valida';
  SInfoRelojFiscalCorrecto =
    'Reloj fiscal correcto. Servidor=%s, diferencia=%d s.';
  SErrorRelojSistemaFueraMargenLegal =
    'Reloj del sistema fuera de margen legal. Servidor=%s, ' +
    'diferencia=%d s, margen=%d s.';
  SErrorComprobarRelojFiscalNtp =
    'No se pudo comprobar el reloj fiscal contra NTP.';
  SErrorExportarNoVerifactuSinCertificado =
    'No se puede exportar NO VERI*FACTU legal: el modo NO VERI*FACTU ' +
    'exige firma electrónica con certificado oficial.';
  SErrorExportarNoVerifactuSinColumnasEventos =
    'No se puede exportar NO VERI*FACTU legal: faltan columnas de firma ' +
    'en fza_verifactu_eventos.';
  SErrorExportarNoVerifactuSinColumnasFacturacion =
    'No se puede exportar NO VERI*FACTU legal: faltan columnas de firma ' +
    'en fza_facturas_consolidaciones.';
  SErrorExportarNoVerifactuRegistrosSinFirma =
    'No se puede exportar NO VERI*FACTU legal: %d evento(s) y %d ' +
    'registro(s) de facturación no tienen firma XAdES y datos de ' +
    'certificado.';
  SErrorConexionExportarNoVerifactu =
    'No hay conexion para exportar NO VERI*FACTU.';
  SErrorArchivoBaseExportacionNoIndicado =
    'No se ha indicado archivo base de exportacion.';
  STextoTipoError = 'ERROR';
  STextoTipoAviso = 'AVISO';
  SFormatoDetalleVerificacion = '%s: %s';
  SErrorModoExportacionNoCoincide =
    '%s: ModoVerifactu no coincide con el otro fichero.';
  SErrorXmlFirmadoNoLegible =
    '%s: el XML firmado no se puede leer.';
  SErrorFirmaEventoRaizIncorrecta =
    '%s: la firma de evento debe envolver RegistroEvento.';
  SErrorEventoFirmadoNoEncontrado =
    '%s: falta el nodo Evento firmado.';
  SErrorFirmaXadesNodoAeatIncorrecto =
    '%s: la firma XAdES no esta en el nodo exigido por AEAT.';
  SErrorFirmaXadesSinCertificado =
    '%s: falta certificado X509 en KeyInfo.';
  SErrorFirmaXadesSinSignedInfo =
    '%s: falta SignedInfo.';
  SErrorCanonicalizacionFirmaAeat =
    '%s: CanonicalizationMethod no coincide con AEAT.';
  SErrorMetodoFirmaNoRsaSha256 =
    '%s: SignatureMethod debe ser RSA-SHA256.';
  SErrorReferenciasSignedInfo =
    '%s: SignedInfo debe tener referencia al documento y a ' +
    'SignedProperties.';
  SErrorReferenciaDocumentoFirmado =
    '%s: falta Reference URI vacio al registro firmado.';
  SErrorTransformacionFirmaEnveloped =
    '%s: falta transform enveloped-signature.';
  SErrorDigestRegistroNoSha256 =
    '%s: digest del registro debe ser SHA-256.';
  SErrorReferenciaSignedProperties =
    '%s: falta Reference a SignedProperties.';
  SErrorCanonicalizacionSignedProperties =
    '%s: SignedProperties no usa canonicalizacion AEAT.';
  SErrorDigestSignedPropertiesNoSha256 =
    '%s: digest de SignedProperties debe ser SHA-256.';
  SErrorQualifyingPropertiesXades =
    '%s: falta QualifyingProperties XAdES.';
  SErrorSignedPropertiesXades =
    '%s: falta SignedProperties XAdES.';
  SErrorSigningCertificateXades =
    '%s: falta SigningCertificate.';
  SErrorPoliticaFirmaAge =
    '%s: falta politica de firma AGE.';
  SErrorIdentificadorPoliticaAge =
    '%s: identificador de politica AGE incorrecto.';
  SErrorDigestPoliticaAgeNoSha1 =
    '%s: digest de politica AGE debe ser SHA-1.';
  SErrorDigestValuePoliticaAge =
    '%s: DigestValue de politica AGE incorrecto.';
  SErrorUrlPoliticaAge =
    '%s: URL de politica AGE incorrecta.';
  SFormatoEtiquetaEvento = 'Evento %s';
  SErrorEventoHashPropioNoSha256 =
    'Evento %s: HashPropio no es SHA-256 hexadecimal.';
  SAvisoEventoPrimerHashAnteriorNoCero =
    'Evento %s: primer HashAnterior no es cero.';
  SErrorEventoHashAnteriorNoCoincide =
    'Evento %s: HashAnterior no coincide con el evento anterior.';
  SErrorEventoSinRegistroXmlFirmado =
    'Evento %s: falta RegistroXmlFirmado.';
  SErrorEventoHuellaNoCoincide =
    'Evento %s: HuellaEvento no coincide con HashPropio.';
  SErrorEventoFirmaGuardadaSinFirmaXml =
    'Evento %s: hay FirmaXades pero el XML no contiene firma.';
  SErrorEventoSinFirmaXades =
    'Evento %s: falta FirmaXades legal.';
  SErrorEventoSignatureValueNoCoincide =
    'Evento %s: SignatureValue no coincide con FirmaXades.';
  SErrorEventoFirmaDigitalNoCoincide =
    'Evento %s: FirmaDigital no coincide con FirmaXades.';
  SErrorFacturaSinFirmaDigitalXades =
    'Factura %s: falta FirmaDigitalXades legal.';
  STextoEventos = 'Eventos';
  SErrorFicheroEventosNoExiste =
    'No existe el fichero de eventos: %s';
  SErrorFicheroEventosRaizIncorrecta =
    'El fichero de eventos no tiene la raiz esperada.';
  SErrorFicheroEventosVacio =
    'El fichero de eventos no contiene eventos.';
  SErrorVerificarEventos =
    'No se pudo verificar eventos: %s';
  SInfoVerificacionCorrecta = 'Verificacion correcta.';
  SFormatoModoActual = '%s (modo actual)';
  SResumenVerificacionNoVerifactu =
    'Modo: %s' + sLineBreak +
    'Eventos: %d' + sLineBreak +
    'Registros de facturacion: %d' + sLineBreak +
    'Errores: %d' + sLineBreak +
    'Avisos: %d';
  SErrorAbrirProveedorCriptografico =
    'No se pudo abrir el proveedor criptografico.';
  SErrorCrearHashCriptografico =
    'No se pudo crear el hash criptografico.';
  SErrorCalcularHash = 'No se pudo calcular el hash.';
  SErrorObtenerTamanoHash =
    'No se pudo obtener el tamano del hash.';
  SErrorObtenerValorHash =
    'No se pudo obtener el valor del hash.';
  SErrorOperacionCriptografica =
    '%s. Codigo: %s. %s';
  SErrorProveedorCertificadoSinSha256 =
    'El proveedor criptografico del certificado no admite SHA-256 para ' +
    'firma RSA. No se puede generar XAdES rsa-sha256 con ese certificado ' +
    'tal como esta instalado. Reinstala o importa el certificado con un ' +
    'proveedor compatible con SHA-256, como Microsoft Enhanced RSA and ' +
    'AES Cryptographic Provider o Microsoft Software Key Storage ' +
    'Provider. %s';
  STextoCertificadoTodaviaNoValido =
    'todavia no es valido';
  STextoCertificadoCaducado = 'esta caducado';
  SErrorCertificadoNoVigente =
    'El certificado configurado %s. Vigencia: %s - %s. Seleccione un ' +
    'certificado vigente en la ficha de empresa.';
  SErrorCertificadoVigenteNoEncontrado =
    'No se encontro en el almacen personal de Windows un certificado ' +
    'vigente que coincida con el numero de serie o titular configurado.';
  SErrorCertificadoEmpresaNoConfigurado =
    'No hay un certificado configurado en la ficha de la empresa.';
  SErrorCrearHashSha256Firma =
    'No se pudo crear el hash SHA-256 para firmar';
  SErrorCargarDatosFirma =
    'No se pudieron cargar los datos a firmar';
  SErrorCalcularTamanoFirmaSha256 =
    'No se pudo calcular el tamano de la firma SHA-256';
  SErrorFirmarSha256 = 'No se pudo firmar con SHA-256';
  SErrorCalcularTamanoFirmaNCrypt =
    'NCryptSignHash fallo al calcular el tamano de la firma. Codigo: %d';
  SErrorFirmaNCrypt =
    'NCryptSignHash fallo al firmar. Codigo: %d';
  SErrorAbrirClavePrivadaCertificado =
    'No se pudo abrir la clave privada del certificado';
  SErrorXmlMalFormadoCanonicalizar =
    'XML mal formado al canonicalizar.';
  SErrorElementoRaizXmlNoEncontrado =
    'No se encontro el elemento raiz del XML.';
  SErrorNombreNodoRaizNoDeterminado =
    'No se pudo determinar el nombre del nodo raiz.';
  SErrorCierreAperturaRaizNoEncontrado =
    'No se encontro el cierre de la apertura raiz.';
  SErrorCierreNodoRaizNoEncontrado =
    'No se encontro el cierre del nodo raiz %s.';
  SErrorCierreNodoNoEncontrado =
    'No se encontro el cierre del nodo %s.';
  SErrorNifProductorEventoVerifactuInvalido =
    'Parámetro appVerifactuSifNif vacío o no válido: "%s".';
  SErrorEmpresaEventosVerifactuNoConfigurada =
    'No hay empresa configurada para registrar eventos Verifactu.';
  SErrorNifEmisorEventoNoVerifactuInvalido =
    'NIF de la empresa emisora vacío o no válido para firmar eventos ' +
    'NO VERI*FACTU: "%s".';
  SErrorEmpresaSinNifEmisionFiscal =
    'La empresa %s no tiene un NIF válido para la emisión fiscal.';
  SErrorNifProductorVerifactuInvalido =
    'El parámetro appVerifactuSifNif no contiene un NIF de productor ' +
    'válido.';
  SErrorCertificadoFiscalEmpresaNoUtilizable =
    'La empresa %s no dispone de un certificado fiscal utilizable: %s';
  SErrorFirmaCertificadoNoVerifactuDesactivada =
    'El modo NO VERI*FACTU exige activar la firma con certificado en ' +
    'appVerifactuFirmaCertificado.';
  SErrorCertificadoEventosNoVerifactuNoConfigurado =
    'No hay certificado configurado en Empresas para firmar eventos ' +
    'NO VERI*FACTU.';
  SErrorFirmarEventoNoVerifactu =
    'No se pudo firmar el evento NO VERI*FACTU: %s';
  SErrorRelojEventoNoVerifactu =
    'No se pudo validar el reloj del evento NO VERI*FACTU: %s';
  STextoRegistroFacturacionNoVerifactu =
    'Registro de facturación NO VERI*FACTU';
  SErrorFirmaRegistroNoVerifactuObligatoria =
    'El modo NO VERI*FACTU exige firmar el registro de facturación con ' +
    'certificado oficial.';
  SErrorNifProductorSoftwareVerifactuInvalido =
    'Parámetro appVerifactuSifNif (NIF del productor del software) vacío ' +
    'o no válido: "%s". Rellenarlo en Parámetros de aplicación, categoría ' +
    'Verifactu.';
  SErrorNifEmisorVerifactuInvalido =
    'NIF de la empresa emisora vacío o no válido para Verifactu: "%s". ' +
    'Revisar la ficha de la empresa (NIF de 9 caracteres, sin guiones).';
  SErrorFacturaRegistroFiscalNoEncontrada =
    'Factura %s\%s no encontrada para el registro fiscal';
  SAvisoQrPngNoGenerado =
    '(QR PNG no generado: %s) ';
  SErrorFacturaEnvioVerifactuNoEncontrada =
    'Factura %s\%s no encontrada para el envío Verifactu';
  SErrorRespuestaServicioInesperada =
    'Respuesta inesperada del servicio';
  SErrorRespuestaHttpAeat = 'AEAT HTTP %d: %s';
  SErrorRespuestaRegistroAeat = 'AEAT [%s] %s';
  SErrorEstadoEnvioAeat = 'EstadoEnvio: %s';
  SErrorServicioInstalacionHttp =
    'El servicio respondió con HTTP %d.';
  SErrorReferenciaGlobalInstalacionFaltante =
    'Falta la referencia global de la instalación.';
  SErrorServicioJsonInvalido =
    'El servicio no devolvió JSON válido.';
  SErrorServicioSinNumeroInstalacion =
    'El servicio no devolvió NumeroInstalacion.';
  SErrorServicioSinDatosDeclaracion =
    'El servicio no devolvió los datos de la declaración responsable.';
  SErrorDeclaracionVersionNoSolicitada =
    'La declaración recibida no corresponde a la versión solicitada.';
  SErrorDeclaracionSifIncorrecto =
    'La declaración recibida no corresponde al SIF FZ.';
  SErrorDeclaracionDescargadaVacia =
    'La declaración descargada está vacía.';
  SErrorPaginaPublicaHttp =
    'La página pública respondió con HTTP %d.';
  SErrorDeclaracionPaginaPublicaOtraVersion =
    'La página pública corresponde a otra versión.';
  SErrorDeclaracionResponsableNoDisponible =
    'No hay una declaración responsable disponible para la versión %s. ' +
    'Webservice: %s. Caché: %s. Página pública: %s';
  SErrorEmpresaInstalacionSifNoConfigurada =
    'No hay empresa configurada para solicitar el número de instalación ' +
    'SIF.';
  SErrorEmpresaSinRazonSocial =
    'La empresa no tiene razón social.';
  SErrorNifEmpresaInstalacionInvalido =
    'El NIF de la empresa no es válido: "%s".';
  SErrorEmpresaSinNumeroInstalacionSif =
    'La empresa %s (%s) no tiene número de instalación SIF. Genéralo desde ' +
    'Archivo > Empresas.';
  SErrorNumeroInstalacionSifIncorrecto =
    'El número de instalación SIF de la empresa %s no corresponde al SIF ' +
    'FZ.';
  SErrorNumeroInstalacionSinVersion =
    'El número de instalación SIF de la empresa %s no tiene versión ' +
    'asociada. Genéralo de nuevo desde Archivo > Empresas.';
  SErrorVersionNumeroInstalacionIncorrecta =
    'El número de instalación SIF de la empresa %s fue generado para la ' +
    'versión %s y la versión actual es %s. Genéralo de nuevo desde ' +
    'Archivo > Empresas.';
  SInfoExportacionNoVerifactuGenerada =
    'Exportacion NO VERI*FACTU generada:' + sLineBreak +
    '%s' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Eventos: %d' + sLineBreak +
    'Registros de facturacion: %d' + sLineBreak +
    'Firmas: registros internos XAdES';
  SInfoVerificacionNoVerifactuCorrecta =
    'Verificacion NO VERI*FACTU correcta.' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Informe:' + sLineBreak + '%s';
  SErrorVerificacionNoVerifactu =
    'Verificacion NO VERI*FACTU con errores.' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Informe:' + sLineBreak + '%s';
  SInfoAnulacionVerifactuEncolada =
    'Anulación encolada: el hilo Verifactu la enviará en el próximo ciclo.';
  SInfoAnulacionNoVerifactuRegistrada =
    'Anulación registrada y firmada en NO VERI*FACTU.';
  SInfoAnulacionSinVerifactuRegistrada =
    'Anulación registrada en modo SIN VERIFACTU.';
  SInfoAccionFiscalEncolada =
    '%s encolada: el hilo Verifactu la enviará en el próximo ciclo. Puede ' +
    'seguirla en la columna "Cola Verifactu" y en Verifactu - Cola de ' +
    'Envíos.';
  SInfoAccionFiscalNoVerifactu =
    '%s registrada y firmada en NO VERI*FACTU.';
  SInfoAccionFiscalSinVerifactu =
    '%s registrada en modo SIN VERIFACTU.';
  SInfoBorradorVerifactuPendiente =
    'Borrador %s\%s en VERIFACTU_PENDIENTE: el QR ya puede imprimirse y ' +
    'el envío a la AEAT queda en la cola Verifactu.';
  SInfoBorradorNoVerifactuRegistrado =
    'Borrador %s\%s registrado y firmado en NO VERI*FACTU.';
  SInfoBorradorSinVerifactuEmitido =
    'Borrador %s\%s emitido en modo SIN VERIFACTU.';
  SErrorPrepararImpresionDeclaracionResponsable =
    'No se pudo preparar el documento de impresión.';
  SErrorImprimirDeclaracionResponsable =
    'No se pudo imprimir la declaración responsable:' + sLineBreak;
  SInfoNumeroInstalacionSifDisponible =
    'Número de instalación SIF disponible: ';
  SErrorGenerarNumeroInstalacionSif =
    'No se pudo generar el número de instalación SIF:' + sLineBreak;
implementation

end.
