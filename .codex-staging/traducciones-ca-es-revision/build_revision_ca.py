from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path

import pymysql


IDIOMA = "ca-ES"
USUARIO = "D27"
SEPARADOR = re.compile(r"\r\n|\r|\n")
MARCADOR = re.compile(
    r"%(?!%)(?:\d+:)?[-0-9.]*(?:[dDuUeEfFgGnNmMpPsSxX])"
)


@dataclass(frozen=True)
class Entrada:
    clave: str
    texto: str
    contexto: str


def conectar():
    return pymysql.connect(
        host=os.environ["FZH"],
        port=int(os.environ.get("FZPORT", "3306")),
        user=os.environ["FZU"],
        password=os.environ["FZP"],
        database=os.environ["FZD"],
        charset="utf8mb4",
    )


def cargar_catalogo() -> dict[str, tuple[str, str, str | None]]:
    conexion = conectar()
    try:
        with conexion.cursor() as cursor:
            cursor.execute(
                """
SELECT E.CLAVE_TRAD, E.TEXTO_TRAD, E.CONTEXTO_TRAD, C.TEXTO_TRAD
  FROM fza_traducciones E
  LEFT JOIN fza_traducciones C
    ON C.CLAVE_TRAD = E.CLAVE_TRAD
   AND C.IDIOMA_TRAD = 'ca-ES'
   AND C.ESACTIVO_TRAD = 'S'
 WHERE E.IDIOMA_TRAD = 'es-ES'
   AND E.ESACTIVO_TRAD = 'S'
 ORDER BY E.CLAVE_TRAD
"""
            )
            return {
                clave: (espanol, contexto, catalan)
                for clave, espanol, contexto, catalan in cursor.fetchall()
            }
    finally:
        conexion.close()


def recursos_recientes() -> dict[str, tuple[str, str]]:
    grupos = {
        "Vcl.Consts": (
            "src/vcl37/Vcl.Consts.pas",
            {
                "SVGIFImages": "Imatges GIF",
                "SVJPGImages": "Imatges JPEG",
                "SVPNGImages": "Imatges PNG",
            },
        ),
        "inLibMsgArticulos": (
            "src/Lib/inLibMsgArticulos.pas",
            {
                "SErrorAlmacenesVentasAddBlock":
                    "Seleccioneu almenys un magatzem de venda per aplicar "
                    "els filtres de vendes o d'estoc de destinació.",
            },
        ),
        "inLibMsgCaja": (
            "src/Lib/inLibMsgCaja.pas",
            {
                "SErrorCambioIvaSoloArticuloInmaterial":
                    "Seleccioneu una línia d'article immaterial per "
                    "canviar-ne l'IVA.",
                "SErrorRestanteArqueoCajaNoValido":
                    "Introduïu un recompte vàlid perquè l'import restant "
                    "sigui vàlid.",
                "SPreguntaImprimirJustificanteCierreCaja":
                    "Voleu imprimir el justificant de tancament?",
                "STituloJustificanteCierreCaja":
                    "Justificant de tancament",
            },
        ),
        "inLibMsgComun": (
            "src/Lib/inLibMsgComun.pas",
            {
                "SAvisoLogErrorIncompleto":
                    "Avís: no estan activades les tres traces del LOG "
                    "(SQL, rendiment i avançada). Podeu enviar l'error, "
                    "però diagnosticar-lo serà més costós.",
                "SCaptionActivarLogCompleto": "Activar el LOG complet",
                "SCaptionContrasenaCopiaError": "Contrasenya",
                "SCaptionDescripcionError":
                    "Què estàveu fent quan s'ha produït?",
                "SCaptionEmailContactoError":
                    "Correu electrònic de contacte:",
                "SCaptionEnviarCopiaSeguridadError":
                    "Enviar una còpia de seguretat protegida (ZIP)",
                "SCaptionEnviarDesarrollador":
                    "Enviar l'error al suport",
                "SCaptionRepetirContrasenaCopiaError":
                    "Repetiu la contrasenya",
                "SCaptionSalirAplicacion": "Sortir de l'aplicació",
                "SCaptionTelefonoContactoError":
                    "Telèfon de contacte:",
                "SErrorAlmacenSerieTokenizadaNoIndicado":
                    "Seleccioneu el magatzem de la sèrie tokenitzada.",
                "SErrorCajaSerieTokenizadaNoIndicada":
                    "Seleccioneu la caixa de la sèrie tokenitzada.",
                "SErrorContactoEnvioErrorNoValido":
                    "Indiqueu un correu electrònic vàlid i un telèfon de "
                    "contacte vàlid.",
                "SErrorContrasenaCopiaErrorVacia":
                    "La contrasenya de la còpia no pot estar buida.",
                "SErrorContrasenasCopiaErrorNoCoinciden":
                    "Les contrasenyes no coincideixen.",
                "SErrorNoSePudoEnviarError":
                    "No s'ha pogut enviar l'error al desenvolupador.",
                "SErrorPrepararCopiaSeguridadError":
                    "No s'ha pogut preparar la còpia de seguretat.\r\n%s",
                "SErrorRespuestaEnvioError":
                    "El servei d'errors ha respost amb HTTP %d.",
                "SErrorSerieTokenizadaCalendarioNoNatural":
                    "L'empresa ha de tenir marcada l'opció «Fer coincidir "
                    "el calendari natural amb els tokens» abans d'usar "
                    "una sèrie tokenitzada.",
                "SErrorSerieTokenizadaEmpresa":
                    "La sèrie tokenitzada %s ha de contenir yyyy, q, mm, "
                    "dd o una combinació d'aquests tokens, sense repetir-ne "
                    "cap. Exemples: A1.yyyy, yyyy.Tq.A1 i yyyy.mm.dd.",
                "SInfoContrasenaCopiaError":
                    "La còpia es xifrarà i es comprimirà. Deseu aquesta "
                    "contrasenya: l'haureu d'enviar per correu al "
                    "desenvolupador.",
                "SInfoCopiaSeguridadError":
                    "En enviar-la se sol·licitarà la contrasenya i es "
                    "crearà el ZIP. L'operació pot trigar uns quants "
                    "minuts.",
                "SInfoEnviarContrasenaCopiaError":
                    "La contrasenya no s'ha enviat ni emmagatzemat. "
                    "Envieu-la per correu a info@veryverifactu.com i "
                    "indiqueu aquesta referència: %s",
                "SInfoErrorEnviado":
                    "Error enviat correctament. Referència: %s",
                "SInfoEvidenciasCopiaError":
                    "S'hi adjuntaran el detall tècnic, la captura de "
                    "pantalla de Factuzam i una còpia de seguretat "
                    "protegida.",
                "SInfoEvidenciasError":
                    "S'hi adjuntaran el detall tècnic, la captura de "
                    "pantalla de Factuzam i el tram recent del LOG.",
                "SInfoLogActivadoRepetir":
                    "LOG complet activat per a aquesta sessió. Tanqueu "
                    "aquest avís i repetiu l'operació que ha produït "
                    "l'error.",
                "SInfoLogErrorCompleto":
                    "Les traces SQL, de rendiment i avançada estan "
                    "activades.",
                "SInfoPreparandoCopiaSeguridadError":
                    "S'està preparant la còpia de seguretat protegida...",
                "SInfoSeguimientoError":
                    "Podeu consultar la comunicació a: %s",
                "SPreguntaActivarLogCompleto":
                    "Voleu activar ara les traces SQL, de rendiment i "
                    "avançada? Després tanqueu aquest avís i repetiu "
                    "l'operació que ha produït l'error.",
                "STituloContrasenaCopiaError":
                    "Protegir la còpia de seguretat",
            },
        ),
        "inLibMsgConfiguracion": (
            "src/Lib/inLibMsgConfiguracion.pas",
            {
                "SErrorSeleccionIdiomaNoAplicado":
                    "No s'ha pogut aplicar l'idioma %s:\r\n%s",
            },
        ),
        "inLibMsgFacturas": (
            "src/Lib/inLibMsgFacturas.pas",
            {
                "SErrorLecturasFacturasNoRegistradas":
                    "No s'ha registrat el repositori de lectures de "
                    "factures.",
                "SErrorPersistenciaFacturasNoRegistrada":
                    "La persistència d'operacions de factures no està "
                    "registrada.",
                "SErrorRepositorioFacturaeNoRegistrado":
                    "No s'ha registrat el repositori de Facturae.",
            },
        ),
        "inLibMsgIntegraciones": (
            "src/Lib/inLibMsgIntegraciones.pas",
            {
                "SErrorConexionTraduccionNoDisponible":
                    "No està disponible la connexió per instal·lar la "
                    "traducció.",
                "SErrorDescargaTraduccion":
                    "No s'ha pogut baixar la traducció: %s",
                "SErrorPaqueteTraduccionInvalido":
                    "El paquet de traducció no és vàlid: %s",
                "SErrorTraduccionSinFilas":
                    "El paquet no ha instal·lat cap traducció per a %s.",
                "SErrorTraduccionTransaccionActiva":
                    "No es pot instal·lar la traducció mentre hi ha una "
                    "transacció activa.",
                "SErrorVentasWsColaNoRegistrada":
                    "La persistència de la cua de vendes no està "
                    "registrada.",
                "SProgresoTraduccionAplicando":
                    "S'està aplicant la traducció a la interfície...",
                "SProgresoTraduccionCompletada":
                    "Traducció baixada i aplicada correctament.",
                "SProgresoTraduccionComprobando":
                    "S'està comprovant el catàleg instal·lat...",
                "SProgresoTraduccionDescargando":
                    "S'està baixant el paquet de traducció...",
                "SProgresoTraduccionDisponible":
                    "La traducció ja està baixada i disponible.",
                "SProgresoTraduccionEjecutando":
                    "S'està executant %s (%d de %d)...",
                "SProgresoTraduccionPreparando":
                    "S'està preparant la baixada de %s...",
                "SProgresoTraduccionValidando":
                    "S'estan validant el manifest i les empremtes "
                    "SHA-256...",
            },
        ),
        "inLibMsgVentas": (
            "src/Lib/inLibMsgVentas.pas",
            {
                "SCaptionExcluirSkuDocumentoTrabajoAddBlock":
                    "Excloure els SKU que ja són al document",
                "SErrorActualizarEstadoDocumentoTrabajo":
                    "No s'ha pogut actualitzar l'estat del Document de "
                    "Treball. Actualitzeu la llista i torneu-ho a provar.",
                "SErrorActualizarEstadoDocumentoTrabajoSoloPropietario":
                    "Només el propietari pot canviar l'estat del Document "
                    "de Treball.",
                "SErrorArchivarDocumentoTrabajoNoPermitido":
                    "Només es poden arxivar documents propis en estat "
                    "CREADO o ENVIADO.",
                "SErrorContadorFacturaVentaDocumentoTrabajo":
                    "El comptador de factures de venda no ha retornat cap "
                    "número per a la sèrie %s.",
                "SErrorContadorPedidoCompraDocumentoTrabajo":
                    "El comptador de comandes de compra no ha retornat cap "
                    "número per a la sèrie %s.",
                "SErrorEmpresaDocumentoTrabajoNoExiste":
                    "No existeix l'empresa %s del Document de Treball.",
                "SErrorEnviarDocumentoTrabajoNoPermitido":
                    "Només es poden enviar documents en estat CREADO.",
                "SErrorEstadoDocumentoTrabajoNoValido":
                    "L'estat del Document de Treball ha de ser CREADO, "
                    "ENVIADO o ARCHIVADO.",
                "SErrorModificarDocumentoTrabajoNoPermitido":
                    "Només es poden modificar documents propis en estat "
                    "CREADO.",
                "SErrorVentasCalendarioNoRegistrado":
                    "El repositori del calendari de vendes no està "
                    "registrat.",
                "SInfoDocumentoTrabajoArchivado":
                    "Document de Treball arxivat.",
                "SInfoFacturaVentaDocumentoTrabajoCreada":
                    "Factura de venda %s/%s creada en BORRADOR amb %d "
                    "línies.\r\nAssigneu-hi client, tarifa, preus i "
                    "impostos abans de consolidar-la.",
                "SInfoPedidoCompraDocumentoTrabajoCreado":
                    "Comanda de compra %s/%s creada en ABIERTO amb %d "
                    "línies.\r\nAssigneu-hi proveïdor, preus i condicions "
                    "de compra.",
                "SPreguntaArchivarDocumentoTrabajo":
                    "Voleu arxivar el Document de Treball seleccionat?",
                "STituloEnviarFacturaVentaDocumentoTrabajo":
                    "Enviar a una factura de venda",
                "STituloEnviarPedidoCompraDocumentoTrabajo":
                    "Enviar a una comanda de compra",
            },
        ),
        "inLibMsgVerifactu": (
            "src/Lib/inLibMsgVerifactu.pas",
            {
                "SErrorIncidenciaClienteNoEncontrado":
                    "No existeix el client %s.",
                "SErrorIncidenciaClienteObligatorio":
                    "Seleccioneu el client correcte per emetre la "
                    "rectificativa R4.",
                "SErrorIncidenciaClienteSinNif":
                    "El client %s no té identificació fiscal.",
                "SErrorIncidenciaCrearRectificativa":
                    "No s'ha pogut crear la factura rectificativa R4.",
                "SErrorIncidenciaEncolarSubsanacion":
                    "No s'ha pogut posar en cua la subsanació. Comproveu "
                    "que el registre continuï acceptat amb errors i que no "
                    "hi hagi cap altra subsanació activa.",
                "SErrorIncidenciaEstadoCambio":
                    "La subsanació ja no parteix d'un registre acceptat "
                    "amb errors.",
                "SErrorIncidenciaFacturaNoSeleccionada":
                    "Seleccioneu una factura per resoldre la incidència "
                    "VERI*FACTU.",
                "SErrorIncidenciaFechaRectificativaObligatoria":
                    "Indiqueu la data de la factura rectificativa.",
                "SErrorIncidenciaMotivoObligatorio":
                    "Indiqueu el motiu de la correcció.",
                "SErrorIncidenciaNoAceptadaConErrores":
                    "Per aquesta via només es pot resoldre un registre "
                    "acceptat amb errors.",
                "SErrorIncidenciaRectificativaExistente":
                    "La factura %s\\%s ja té associada la rectificativa "
                    "%s\\%s.",
                "SErrorIncidenciaSerieRectificativaObligatoria":
                    "Indiqueu la sèrie de la factura rectificativa.",
                "SErrorIncidenciaSoloVentaMayor":
                    "La resolució guiada només està disponible per a "
                    "factures de venda a l'engròs.",
                "SErrorIncidenciaSubsanacionActiva":
                    "Ja hi ha una subsanació pendent, en procés o enviada.",
                "SErrorRepositorioExportacionNoVerifactuNoRegistrado":
                    "No s'ha registrat el repositori d'exportació NO "
                    "VERI*FACTU.",
                "SInfoIncidenciaRectificativaCreada":
                    "Rectificativa R4 %s\\%s creada i posada en cua.",
                "SInfoIncidenciaSubsanacionEncolada":
                    "Subsanació posada en cua. La factura original roman "
                    "inalterada.",
                "STextoIncidenciaCancelar": "Cancel·lar",
                "STextoIncidenciaCargarCliente": "Carregar client",
                "STextoIncidenciaClienteActual":
                    "Destinatari de la factura",
                "STextoIncidenciaClienteCorrecto":
                    "Destinatari correcte",
                "STextoIncidenciaDecision":
                    "Tractament de la incidència",
                "STextoIncidenciaErrorAeat":
                    "Incidència comunicada per l'AEAT",
                "STextoIncidenciaFactura": "Factura original",
                "STextoIncidenciaFechaRectificativa":
                    "Data de la rectificativa",
                "STextoIncidenciaMotivo": "Motiu de la correcció",
                "STextoIncidenciaRectificar":
                    "La dada incorrecta consta a la factura: emetre una "
                    "rectificativa R4",
                "STextoIncidenciaResolver": "Resoldre",
                "STextoIncidenciaSerieRectificativa":
                    "Sèrie de la rectificativa",
                "STextoIncidenciaSubsanar":
                    "La factura emesa és correcta: esmenar el registre "
                    "enviat",
                "STituloResolverIncidenciaVerifactu":
                    "Resoldre la incidència VERI*FACTU",
            },
        ),
    }
    resultat = {}
    for unitat, (context, textos) in grupos.items():
        for nom, text in textos.items():
            resultat[f"{unitat}.{nom}"] = (text, context)
    return resultat


def traducciones_nuevas() -> dict[str, Entrada]:
    datos = {
        "inLibMsgArticulos.SCaptionColCodigoBarras": (
            "Codi de barres", "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SCaptionColDescripcion": (
            "Descripció", "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SCaptionColRefProveedor": (
            "Ref. prov.", "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SCaptionColStock": (
            "Estoc", "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SErrorArticulosVariacionesNoRegistradas": (
            "No s'ha registrat la implementació de variacions d'articles.",
            "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SErrorLookupAtributosNoInyectado": (
            "No s'ha injectat el lookup d'atributs a la configuració.",
            "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SErrorPersistenciaFotosNoRegistrada": (
            "No s'ha registrat la persistència del subsistema de fotos.",
            "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SErrorPersistenciaTallasNoRegistrada": (
            "No s'ha registrat la persistència del mode de talles.",
            "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgArticulos.SErrorValidadorArticulosNoInyectado": (
            "No s'ha injectat el validador d'articles a la configuració.",
            "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgCaja.SAvisoDevolucionTicketOtraEmpresa": (
            "El tiquet és d'una altra empresa: la devolució es desarà "
            "com a devolució amb referència al tiquet d'origen, sense "
            "rectificativa fiscal.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SCaptionDevolucionTicketDe": (
            "  —  DEVOLUCIÓ de %s\\%s (Botiga %s)",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorDevolucionTicketOperacionEnCurso": (
            "Finalitzeu o cancel·leu l'operació en curs abans de carregar "
            "una devolució per tiquet.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorMotivoDevolucionCajaObligatorio": (
            "Indiqueu el motiu de la devolució.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorTicketDevolucionCajaDatosDocumento": (
            "Indiqueu la sèrie i el número del document.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorTicketDevolucionCajaDatosOperacion": (
            "Indiqueu l'empresa, el magatzem, la caixa i el número "
            "d'operació.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorTicketDevolucionCajaEsRectificativa": (
            "El document localitzat és una rectificativa. Localitzeu el "
            "tiquet de venda original.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorTicketDevolucionCajaNoEncontrado": (
            "No s'ha trobat cap tiquet amb aquestes dades.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorTicketDevolucionCajaSinSeleccion": (
            "Localitzeu primer un tiquet vàlid.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SErrorVentaOrigenCajaSinSeleccion": (
            "Seleccioneu una venda de la llista o cancel·leu.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SInfoTicketDevolucionCajaLocalizado": (
            "Tiquet %s\\%s — %s — Botiga %s — Total %s €",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCaja.SInfoVentasOrigenSkuCaja": (
            "Vendes dels darrers 12 mesos que contenen \"%s\". Trieu el "
            "tiquet d'origen o cancel·leu per fer la devolució sense "
            "origen.",
            "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgCompras.SErrorMovimientosAlbaranCompraNoRegistrados": (
            "La persistència dels moviments d'albarans de compra no està "
            "registrada.",
            "src/Lib/inLibMsgCompras.pas"),
        "inLibMsgCompras.SErrorMovimientosDevolucionCompraNoRegistrados": (
            "La persistència dels moviments de devolucions de compra no "
            "està registrada.",
            "src/Lib/inLibMsgCompras.pas"),
        "inLibMsgCompras.SErrorPedidosCompraNoRegistrados": (
            "La persistència de les comandes de compra no està registrada.",
            "src/Lib/inLibMsgCompras.pas"),
        "inLibMsgCompras.SErrorPersistenciaGridPivoteCompraNoRegistrada": (
            "No s'ha registrat la persistència del pivot de compra.",
            "src/Lib/inLibMsgCompras.pas"),
        "inLibMsgFacturas.SCaptionEfectosCobroPlural": (
            "efectes de cobrament", "src/Lib/inLibMsgFacturas.pas"),
        "inLibMsgFacturas.SCaptionRecibosPlural": (
            "rebuts", "src/Lib/inLibMsgFacturas.pas"),
        "inLibMsgIntegraciones.SErrorVentasWsJsonNoRegistrado": (
            "El serialitzador JSON de vendes no està registrat.",
            "src/Lib/inLibMsgIntegraciones.pas"),
        "inMtoDocumentosTrabajo.TfrmMtoDocumentosTrabajo."
        "miEnviarFacturaVentaDTR.Caption": (
            "Factura de venda (major)...",
            "src/Forms/inMtoDocumentosTrabajo.dfm"),
        "inMtoDocumentosTrabajo.TfrmMtoDocumentosTrabajo."
        "miEnviarPedidoCompraDTR.Caption": (
            "Comanda de compra...",
            "src/Forms/inMtoDocumentosTrabajo.dfm"),
        "inMtoDocumentosTrabajo.TfrmMtoDocumentosTrabajo."
        "miEnviarPeticionTraspasoDTR.Caption": (
            "Sol·licitud de traspàs...",
            "src/Forms/inMtoDocumentosTrabajo.dfm"),
        "inMtoDocumentosTrabajo.TfrmMtoDocumentosTrabajo."
        "miEnviarTraspasoCajaDTR.Caption": (
            "Traspàs de caixa...",
            "src/Forms/inMtoDocumentosTrabajo.dfm"),
        "inLibMsgArticulos.SCaptionSinArticulos": (
            "No hi ha articles", "src/Lib/inLibMsgArticulos.pas"),
        "inLibMsgCaja.SCaptionSinStock": (
            "Sense estoc", "src/Lib/inLibMsgCaja.pas"),
        "inLibMsgComun.SCaptionSinDatosMostrar": (
            "<No hi ha dades per mostrar>", "src/Lib/inLibMsgComun.pas"),
        "inLibMsgComun.SCaptionSinDatos": (
            "No hi ha dades", "src/Lib/inLibMsgComun.pas"),
        "inLibMsgVentas.SCaptionSinVentas": (
            "No hi ha vendes", "src/Lib/inLibMsgVentas.pas"),
    }
    datos.update(recursos_recientes())
    return {
        clave: Entrada(clave, texto, contexto)
        for clave, (texto, contexto) in datos.items()
    }


def correcciones_manuales() -> dict[str, str]:
    return {
        "inLibMsgArticulos.SCaptionDemasiadosArticulosFiltro":
            "Hi ha massa articles per carregar-los de cop (més de %d). "
            "Marqueu la temporada i/o el proveïdor per limitar la càrrega; "
            "premeu \"Calcular núm.\" per veure quants en quedarien. "
            "\"Acceptar\" carrega la selecció; \"Cancel·lar\" carrega el "
            "filtre per defecte.",
        "inLibMsgComun.SPreguntaRectificarBorrador":
            "Seleccioneu com voleu rectificar l'esborrany %s\\%s.\r\n"
            "Per diferències, carrega les quantitats en negatiu; la "
            "substitutiva les carrega en positiu.",
        "inLibMsgComun.SErrorCamposTablaExternaWizardNoSeleccionados":
            "4) Seleccioneu el camp (o els camps) de la taula externa que "
            "s'encreuen amb la taula mestra. Per seleccionar-ne diversos, "
            "useu Ctrl o Maj; l'ordre de selecció determina la "
            "correspondència amb els Master fields (k=1,2,...).",
        "inLibMsgComun.SHintNivelFamilia":
            "En agrupar per família: 0 = família de l'article; 1 = família "
            "arrel; 2, 3... nivells intermedis.",
        "inLibMsgCaja.SErrorImpresoraTicketsCajaNoConfigurada":
            "No hi ha cap impressora de tiquets configurada als paràmetres "
            "(vgerDefPrinter); no es pot obrir el calaix.",
        "DevExpress.dxSBAR_WANTTORESETUSAGEDATA":
            "Aquesta operació esborrarà l'historial de les ordres "
            "utilitzades en aquesta aplicació i restaurarà el conjunt "
            "d'ordres predeterminat dels menús i les barres. No es perdran "
            "les opcions personalitzades. Esteu segur que voleu continuar?",
        "DevExpress.cxSDataRowIndexError":
            "Índex de l'element de fila fora de rang",
        "DevExpress.cxSDataRecordIndexError":
            "Índex del registre fora de rang",
        "Vcl.Consts.SActionBarStyleMissing":
            "No hi ha cap unitat d'estil ActionBand a la clàusula uses.\r"
            "L'aplicació ha d'incloure XPStyleActnCtrls, "
            "StdStyleActnCtrls o una unitat d'estil ActionBand de tercers "
            "a la clàusula uses.",
        "DevExpress.cxNavigator_DeleteRecordQuestion":
            "Voleu suprimir aquest registre?",
        "DevExpress.cxNavigatorHint_GotoBookmark":
            "Tornar al marcador",
        "DevExpress.cxNavigatorHint_Post":
            "Desar l'edició",
        "DevExpress.cxNavigatorHint_Refresh":
            "Actualitzar dades",
        "DevExpress.cxNavigatorHint_SaveBookmark":
            "Desar el marcador",
        "DevExpress.cxSFilterControlDialogActionSaveCaption":
            "&Desar...",
        "DevExpress.cxSMenuItemCaptionSave":
            "Desar &com a...",
        "DevExpress.dxSBAR_CP_DEFAULTSTYLE":
            "Estil per defecte",
        "DevExpress.dxSBAR_HINTOPT1":
            "Mo&strar els consells emergents a les barres",
        "DevExpress.dxSBAR_PERSMENUSANDTOOLBARS":
            "Menús i barres personalitzats",
        "DevExpress.dxSBAR_RESETTOOLBAR":
            "&Restablir les barres",
        "DevExpress.dxSBAR_TOOLBARADD":
            "Afegir barra",
        "DevExpress.dxSBAR_TOOLBARNAME":
            "Nom de la &barra:",
        "DevExpress.dxSBAR_TOOLBARRENAME":
            "Reanomenar barra",
        "DevExpress.scxExitConfirmation":
            "Voleu desar els canvis?",
        "DevExpress.scxFirstButtonHint":
            "Primer recurs",
        "DevExpress.scxGridChartBarDiagramDisplayText":
            "Diagrama de barres",
        "DevExpress.scxGridDeletingSelectedConfirmationText":
            "Voleu suprimir tots els registres seleccionats?",
        "DevExpress.scxNextPageButtonHint":
            "Pàgina següent",
        "DevExpress.scxpmResourcesLayout":
            "Editor de recursos",
        "DevExpress.scxPrevButtonHint":
            "Recurs anterior",
        "DevExpress.scxResource":
            "Recurs",
        "DevExpress.scxResourceLayoutCaption":
            "Editor de recursos",
        "DevExpress.scxShowFewerResourcesButtonHint":
            "Mostrar menys recursos",
        "DevExpress.sRefresh":
            "Actualitzar la traducció",
        "DevExpress.sView":
            "Visualització",
        "DevExpress.cxSEditRichEditSelectAllCaption":
            "Seleccion&ar-ho tot",
        "DevExpress.scxGridDeletingFocusedConfirmationText":
            "Voleu suprimir el registre?",
        "DevExpress.scxpmEditSeries": "Editar sèries",
        "DevExpress.dxSBAR_OTHEROPTIONS": "Altres",
        "Vcl.Consts.SNameHotLight": "Llum calenta",
        "Vcl.Consts.SNameMenuBar": "Barra de menú",
        "Vcl.Consts.SNameScrollBar": "Barra de desplaçament",
        "Vcl.Consts.SResetActionToolBar":
            "Restablir la barra d'eines",
        "Vcl.Consts.SResetUsageData":
            "Voleu restablir totes les dades d'ús?",
        "Vcl.Consts.SRestoreDefaultSchedule":
            "Voleu restablir la planificació de prioritats "
            "predeterminada?",
        "inMtoFormasdePago.TfrmMtoFormasdePago."
        "cxGrdDBTabPrinN_PLAZOS_FORMAPAGO.Caption": "Nombre de terminis",
        "inMtoArticulos.TfrmMtoArticulos."
        "cxgrdbclmnProveedoresPRECIO_ULT_COMPRA.Caption":
            "Preu de l'última compra",
        "inMtoTarifas.TfrmMtoTarifas."
        "cxgrdbclmnArticulosPRECIO_ULT_COMPRA.Caption":
            "Preu de l'última compra",
        "inMtoTarifas.TfrmMtoTarifas."
        "cxgrdbclmnArticulosFECHA_VALIDEZ.Caption":
            "Data de l'última compra",
        "inMtoEmpresas.TfrmMtoEmpresas.lblUsuarioModif.Caption":
            "Usuari de l'última modificació",
        "inMtoGeneradorProcesos.TfrmMtoGeneradorProcesos."
        "cxlblUsuarioModif.Caption":
            "Usuari de l'última modificació",
    }


def reparar_devexpress(correcciones: dict[str, str]) -> None:
    for clave in (
        "DevExpress.dxSBAR_CP_DELETE",
        "DevExpress.dxSBAR_TDELETE",
        "DevExpress.scxDelete",
        "DevExpress.scxpmDelete",
    ):
        correcciones[clave] = "&Suprimir"
    periodos = {
        "DevExpress.cxSFilterOperatorLast7Days": "Darrers 7 dies",
        "DevExpress.cxSFilterOperatorLast14Days": "Darrers 14 dies",
        "DevExpress.cxSFilterOperatorLast30Days": "Darrers 30 dies",
        "DevExpress.cxSFilterOperatorNext7Days": "Propers 7 dies",
        "DevExpress.cxSFilterOperatorNext14Days": "Propers 14 dies",
        "DevExpress.cxSFilterOperatorNext30Days": "Propers 30 dies",
        "DevExpress.cxSFilterOperatorPast": "Passat",
        "DevExpress.cxSFilterOperatorFuture": "Futur",
    }
    correcciones.update(periodos)


def reparar_terminologia(
    catalogo: dict[str, tuple[str, str, str | None]],
    correcciones: dict[str, str],
) -> None:
    formas_grabar = (
        (r"\bGravar\b", "Desar"),
        (r"\bgravar\b", "desar"),
        (r"\bGraveu\b", "Deseu"),
        (r"\bgraveu\b", "deseu"),
        (r"\bGravades\b", "Desades"),
        (r"\bgravades\b", "desades"),
        (r"\bGravada\b", "Desada"),
        (r"\bgravada\b", "desada"),
        (r"\bGravats\b", "Desats"),
        (r"\bgravats\b", "desats"),
        (r"\bGravat\b", "Desat"),
        (r"\bgravat\b", "desat"),
        (r"\bGravant\b", "Desant"),
        (r"\bgravant\b", "desant"),
    )
    for clave, (espanol, _, catalan) in catalogo.items():
        if catalan is None or clave in correcciones:
            continue
        texto = catalan
        if re.search(r"\bgrab\w*", espanol, re.IGNORECASE):
            for patron, sustitucion in formas_grabar:
                texto = re.sub(patron, sustitucion, texto)
        if re.search(r"\bcomandos?\b", espanol, re.IGNORECASE):
            texto = re.sub(r"\bComandes\b", "Ordres", texto)
            texto = re.sub(r"\bcomandes\b", "ordres", texto)
            texto = re.sub(r"\bComanda\b", "Ordre", texto)
            texto = re.sub(r"\bcomanda\b", "ordre", texto)
        if texto != catalan:
            if SEPARADOR.findall(espanol) != SEPARADOR.findall(texto):
                texto = restaurar_saltos(espanol, texto)
            correcciones[clave] = texto


def reparar_fastreport(
    catalogo: dict[str, tuple[str, str, str | None]],
    correcciones: dict[str, str],
) -> None:
    for clave, (espanol, _, catalan) in catalogo.items():
        if not clave.startswith("FastReport.") or catalan != espanol:
            continue
        texto = catalan
        if texto == "Impreso el [Date]":
            texto = "Imprès el [Date]"
        elif texto.startswith("Fecha:"):
            texto = "Data:" + texto[len("Fecha:"):]
        elif texto.startswith("Albarán:"):
            texto = "Albarà:" + texto[len("Albarán:"):]
        elif texto.startswith("Devolución:"):
            texto = "Devolució:" + texto[len("Devolución:"):]
        elif texto.startswith("Forma de Pago:"):
            texto = "Forma de pagament:" + texto[len("Forma de Pago:"):]
        elif texto.startswith("Retención IRPF"):
            texto = "Retenció IRPF" + texto[len("Retención IRPF"):]
        elif texto.startswith("Desde fecha"):
            texto = "Des de la data" + texto[len("Desde fecha"):]
        elif texto.startswith("Hasta fecha"):
            texto = "Fins a la data" + texto[len("Hasta fecha"):]
        elif texto.startswith("TOT.FECHA"):
            texto = "TOT.DATA" + texto[len("TOT.FECHA"):]
        elif texto == "SON EU:":
            texto = "SÓN EU:"
        if texto != catalan:
            correcciones[clave] = texto


def posiciones_candidatas(texto: str) -> list[int]:
    resultado = {0, len(texto)}
    for posicion in range(1, len(texto)):
        anterior = texto[posicion - 1]
        siguiente = texto[posicion]
        if anterior.isspace() or siguiente.isspace():
            resultado.add(posicion)
        if anterior in ".?!:;":
            resultado.add(posicion)
        if siguiente in "-·[%":
            resultado.add(posicion)
    return sorted(resultado)


def elegir_corte(
    texto: str,
    candidatos: list[int],
    ideal: float,
    minimo: int,
    fin_origen: str,
    inicio_siguiente: str,
) -> int:
    mejor = minimo
    mejor_puntuacion = float("inf")
    fin_origen = fin_origen.rstrip()
    inicio_siguiente = inicio_siguiente.lstrip()
    for posicion in candidatos:
        if posicion <= minimo or posicion >= len(texto):
            continue
        puntuacion = abs(posicion - ideal)
        anterior = texto[posicion - 1] if posicion > 0 else ""
        siguiente = texto[posicion] if posicion < len(texto) else ""
        if fin_origen.endswith(tuple(".?!:;")):
            if anterior == fin_origen[-1]:
                puntuacion -= 45
            elif anterior in ".?!:;":
                puntuacion -= 25
        elif anterior in ".?!:;":
            puntuacion += 18
        if inicio_siguiente.startswith(("-", "·")):
            if siguiente == inicio_siguiente[0]:
                puntuacion -= 45
        if inicio_siguiente.startswith("%") and texto[posicion:].startswith(
            inicio_siguiente.split()[0]
        ):
            puntuacion -= 45
        if anterior.isalnum() and siguiente.isalnum():
            puntuacion += 1000
        if puntuacion < mejor_puntuacion:
            mejor = posicion
            mejor_puntuacion = puntuacion
    return mejor


def restaurar_saltos(origen: str, destino: str) -> str:
    separadores = SEPARADOR.findall(origen)
    if not separadores:
        return destino
    lineas_origen = SEPARADOR.split(origen)
    indices_no_vacios = [
        indice
        for indice, linea in enumerate(lineas_origen)
        if linea.strip()
    ]
    if not indices_no_vacios:
        return origen
    pesos = [max(1, len(lineas_origen[i].strip())) for i in indices_no_vacios]
    total = sum(pesos)
    candidatos = posiciones_candidatas(destino)
    marcadores_destino = list(MARCADOR.finditer(destino))
    cortes = []
    acumulado = 0
    marcadores_consumidos = 0
    minimo = 0
    for indice in range(len(indices_no_vacios) - 1):
        acumulado += pesos[indice]
        ideal = len(destino) * acumulado / total
        actual = indices_no_vacios[indice]
        siguiente = indices_no_vacios[indice + 1]
        marcadores_linea = list(MARCADOR.finditer(lineas_origen[actual]))
        marcadores_consumidos += len(marcadores_linea)
        corte_forzado = None
        texto_actual = lineas_origen[actual].rstrip()
        texto_siguiente = lineas_origen[siguiente].lstrip()
        if (marcadores_linea and
                texto_actual.endswith(marcadores_linea[-1].group(0)) and
                marcadores_consumidos <= len(marcadores_destino)):
            corte_forzado = marcadores_destino[
                marcadores_consumidos - 1
            ].end()
        marcadores_linea_siguiente = list(
            MARCADOR.finditer(lineas_origen[siguiente])
        )
        if (corte_forzado is None and marcadores_linea_siguiente and
                texto_siguiente.startswith(
                    marcadores_linea_siguiente[0].group(0)) and
                marcadores_consumidos < len(marcadores_destino)):
            corte_forzado = marcadores_destino[
                marcadores_consumidos
            ].start()
        if corte_forzado is not None and corte_forzado > minimo:
            corte = corte_forzado
        else:
            corte = elegir_corte(
                destino,
                candidatos,
                ideal,
                minimo,
                lineas_origen[actual],
                lineas_origen[siguiente],
            )
        cortes.append(corte)
        minimo = corte
    fragmentos = []
    inicio = 0
    for corte in cortes:
        fragmentos.append(destino[inicio:corte].strip())
        inicio = corte
    fragmentos.append(destino[inicio:].strip())
    lineas_destino = [""] * len(lineas_origen)
    for indice, fragmento in zip(indices_no_vacios, fragmentos):
        sangria = lineas_origen[indice][
            : len(lineas_origen[indice]) - len(lineas_origen[indice].lstrip())
        ]
        lineas_destino[indice] = sangria + fragmento
    resultado = lineas_destino[0]
    for indice, separador in enumerate(separadores):
        resultado += separador + lineas_destino[indice + 1]
    return resultado


def decodificar_dfm(expresion: str) -> str:
    resultado = []
    indice = 0
    while indice < len(expresion):
        if expresion[indice] == "'":
            indice += 1
            while indice < len(expresion):
                if expresion[indice] == "'":
                    if indice + 1 < len(expresion) and expresion[indice + 1] == "'":
                        resultado.append("'")
                        indice += 2
                    else:
                        indice += 1
                        break
                else:
                    resultado.append(expresion[indice])
                    indice += 1
        elif expresion[indice] == "#":
            indice += 1
            inicio = indice
            while indice < len(expresion) and expresion[indice].isdigit():
                indice += 1
            if indice > inicio:
                resultado.append(chr(int(expresion[inicio:indice])))
        else:
            indice += 1
    return "".join(resultado)


def catalogo_no_data(raiz: Path) -> dict[str, Entrada]:
    traducciones = {
        "<No hay datos a mostrar>": "<No hi ha dades per mostrar>",
        "<No hay valores en este conjunto>":
            "<No hi ha valors en aquest conjunt>",
        "<Ningún artículo usa esta colección>":
            "<Cap article utilitza aquesta col·lecció>",
        "No hay operaciones para esta fecha":
            "No hi ha operacions per a aquesta data",
        "<No hay atributos para este tipo de variación>":
            "<No hi ha atributs per a aquest tipus de variació>",
        "<No hay artículos que usen este tipo de variación>":
            "<No hi ha articles que utilitzin aquest tipus de variació>",
        "<Selecciona un artículo para ver sus SKUs>":
            "<Seleccioneu un article per veure'n els SKU>",
        "No hay artículos": "No hi ha articles",
        "Sin stock": "Sense estoc",
    }
    rutas = [
        raiz / "src" / "Core",
        raiz / "src" / "Forms",
        raiz / "src" / "Modals",
        raiz / "src" / "Caja" / "Forms",
        raiz / "src" / "Caja" / "Modals",
        raiz / "src" / "verifactu",
    ]
    resultado: dict[str, Entrada] = {}
    patron_componente = re.compile(
        r"^(?:object|inherited|inline)\s+([^:]+):\s*([^\s\[]+)"
    )
    patron_propiedad = re.compile(
        r"^OptionsView\.NoDataToDisplayInfoText\s*=\s*(.*)$"
    )
    for directorio in rutas:
        for ruta in sorted(directorio.glob("*.dfm")):
            lineas = ruta.read_text(encoding="utf-8-sig").splitlines()
            pila: list[tuple[str, str, str]] = []
            clase_raiz = ""
            for linea_original in lineas:
                linea = linea_original.strip()
                encontrado = patron_componente.match(linea)
                if encontrado:
                    nombre, clase = encontrado.groups()
                    pila.append(("componente", nombre.strip(), clase.strip()))
                    if not clase_raiz:
                        clase_raiz = clase.strip()
                    continue
                if re.match(r"^[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\s*=\s*<$", linea):
                    pila.append(("coleccion", "", ""))
                    continue
                if re.match(r"^item(?:\s|$)", linea):
                    pila.append(("item", "", ""))
                    continue
                if re.match(r"^end>\s*$", linea):
                    if pila and pila[-1][0] == "item":
                        pila.pop()
                    if pila and pila[-1][0] == "coleccion":
                        pila.pop()
                    continue
                if re.match(r"^end\)?\s*$", linea):
                    if pila:
                        pila.pop()
                    continue
                propiedad = patron_propiedad.match(linea)
                if not propiedad:
                    continue
                componente = next(
                    (marco for marco in reversed(pila) if marco[0] == "componente"),
                    None,
                )
                if componente is None:
                    raise RuntimeError(f"Propiedad sin componente en {ruta}")
                texto = decodificar_dfm(propiedad.group(1))
                if texto not in traducciones:
                    raise RuntimeError(
                        f"Falta traducción NoData para {texto!r} en {ruta}"
                    )
                _, nombre, clase = componente
                clave = f"{ruta.stem}.{clase_raiz}"
                if clase != clase_raiz:
                    clave += f".{nombre}"
                clave += ".OptionsView.NoDataToDisplayInfoText"
                contexto = ruta.relative_to(raiz).as_posix()
                resultado[clave] = Entrada(
                    clave,
                    traducciones[texto],
                    contexto,
                )
    return resultado


def valor_hexadecimal(valor: str) -> str:
    return "CONVERT(0x" + valor.encode("utf-8").hex() + " USING utf8mb4)"


def escribir_sql(ruta: Path, entradas: list[Entrada]) -> None:
    lineas = [
        "-- D27: revisión lingüística del catálogo catalán ca-ES.",
        "-- Corrige cobertura, textos truncados, saltos de línea y rejillas vacías.",
        "-- Idempotente: actualiza la pareja clave/idioma si ya existe.",
        "START TRANSACTION;",
        "INSERT INTO fza_traducciones (",
        "  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD,",
        "  ESACTIVO_TRAD, ESDESCARGADA_TRAD,",
        "  INSTANTE_ALTA, USUARIO_ALTA",
        ") VALUES",
    ]
    for indice, entrada in enumerate(entradas):
        separador = "," if indice < len(entradas) - 1 else ""
        lineas.extend(
            [
                f"  ({valor_hexadecimal(entrada.clave)},",
                f"   {valor_hexadecimal(IDIOMA)},",
                f"   {valor_hexadecimal(entrada.texto)},",
                f"   {valor_hexadecimal(entrada.contexto)},",
                "   'S', 'S', CURRENT_TIMESTAMP,",
                f"   '{USUARIO}'){separador}",
            ]
        )
    lineas.extend(
        [
            "ON DUPLICATE KEY UPDATE",
            "  TEXTO_TRAD = VALUES(TEXTO_TRAD),",
            "  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD),",
            "  ESACTIVO_TRAD = 'S',",
            "  ESDESCARGADA_TRAD = 'S',",
            "  INSTANTE_MODIF = CURRENT_TIMESTAMP,",
            "  USUARIO_MODIF = VALUES(USUARIO_ALTA);",
            "COMMIT;",
        ]
    )
    ruta.write_text("\n".join(lineas) + "\n", encoding="utf-8")


def principal() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raiz", required=True, type=Path)
    parser.add_argument("--salida", required=True, type=Path)
    opciones = parser.parse_args()
    catalogo = cargar_catalogo()
    nuevas = traducciones_nuevas()
    faltantes = {
        clave
        for clave, (_, _, catalan) in catalogo.items()
        if catalan is None
    }
    no_cubiertas = sorted(faltantes - nuevas.keys())
    if no_cubiertas:
        raise RuntimeError(
            "Faltan traducciones nuevas: " + ", ".join(no_cubiertas)
        )
    correcciones = correcciones_manuales()
    reparar_devexpress(correcciones)
    reparar_terminologia(catalogo, correcciones)
    reparar_fastreport(catalogo, correcciones)
    for clave, (espanol, _, catalan) in catalogo.items():
        if catalan is None or clave in correcciones:
            continue
        if SEPARADOR.findall(espanol) != SEPARADOR.findall(catalan):
            correcciones[clave] = restaurar_saltos(espanol, catalan)
    entradas: dict[str, Entrada] = dict(nuevas)
    for clave, texto in correcciones.items():
        if clave not in catalogo:
            raise RuntimeError(f"No existe la clave corregida {clave}")
        _, contexto, _ = catalogo[clave]
        entradas[clave] = Entrada(clave, texto, contexto)
    entradas.update(catalogo_no_data(opciones.raiz.resolve()))
    escribir_sql(
        opciones.salida,
        [entradas[clave] for clave in sorted(entradas)],
    )
    print(f"FALTANTES_CUBIERTAS={len(faltantes)}")
    print(f"RECURSOS_NUEVOS={len(nuevas) - len(faltantes)}")
    print(f"CORRECCIONES={len(correcciones)}")
    print(f"NO_DATA={len(catalogo_no_data(opciones.raiz.resolve()))}")
    print(f"TOTAL_SQL={len(entradas)}")
    print(f"SALIDA={opciones.salida}")


if __name__ == "__main__":
    principal()
