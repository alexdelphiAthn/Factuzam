#!/usr/bin/env python3
"""Genera y aplica el catálogo chino simplificado de Factuzam."""

from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass
from pathlib import Path

import argostranslate.package
import ctranslate2
import pymysql


IDIOMA_ORIGEN = "es-ES"
IDIOMA_INGLES = "en-GB"
IDIOMA_DESTINO = "zh-CN"
USUARIO_GENERACION = "D25"
CONTEXTOS_FUENTE_INGLES = {
    "CXLOCALIZATION.res",
    "src/vcl37/Vcl.Consts.pas",
}
TRADUCCIONES_REVISADAS = {
    "inMtoPrincipal.TfrmMtoPrincipal.Archivo1.Caption": "文件",
    "inMtoPrincipal.TfrmMtoPrincipal.mnuEmpresas.Caption": "公司",
    "inMtoPrincipal.TfrmMtoPrincipal.mnuClientes.Caption": "客户",
    "inMtoPrincipal.TfrmMtoPrincipal.mnuArticulos.Caption": "商品",
    "inMtoPrincipal.TfrmMtoPrincipal.Salir1.Caption": "退出",
    "inMtoPrincipal.TfrmMtoPrincipal.Compras1.Caption": "采购",
    "inMtoPrincipal.TfrmMtoPrincipal.Ventas1.Caption": "批发销售",
    "inMtoPrincipal.TfrmMtoPrincipal.mnuCaja.Caption": "销售终端",
    "inMtoPrincipal.TfrmMtoPrincipal.mnuAlmacen.Caption": "仓库",
    "inMtoPrincipal.TfrmMtoPrincipal.Utilidades1.Caption": "其他",
    "inMtoPrincipal.TfrmMtoPrincipal.Ayuda1.Caption": "帮助",
    "DevExpress.scxDuration": "持续时间(&U):",
    "Vcl.Consts.SDrivesCap": "驱动器(&R):",
    "inMtoInventarios.TfrmMtoInventarios.tsCabecera.Caption": (
        "3.其他(&3)"
    ),
    "inLibMsgComun.SCaptionTabModoTallasHoriz": (
        "%0:s [横向尺码]"
    ),
    "inLibMsgComun.SCaptionTabModoTallasHorizBandas": (
        "%0:s [横向尺码分组]"
    ),
    "inMtoCajaMenu.TfrmMtoMenuCaja.Caption": "现金菜单",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblF5.Caption": "F5",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblF10.Caption": "F10",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblBuscarModificar.Caption": "查询/修改",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblVentas.Caption": "销售",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblF6.Caption": "F6",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblEntradaCambio.Caption": "零钱入账",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblF7.Caption": "F7",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblGastosCaja.Caption": "现金支出",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblArqueo.Caption": "现金盘点",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblF11.Caption": "F11",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblSalir.Caption": "退出",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblESC.Caption": "ESC",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblFecha.Caption": "收银日期",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblF3.Caption": "F3",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblTraspasos.Caption": "调拨",
    "inMtoCajaMenu.TfrmMtoMenuCaja.lblEmpresa.Caption": "公司",
    "inMtoCajaMenu.TfrmMtoMenuCaja.actSalirMenu.Caption": "ESCAPE",
    "inMtoCajaOpe.TfrmMtoOpeCaja.Caption": "收银操作",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblFecha.Caption": "员工",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblNombreEmpleado.Caption": "员工姓名",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblNombreCliente.Caption": "客户姓名",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblFechaCaja.Caption": "收银日期",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblTarifa.Caption": "价目",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblCliente.Caption": "客户",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblTipoRectificativa.Caption": "差额更正",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblTotal.Caption": "合计 0,00 €",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF12.Caption": "F12",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF3.Caption": "F3",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF8.Caption": "F8",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF6.Caption": "F6",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF61.Caption": "F4",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF7.Caption": "F7",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF5.Caption": "F5",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF2.Caption": "F2",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF10.Caption": "F10",
    "inMtoCajaOpe.TfrmMtoOpeCaja.btnF10.Hint": "查询/修改交易",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblCobro.Caption": "收款",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblBuscar.Caption": "查找",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblEliminar.Caption": "删除",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblTextoTarifa.Caption": "价目",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblBusqTick.Caption": "退货",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblIndIVA.Caption": "含税",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblOtro.Caption": "其他",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblCargarCta.Caption": "加载账户",
    "inMtoCajaOpe.TfrmMtoOpeCaja.lblBuscarModificar.Caption": "查改",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvEmpleado.Caption": "销售员",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvArticulo.Caption": "商品",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvDescripcion.Caption": "说明",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvUds.Caption": "数量",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvTipoCantidad.Caption": "数量类型",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvPrecioUni.Caption": "单价",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvDescuento.Caption": "%",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvDescuentoMenos.Caption": "折扣额",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvTotal.Caption": "合计",
    "inMtoCajaOpe.TfrmMtoOpeCaja.tvFechaOperacion.Caption": "交易日期",
    "inMtoCajaOpe.TfrmMtoOpeCaja.dbtvBusqCODIGO_ARTICULO.Caption": "商品",
    "inMtoCajaOpe.TfrmMtoOpeCaja.dbtvBusqDESCRIPCION_ARTICULO.Caption": "说明",
    "inMtoCajaOpe.TfrmMtoOpeCaja.dbtvBusqTEMPORADA.Caption": "季节",
    "inMtoCajaOpe.TfrmMtoOpeCaja.dbtvBusqPROVEEDOR.Caption": "供应商",
    "inMtoCajaOpe.TfrmMtoOpeCaja.dbtvBusqREF_PROVEEDOR.Caption": "供应商货号",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actBuscarEmpleados.Caption": "查找员工",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actSalir.Caption": "退出",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actEliminarLinea.Caption": "删除行",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actCobro.Caption": "收款",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actCargarCta.Caption": "加载账户",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actBuscarModificar.Caption": "查询/修改",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actGuardarLayout.Caption": "保存布局",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actAbrirArticulos.Caption": "商品",
    "inMtoCajaOpe.TfrmMtoOpeCaja.actConsultaStock.Caption": "库存查询",
}
GLOSARIO_ES_EN = {
    "recargo de equivalencia": "equivalence surcharge",
    "formas de pago": "payment methods",
    "punto de venta": "point of sale",
    "albaranes": "delivery notes",
    "albarán": "delivery note",
    "artículos": "products",
    "artículo": "product",
    "proveedores": "suppliers",
    "proveedor": "supplier",
    "facturas": "invoices",
    "factura": "invoice",
    "clientes": "customers",
    "cliente": "customer",
    "pedidos": "orders",
    "pedido": "order",
    "compras": "purchases",
    "compra": "purchase",
    "ventas": "sales",
    "venta": "sale",
    "tallas": "sizes",
    "talla": "size",
    "almacén": "warehouse",
    "familias": "product families",
    "familia": "product family",
    "tarifas": "price lists",
    "tarifa": "price list",
    "arqueo": "cash count",
    "caja": "cash register",
}

PATRON_FORMATO = re.compile(
    r"%(?:\d+:)?[-\d]*(?:\.\d+)?[dDuUeEfFgGnNmMpPsSxX]"
)
PATRON_PROTEGIDO = re.compile(
    r"%(?:\d+:)?[-\d]*(?:\.\d+)?[dDuUeEfFgGnNmMpPsSxX]"
    r"|%%"
    r"|<(?=[^<>\r\n]*(?:[\"._#]|[A-Z]{2}))[^<>\r\n]+>"
    r"|\$\([^()\r\n]+\)"
    r"|https?://[^\s<>]+"
    r"|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"
    r"|(?:[A-Za-z]:\\|\\\\)[^\s,;]+"
    r"|\b(?:Ctrl|Alt|Shift)\+[A-Za-z0-9+]+"
    r"|\b(?:F(?:[1-9]|1[0-2])|Esc(?:ape)?)\b"
    r"|\b[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z0-9_.]+\b"
    r"|\*?\.[A-Za-z0-9]{1,8}\b"
)
PATRON_EXPRESION_TECNICA = re.compile(
    r"\[(?=[^\]]*[\".<>()#])[^\]]+\]",
    re.DOTALL,
)
PATRON_ACELERADOR = re.compile(r"(^|[\s(])&([A-Za-z0-9])")
PATRON_LINEAS = re.compile(r"(\r\n|\r|\n)")


@dataclass(frozen=True)
class Recurso:
    clave: str
    texto_es: str
    texto_en: str | None
    texto_zh: str | None
    contexto: str


@dataclass
class LineaPreparada:
    original: str
    idioma: str
    prefijo: str
    sufijo: str
    segmentos: list[tuple[bool, str]]
    acelerador: str
    siguiente_argumento: int


class TraductorLote:
    def __init__(self, origen: str, destino: str) -> None:
        paquetes = argostranslate.package.get_installed_packages()
        paquete = next(
            (
                actual
                for actual in paquetes
                if actual.from_code == origen
                and actual.to_code == destino
            ),
            None,
        )
        if paquete is None:
            mensaje = (
                f"Falta el modelo Argos Translate {origen}->{destino}."
            )
            raise RuntimeError(mensaje)
        self._paquete = paquete
        self._traductor = ctranslate2.Translator(
            str(paquete.package_path / "model"),
            device="cpu",
            compute_type="int8",
        )

    def traducir(self, textos: list[str]) -> list[str]:
        if not textos:
            return []
        tokenizados = [
            self._paquete.tokenizer.encode(texto)
            for texto in textos
        ]
        resultados = self._traductor.translate_batch(
            tokenizados,
            beam_size=4,
            max_batch_size=128,
            batch_type="tokens",
            replace_unknowns=True,
        )
        return [
            self._paquete.tokenizer.decode(
                resultado.hypotheses[0]
            ).strip()
            for resultado in resultados
        ]


def argumentos() -> argparse.Namespace:
    analizador = argparse.ArgumentParser(
        description="Genera el catálogo zh-CN a partir de es-ES/en-GB.",
    )
    analizador.add_argument("--servidor", default="127.0.0.1")
    analizador.add_argument("--puerto", default=3306, type=int)
    analizador.add_argument("--base-datos", default="factuzam")
    analizador.add_argument("--usuario", default="root")
    analizador.add_argument(
        "--salida",
        type=Path,
        default=Path(__file__).with_name(
            "traducciones_zh_cn_d25.sql"
        ),
    )
    analizador.add_argument(
        "--aplicar",
        action="store_true",
        help="Aplica el catálogo generado a la base de datos.",
    )
    analizador.add_argument(
        "--regenerar-existentes",
        action="store_true",
        help="Sustituye también las traducciones zh-CN existentes.",
    )
    return analizador.parse_args()


def conectar(opciones: argparse.Namespace):
    clave = os.environ.get("FACTUZAM_DB_PASSWORD", "")
    if not clave:
        raise RuntimeError(
            "Debe definir la variable FACTUZAM_DB_PASSWORD."
        )
    return pymysql.connect(
        host=opciones.servidor,
        port=opciones.puerto,
        user=opciones.usuario,
        password=clave,
        database=opciones.base_datos,
        charset="utf8mb4",
        autocommit=False,
    )


def cargar_recursos(conexion) -> list[Recurso]:
    consulta = """
SELECT E.CLAVE_TRAD,
       E.TEXTO_TRAD AS TEXTO_ES,
       I.TEXTO_TRAD AS TEXTO_EN,
       Z.TEXTO_TRAD AS TEXTO_ZH,
       E.CONTEXTO_TRAD
  FROM fza_traducciones E
  LEFT JOIN fza_traducciones I
    ON I.CLAVE_TRAD = E.CLAVE_TRAD
   AND I.IDIOMA_TRAD = %s
   AND I.ESACTIVO_TRAD = 'S'
  LEFT JOIN fza_traducciones Z
    ON Z.CLAVE_TRAD = E.CLAVE_TRAD
   AND Z.IDIOMA_TRAD = %s
   AND Z.ESACTIVO_TRAD = 'S'
 WHERE E.IDIOMA_TRAD = %s
   AND E.ESACTIVO_TRAD = 'S'
 ORDER BY E.CLAVE_TRAD
"""
    with conexion.cursor() as cursor:
        cursor.execute(
            consulta,
            (IDIOMA_INGLES, IDIOMA_DESTINO, IDIOMA_ORIGEN),
        )
        return [
            Recurso(
                clave=fila[0],
                texto_es=fila[1],
                texto_en=fila[2],
                texto_zh=fila[3],
                contexto=fila[4] or "",
            )
            for fila in cursor.fetchall()
        ]


def marcador_explicito(marcador: str, indice: int) -> str:
    contenido = marcador[1:]
    if re.match(r"^\d+:", contenido):
        return marcador
    return f"%{indice}:{contenido}"


def avanzar_argumentos(texto: str, siguiente: int) -> int:
    for coincidencia in PATRON_FORMATO.finditer(texto):
        explicito = re.match(r"^%(\d+):", coincidencia.group(0))
        if explicito:
            siguiente = int(explicito.group(1)) + 1
        else:
            siguiente += 1
    return siguiente


def firma_marcadores(texto: str) -> list[tuple[int, str]]:
    firma: list[tuple[int, str]] = []
    siguiente = 0
    for coincidencia in PATRON_FORMATO.finditer(texto):
        marcador = coincidencia.group(0)
        explicito = re.match(r"^%(\d+):", marcador)
        if explicito:
            indice = int(explicito.group(1))
            siguiente = indice + 1
        else:
            indice = siguiente
            siguiente += 1
        firma.append((indice, marcador[-1].upper()))
    return sorted(firma)


def quitar_acelerador(texto: str) -> tuple[str, str]:
    coincidencia = PATRON_ACELERADOR.search(texto)
    if coincidencia is None:
        return texto, ""
    acelerador = coincidencia.group(2).upper()
    return PATRON_ACELERADOR.sub(r"\1\2", texto), acelerador


def preparar_linea(
    texto: str,
    idioma: str,
    indice_inicial: int,
) -> LineaPreparada:
    if texto.strip():
        prefijo = texto[: len(texto) - len(texto.lstrip())]
        sufijo = texto[len(texto.rstrip()) :]
    else:
        prefijo = texto
        sufijo = ""
    nucleo = texto.strip()
    nucleo, acelerador = quitar_acelerador(nucleo)
    segmentos: list[tuple[bool, str]] = []
    indice_argumento = indice_inicial
    posicion = 0

    for coincidencia in PATRON_PROTEGIDO.finditer(nucleo):
        if coincidencia.start() > posicion:
            segmentos.append(
                (False, nucleo[posicion : coincidencia.start()])
            )
        original = coincidencia.group(0)
        restaurado = original
        if PATRON_FORMATO.fullmatch(original):
            restaurado = marcador_explicito(
                original,
                indice_argumento,
            )
            explicito = re.match(r"^%(\d+):", original)
            if explicito:
                indice_argumento = int(explicito.group(1)) + 1
            else:
                indice_argumento += 1
        segmentos.append((True, restaurado))
        posicion = coincidencia.end()
    if posicion < len(nucleo):
        segmentos.append((False, nucleo[posicion:]))
    if not segmentos:
        segmentos.append((False, nucleo))
    return LineaPreparada(
        original=texto,
        idioma=idioma,
        prefijo=prefijo,
        sufijo=sufijo,
        segmentos=segmentos,
        acelerador=acelerador,
        siguiente_argumento=indice_argumento,
    )


def normalizar_chino(texto: str) -> str:
    resultado = PATRON_FORMATO.sub("", texto)
    resultado = re.sub(r"[\"“']\s*[\"”']", "", resultado)
    resultado = re.sub(r"\s+([，。！？：；、）】,.!?;:])", r"\1", resultado)
    resultado = re.sub(r"([（【])\s+", r"\1", resultado)
    resultado = re.sub(r"[ \t]{2,}", " ", resultado)
    return resultado.strip()


def separar_espacios(texto: str) -> tuple[str, str, str]:
    if not texto.strip():
        return texto, "", ""
    prefijo = texto[: len(texto) - len(texto.lstrip())]
    sufijo = texto[len(texto.rstrip()) :]
    return prefijo, texto.strip(), sufijo


def reconstruir_linea(
    preparada: LineaPreparada,
    traducciones: dict[tuple[str, str], str],
) -> str:
    resultado = ""
    for protegido, segmento in preparada.segmentos:
        if protegido:
            resultado += segmento
        else:
            prefijo, nucleo, sufijo = separar_espacios(segmento)
            traducido = traducciones.get(
                (preparada.idioma, nucleo),
                nucleo,
            )
            resultado += prefijo + traducido + sufijo
    if preparada.acelerador:
        resultado = f"{resultado}(&{preparada.acelerador})"
    return preparada.prefijo + resultado + preparada.sufijo


def necesita_traduccion(texto: str) -> bool:
    return any(caracter.isalpha() for caracter in texto)


def traduccion_glosario(texto: str) -> str | None:
    terminos = sorted(
        GLOSARIO_ES_EN.items(),
        key=lambda elemento: len(elemento[0]),
        reverse=True,
    )
    for espanol, ingles in terminos:
        patron = re.compile(
            rf"^{re.escape(espanol)}([:;,.!?]?)$",
            re.IGNORECASE,
        )
        coincidencia = patron.match(texto)
        if coincidencia:
            if texto[0].isupper():
                ingles = ingles[0].upper() + ingles[1:]
            return ingles + coincidencia.group(1)
    return None


def traducir_lineas(
    preparadas: list[LineaPreparada],
) -> dict[int, str]:
    fragmentos: dict[tuple[str, str], str] = {}
    for preparada in preparadas:
        for protegido, segmento in preparada.segmentos:
            if protegido:
                continue
            _, nucleo, _ = separar_espacios(segmento)
            fragmentos[(preparada.idioma, nucleo)] = nucleo
    espanolas = [
        clave
        for clave, texto in fragmentos.items()
        if clave[0] == "es" and necesita_traduccion(texto)
    ]
    inglesas = [
        clave
        for clave, texto in fragmentos.items()
        if clave[0] == "en" and necesita_traduccion(texto)
    ]
    print(
        f"Fragmentos únicos: {len(fragmentos)}; "
        f"es->en: {len(espanolas)}; en->zh: "
        f"{len(espanolas) + len(inglesas)}",
        flush=True,
    )
    textos_ingles: dict[tuple[str, str], str] = {}
    espanolas_modelo: list[tuple[str, str]] = []
    for clave in espanolas:
        directa = traduccion_glosario(fragmentos[clave])
        if directa is None:
            espanolas_modelo.append(clave)
        else:
            textos_ingles[clave] = directa
    if espanolas_modelo:
        traductor_es = TraductorLote("es", "en")
        traducidas = traductor_es.traducir(
            [fragmentos[clave] for clave in espanolas_modelo]
        )
        for clave, traducida in zip(espanolas_modelo, traducidas):
            textos_ingles[clave] = traducida
    pendientes_zh = inglesas + espanolas
    entradas_zh = [
        fragmentos[clave]
        if clave[0] == "en"
        else textos_ingles[clave]
        for clave in pendientes_zh
    ]
    traducidas_zh: list[str] = []
    if entradas_zh:
        traductor_zh = TraductorLote("en", "zh")
        traducidas_zh = traductor_zh.traducir(entradas_zh)
    resultado: dict[tuple[str, str], str] = {}
    for clave, traducida in zip(pendientes_zh, traducidas_zh):
        resultado[clave] = normalizar_chino(traducida)
    for clave, texto in fragmentos.items():
        if clave not in resultado:
            resultado[clave] = texto
    lineas: dict[int, str] = {}
    for preparada in preparadas:
        lineas[id(preparada)] = reconstruir_linea(
            preparada,
            resultado,
        )
    return lineas


def agregar_bloque_lineas(
    resultado: list[LineaPreparada | str],
    texto: str,
    idioma: str,
    indice_argumento: int,
) -> int:
    for parte in PATRON_LINEAS.split(texto):
        if PATRON_LINEAS.fullmatch(parte):
            resultado.append(parte)
        else:
            preparada = preparar_linea(
                parte,
                idioma,
                indice_argumento,
            )
            resultado.append(preparada)
            indice_argumento = preparada.siguiente_argumento
    return indice_argumento


def dividir_lineas(texto: str, idioma: str) -> list[LineaPreparada | str]:
    resultado: list[LineaPreparada | str] = []
    posicion = 0
    indice_argumento = 0
    for expresion in PATRON_EXPRESION_TECNICA.finditer(texto):
        indice_argumento = agregar_bloque_lineas(
            resultado,
            texto[posicion : expresion.start()],
            idioma,
            indice_argumento,
        )
        protegida = expresion.group(0)
        resultado.append(protegida)
        indice_argumento = avanzar_argumentos(
            protegida,
            indice_argumento,
        )
        posicion = expresion.end()
    agregar_bloque_lineas(
        resultado,
        texto[posicion:],
        idioma,
        indice_argumento,
    )
    return resultado


def generar_catalogo(
    recursos: list[Recurso],
    regenerar_existentes: bool,
) -> list[tuple[str, str, str]]:
    pendientes: dict[str, list[LineaPreparada | str]] = {}
    preparadas: list[LineaPreparada] = []
    for recurso in recursos:
        if recurso.texto_zh and (
            not regenerar_existentes
            or recurso.clave in TRADUCCIONES_REVISADAS
        ):
            continue
        ingles_compatible = (
            recurso.texto_en
            and recurso.contexto in CONTEXTOS_FUENTE_INGLES
            and firma_marcadores(recurso.texto_es)
            == firma_marcadores(recurso.texto_en)
        )
        idioma = "en" if ingles_compatible else "es"
        texto = recurso.texto_en if ingles_compatible else recurso.texto_es
        partes = dividir_lineas(texto, idioma)
        pendientes[recurso.clave] = partes
        preparadas.extend(
            parte
            for parte in partes
            if isinstance(parte, LineaPreparada)
        )
    traducciones = traducir_lineas(preparadas)
    catalogo: list[tuple[str, str, str]] = []
    for recurso in recursos:
        if recurso.clave not in pendientes:
            texto_zh = recurso.texto_zh or recurso.texto_es
        else:
            partes = pendientes[recurso.clave]
            texto_zh = "".join(
                parte
                if isinstance(parte, str)
                else traducciones[id(parte)]
                for parte in partes
            )
        texto_zh = TRADUCCIONES_REVISADAS.get(
            recurso.clave,
            texto_zh,
        )
        catalogo.append(
            (recurso.clave, texto_zh, recurso.contexto)
        )
    return catalogo


def valor_hexadecimal(texto: str) -> str:
    hexadecimal = texto.encode("utf-8").hex().upper()
    return f"CONVERT(0x{hexadecimal} USING utf8mb4)"


def escribir_sql(
    ruta: Path,
    catalogo: list[tuple[str, str, str]],
) -> None:
    cabecera = [
        "-- D25: catálogo chino simplificado (zh-CN).",
        "-- Traducción automática pendiente de revisión visual.",
        "-- Fuente: es-ES; en-GB para VCL y Developer Express.",
        "-- Idempotente: ON DUPLICATE KEY UPDATE.",
        "SET NAMES utf8mb4;",
        "START TRANSACTION;",
    ]
    lineas = cabecera
    tamano_bloque = 400
    for inicio in range(0, len(catalogo), tamano_bloque):
        bloque = catalogo[inicio : inicio + tamano_bloque]
        lineas.extend(
            [
                "INSERT INTO fza_traducciones (",
                "  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD,",
                "  CONTEXTO_TRAD, ESACTIVO_TRAD,",
                "  ESDESCARGADA_TRAD, INSTANTE_ALTA, USUARIO_ALTA",
                ") VALUES",
            ]
        )
        for indice, (clave, texto, contexto) in enumerate(bloque):
            separador = "," if indice < len(bloque) - 1 else ""
            lineas.extend(
                [
                    f"  ({valor_hexadecimal(clave)},",
                    f"   '{IDIOMA_DESTINO}',",
                    f"   {valor_hexadecimal(texto)},",
                    f"   {valor_hexadecimal(contexto)},",
                    "   'S', 'S', CURRENT_TIMESTAMP,",
                    f"   '{USUARIO_GENERACION}'){separador}",
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
            ]
        )
    lineas.extend(
        [
            "COMMIT;",
            "SELECT COUNT(*) AS PENDIENTES",
            "  FROM fza_traducciones E",
            "  LEFT JOIN fza_traducciones Z",
            "    ON Z.CLAVE_TRAD = E.CLAVE_TRAD",
            f"   AND Z.IDIOMA_TRAD = '{IDIOMA_DESTINO}'",
            "   AND Z.ESACTIVO_TRAD = 'S'",
            f" WHERE E.IDIOMA_TRAD = '{IDIOMA_ORIGEN}'",
            "   AND E.ESACTIVO_TRAD = 'S'",
            "   AND Z.ID_TRAD IS NULL;",
        ]
    )
    ruta.write_text("\n".join(lineas) + "\n", encoding="utf-8")


def aplicar_catalogo(conexion, catalogo) -> None:
    sentencia = """
INSERT INTO fza_traducciones (
  CLAVE_TRAD, IDIOMA_TRAD, TEXTO_TRAD, CONTEXTO_TRAD,
  ESACTIVO_TRAD, ESDESCARGADA_TRAD, INSTANTE_ALTA, USUARIO_ALTA
) VALUES (
  %s, %s, %s, %s, 'S', 'S', CURRENT_TIMESTAMP, %s
) ON DUPLICATE KEY UPDATE
  TEXTO_TRAD = VALUES(TEXTO_TRAD),
  CONTEXTO_TRAD = VALUES(CONTEXTO_TRAD),
  ESACTIVO_TRAD = 'S',
  ESDESCARGADA_TRAD = 'S',
  INSTANTE_MODIF = CURRENT_TIMESTAMP,
  USUARIO_MODIF = VALUES(USUARIO_ALTA)
"""
    valores = [
        (clave, IDIOMA_DESTINO, texto, contexto, USUARIO_GENERACION)
        for clave, texto, contexto in catalogo
    ]
    try:
        with conexion.cursor() as cursor:
            cursor.executemany(sentencia, valores)
        conexion.commit()
    except Exception:
        conexion.rollback()
        raise


def principal() -> None:
    opciones = argumentos()
    conexion = conectar(opciones)
    try:
        recursos = cargar_recursos(conexion)
        if not recursos:
            raise RuntimeError("No hay recursos es-ES activos.")
        catalogo = generar_catalogo(
            recursos,
            opciones.regenerar_existentes,
        )
        escribir_sql(opciones.salida, catalogo)
        print(
            f"SQL generado: {opciones.salida} ({len(catalogo)} claves)",
            flush=True,
        )
        if opciones.aplicar:
            aplicar_catalogo(conexion, catalogo)
            print("Catálogo aplicado a la base de datos.", flush=True)
    finally:
        conexion.close()


if __name__ == "__main__":
    principal()
