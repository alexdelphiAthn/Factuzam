#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generador de documentacion HTML para el manual de Factuzam.

Convierte los .md de la carpeta manual/ en un sitio HTML estatico y
navegable dentro de manual/html/. No usa dependencias externas: solo la
libreria estandar de Python 3, para poder ejecutarse en cualquier equipo
(incluido Windows) sin instalar nada.

Uso:
    python generar_html.py

Fuentes traducidas opcionales:
    manual/i18n/<idioma>/<capitulo>.md

Salida:
    manual/html/index.html + un .html por cada capitulo en espanol
    manual/html/<idioma>/... para cada traduccion configurada
    manual/html/estilo.css + manual/html/img/

Si falta un capitulo traducido se publica el Markdown espanol con un aviso.
Las paginas traducidas conservan por orden las anclas del capitulo espanol,
de modo que los enlaces existentes siguen siendo validos.
"""
import os
import re
import html
import datetime
import hashlib

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(AQUI, 'html')
IDIOMA_BASE = 'es-ES'

# El espanol conserva las URL historicas en la raiz de html. Los demas
# idiomas se publican en un subdirectorio con su etiqueta BCP 47.
IDIOMAS = [
    ('es-ES', 'ES', 'Español'),
    ('en-GB', 'EN', 'English'),
    ('ca-ES', 'CA', 'Català'),
    ('zh-CN', 'ZH', '中文'),
]

BANDERAS = {
    'es-ES': '🇪🇸',
    'en-GB': '🇬🇧',
    'ca-ES': '',  # La senyera se dibuja con CSS: no tiene emoji Unicode.
    'zh-CN': '🇨🇳',
}

TEXTOS_UI = {
    'es-ES': {
        'marca': 'Manual de usuario',
        'titulo': 'Manual de Factuzam',
        'boton_menu': 'Menú',
        'selector': 'Idioma del manual',
        'pie': 'Manual de Factuzam · generado el {fecha}',
        'fallback': '',
    },
    'en-GB': {
        'marca': 'User manual',
        'titulo': 'Factuzam User Manual',
        'boton_menu': 'Menu',
        'selector': 'Manual language',
        'pie': 'Factuzam User Manual · generated on {fecha}',
        'fallback': (
            '<strong>Translation pending.</strong> This chapter is not yet '
            'available in English; the Spanish version is shown.'
        ),
    },
    'ca-ES': {
        'marca': "Manual d'usuari",
        'titulo': 'Manual de Factuzam',
        'boton_menu': 'Menú',
        'selector': 'Idioma del manual',
        'pie': 'Manual de Factuzam · generat el {fecha}',
        'fallback': (
            '<strong>Traducció pendent.</strong> Aquest capítol encara no '
            "està disponible en català; es mostra la versió en castellà."
        ),
    },
    'zh-CN': {
        'marca': '用户手册',
        'titulo': 'Factuzam 用户手册',
        'boton_menu': '菜单',
        'selector': '手册语言',
        'pie': 'Factuzam 用户手册 · 生成于 {fecha}',
        'fallback': (
            '<strong>翻译待完成。</strong>本章暂未提供中文版本，'
            '现显示西班牙语版本。'
        ),
    },
}

# Orden de los capitulos en el menu lateral. El primero (README) es la
# portada y se publica como index.html.
ORDEN = [
    ('README.md', 'index.html', 'Inicio'),
    ('00-acceso-y-primeros-pasos.md', '00-acceso-y-primeros-pasos.html', '00 · Acceso y primeros pasos'),
    ('01-conceptos-comunes.md', '01-conceptos-comunes.html', '01 · Conceptos comunes'),
    ('02-menu-archivo.md', '02-menu-archivo.html', '02 · Menú Archivo'),
    ('03-menu-compras.md', '03-menu-compras.html', '03 · Menú Compras'),
    ('04-menu-ventas-mayor.md', '04-menu-ventas-mayor.html', '04 · Menú Ventas Mayor'),
    ('05-menu-caja.md', '05-menu-caja.html', '05 · Menú TPV'),
    ('06-menu-almacen.md', '06-menu-almacen.html', '06 · Menú Almacén'),
    ('07-menu-otros.md', '07-menu-otros.html', '07 · Menú Otros'),
    ('08-menu-ayuda.md', '08-menu-ayuda.html', '08 · Menú Ayuda'),
    ('09-instalacion-windows.md', '09-instalacion-windows.html', '09 · Instalación en Windows'),
    ('10-migracion-legacy.md', '10-migracion-legacy.html', '10 · Migración desde legacy'),
    ('11-verifactu.md', '11-verifactu.html', '11 · Verifactu (AEAT)'),
    ('12-cambios-y-novedades.md', '12-cambios-y-novedades.html', '12 · Cambios y novedades'),
    ('13-aplicaciones-moviles.md', '13-aplicaciones-moviles.html', '13 · Aplicaciones móviles'),
    ('14-arquitectura-y-desarrollo.md', '14-arquitectura-y-desarrollo.html', '14 · Arquitectura y desarrollo'),
    ('15-integracion-prestashop.md', '15-integracion-prestashop.html', '15 · Integración con PrestaShop'),
]
MD2HTML = {md: dst for md, dst, _ in ORDEN}

ETIQUETAS_NAV = {
    'en-GB': {
        'index.html': 'Home',
        '00-acceso-y-primeros-pasos.html': '00 · Access and first steps',
        '01-conceptos-comunes.html': '01 · Common concepts',
        '02-menu-archivo.html': '02 · File menu',
        '03-menu-compras.html': '03 · Purchases menu',
        '04-menu-ventas-mayor.html': '04 · Wholesale menu',
        '05-menu-caja.html': '05 · POS menu',
        '06-menu-almacen.html': '06 · Warehouse menu',
        '07-menu-otros.html': '07 · Other menu',
        '08-menu-ayuda.html': '08 · Help menu',
        '09-instalacion-windows.html': '09 · Windows installation',
        '10-migracion-legacy.html': '10 · Migration from legacy',
        '11-verifactu.html': '11 · Verifactu (AEAT)',
        '12-cambios-y-novedades.html': '12 · Changes and new features',
        '13-aplicaciones-moviles.html': '13 · Mobile applications',
        '14-arquitectura-y-desarrollo.html': (
            '14 · Architecture and development'
        ),
        '15-integracion-prestashop.html': '15 · PrestaShop integration',
    },
    'ca-ES': {
        'index.html': 'Inici',
        '00-acceso-y-primeros-pasos.html': '00 · Accés i primers passos',
        '01-conceptos-comunes.html': '01 · Conceptes comuns',
        '02-menu-archivo.html': '02 · Menú Fitxer',
        '03-menu-compras.html': '03 · Menú Compres',
        '04-menu-ventas-mayor.html': '04 · Menú Vendes majoristes',
        '05-menu-caja.html': '05 · Menú TPV',
        '06-menu-almacen.html': '06 · Menú Magatzem',
        '07-menu-otros.html': '07 · Menú Altres',
        '08-menu-ayuda.html': '08 · Menú Ajuda',
        '09-instalacion-windows.html': '09 · Instal·lació a Windows',
        '10-migracion-legacy.html': '10 · Migració des del sistema anterior',
        '11-verifactu.html': '11 · Verifactu (AEAT)',
        '12-cambios-y-novedades.html': '12 · Canvis i novetats',
        '13-aplicaciones-moviles.html': '13 · Aplicacions mòbils',
        '14-arquitectura-y-desarrollo.html': (
            '14 · Arquitectura i desenvolupament'
        ),
        '15-integracion-prestashop.html': '15 · Integració amb PrestaShop',
    },
    'zh-CN': {
        'index.html': '首页',
        '00-acceso-y-primeros-pasos.html': '00 · 访问与入门',
        '01-conceptos-comunes.html': '01 · 通用概念',
        '02-menu-archivo.html': '02 · 文件菜单',
        '03-menu-compras.html': '03 · 采购菜单',
        '04-menu-ventas-mayor.html': '04 · 批发销售菜单',
        '05-menu-caja.html': '05 · POS 菜单',
        '06-menu-almacen.html': '06 · 仓库菜单',
        '07-menu-otros.html': '07 · 其他菜单',
        '08-menu-ayuda.html': '08 · 帮助菜单',
        '09-instalacion-windows.html': '09 · Windows 安装',
        '10-migracion-legacy.html': '10 · 从旧版迁移',
        '11-verifactu.html': '11 · Verifactu (AEAT)',
        '12-cambios-y-novedades.html': '12 · 更改与新功能',
        '13-aplicaciones-moviles.html': '13 · 移动应用',
        '14-arquitectura-y-desarrollo.html': '14 · 架构与开发',
        '15-integracion-prestashop.html': '15 · PrestaShop 集成',
    },
}


def slug(texto):
    """Genera un ancla estilo GitHub a partir del texto de un encabezado."""
    s = texto.strip().lower()
    s = s.replace('·', ' ')
    # quitar acentos basicos
    for a, b in (('á', 'a'), ('é', 'e'), ('í', 'i'), ('ó', 'o'), ('ú', 'u'),
                 ('ñ', 'n'), ('ü', 'u')):
        s = s.replace(a, b)
    s = re.sub(r'[^a-z0-9 \-]', '', s)
    s = s.strip().replace(' ', '-')
    s = re.sub(r'-+', '-', s)
    return s


def estructura_encabezados(texto):
    """Devuelve (nivel, ancla) de los encabezados fuera de bloques codigo."""
    resultado = []
    en_codigo = False
    for linea in texto.split('\n'):
        if linea.startswith('```'):
            en_codigo = not en_codigo
        elif not en_codigo:
            m = re.match(r'^(#{1,6})\s+(.*)$', linea)
            if m:
                resultado.append((len(m.group(1)), slug(m.group(2).strip())))
    return resultado


def validar_estructura_traduccion(texto_base, texto_traducido, ruta):
    """Impide publicar una traduccion que rompa las anclas canonicas."""
    base = estructura_encabezados(texto_base)
    traducida = estructura_encabezados(texto_traducido)
    niveles_base = [nivel for nivel, _ in base]
    niveles_traducidos = [nivel for nivel, _ in traducida]
    if niveles_traducidos != niveles_base:
        raise ValueError(
            'La traduccion %s no conserva el numero y nivel de encabezados '
            'del Markdown espanol' % ruta
        )
    return [ancla for _, ancla in base]


def corregir_enlace(destino):
    """Reescribe enlaces .md -> .html conservando el ancla."""
    ancla = ''
    if '#' in destino:
        destino, ancla = destino.split('#', 1)
        ancla = '#' + ancla
    if destino in MD2HTML:
        destino = MD2HTML[destino]
    return destino + ancla


def corregir_recurso(destino, prefijo_recursos):
    """Ajusta recursos compartidos al publicar dentro de html/<idioma>."""
    if (not prefijo_recursos or not destino.startswith('img/') or
            destino.startswith(('http://', 'https://', 'data:'))):
        return destino
    return prefijo_recursos + destino


def inline(texto, prefijo_recursos=''):
    """Formato en linea: codigo, imagenes, enlaces, negrita, cursiva."""
    codigos = []
    enlaces_automaticos = []

    def guarda_codigo(m):
        codigos.append(m.group(1))
        return '\x00C%d\x00' % (len(codigos) - 1)

    texto = re.sub(r'`([^`]+)`', guarda_codigo, texto)

    def guarda_enlace_automatico(m):
        enlaces_automaticos.append(m.group(1))
        return '\x00A%d\x00' % (len(enlaces_automaticos) - 1)

    texto = re.sub(r'<(https?://[^<>\s]+)>', guarda_enlace_automatico,
                   texto)
    texto = html.escape(texto, quote=False)
    # imagenes ![alt](src)
    texto = re.sub(
        r'!\[([^\]]*)\]\(([^)]+)\)',
        lambda m: '<img src="%s" alt="%s" loading="lazy">'
                  % (html.escape(
                         corregir_recurso(m.group(2), prefijo_recursos),
                         quote=True),
                     m.group(1)),
        texto)
    # enlaces [texto](destino)
    texto = re.sub(
        r'\[([^\]]+)\]\(([^)]+)\)',
        lambda m: '<a href="%s">%s</a>'
                  % (html.escape(corregir_enlace(m.group(2)), quote=True),
                     m.group(1)),
        texto)
    texto = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', texto)
    texto = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', texto)
    # restaurar enlaces automaticos
    texto = re.sub(
        r'\x00A(\d+)\x00',
        lambda m: '<a href="%s">%s</a>'
                  % (html.escape(enlaces_automaticos[int(m.group(1))],
                                 quote=True),
                     html.escape(enlaces_automaticos[int(m.group(1))],
                                 quote=False)),
        texto
    )
    # restaurar codigo
    texto = re.sub(r'\x00C(\d+)\x00',
                   lambda m: '<code>%s</code>'
                             % html.escape(codigos[int(m.group(1))], quote=False),
                   texto)
    return texto


PATRON_LISTA = re.compile(r'^(\s*)([-*]|\d+\.)\s+(.*)$')


def datos_elemento_lista(linea):
    """Devuelve sangria, tipo, numero y texto de un elemento de lista."""
    m = PATRON_LISTA.match(linea)
    if not m:
        return None
    sangria = len(m.group(1).expandtabs(4))
    marcador = m.group(2)
    tipo = 'ul' if marcador in ('-', '*') else 'ol'
    numero = int(marcador[:-1]) if tipo == 'ol' else None
    return sangria, tipo, numero, m.group(3).strip()


def render_lista(lineas, inicio, prefijo_recursos=''):
    """Renderiza una lista y sus sublistas conservando la lista principal."""
    primeros_datos = datos_elemento_lista(lineas[inicio])
    sangria_base, tipo, primer_numero, _ = primeros_datos
    atributos = ''
    if tipo == 'ol' and primer_numero != 1:
        atributos = ' start="%d"' % primer_numero
    elementos = []
    i = inicio
    while i < len(lineas):
        datos = datos_elemento_lista(lineas[i])
        if not datos or datos[0] != sangria_base or datos[1] != tipo:
            break
        partes = [datos[3]]
        sublistas = []
        i += 1
        while i < len(lineas) and lineas[i].strip() != '':
            datos_siguiente = datos_elemento_lista(lineas[i])
            if datos_siguiente:
                if datos_siguiente[0] > sangria_base:
                    sublista, i = render_lista(
                        lineas, i, prefijo_recursos
                    )
                    sublistas.append(sublista)
                    continue
                break
            sangria = len(lineas[i]) - len(lineas[i].lstrip())
            if sangria <= sangria_base:
                break
            partes.append(lineas[i].strip())
            i += 1
        contenido = inline(
            ' '.join(partes), prefijo_recursos
        ) + ''.join(sublistas)
        elementos.append('<li>%s</li>' % contenido)
    return '<%s%s>%s</%s>' % (tipo, atributos, ''.join(elementos), tipo), i


def render_tabla(filas, prefijo_recursos=''):
    """filas: lista de lineas markdown de tabla (con pipes)."""
    def celdas(linea):
        linea = linea.strip()
        if linea.startswith('|'):
            linea = linea[1:]
        if linea.endswith('|'):
            linea = linea[:-1]
        return [c.strip() for c in linea.split('|')]

    cabecera = celdas(filas[0])
    cuerpo = [celdas(f) for f in filas[2:]]
    out = ['<table>', '<thead><tr>']
    out += [
        '<th>%s</th>' % inline(c, prefijo_recursos) for c in cabecera
    ]
    out += ['</tr></thead>', '<tbody>']
    for fila in cuerpo:
        out.append(
            '<tr>' + ''.join(
                '<td>%s</td>' % inline(c, prefijo_recursos) for c in fila
            ) + '</tr>'
        )
    out += ['</tbody>', '</table>']
    return '\n'.join(out)


def md_a_html(texto, anclas_canonicas=None, prefijo_recursos='',
              _estado_anclas=None):
    if _estado_anclas is None:
        _estado_anclas = {'indice': 0}
    lineas = texto.split('\n')
    out = []
    i = 0
    n = len(lineas)
    while i < n:
        linea = lineas[i]
        # bloque de codigo cercado
        if linea.startswith('```'):
            j = i + 1
            buf = []
            while j < n and not lineas[j].startswith('```'):
                buf.append(lineas[j])
                j += 1
            out.append('<pre><code>%s</code></pre>'
                       % html.escape('\n'.join(buf), quote=False))
            i = j + 1
            continue
        # tabla
        if (linea.lstrip().startswith('|') and i + 1 < n
                and re.match(r'^\s*\|?[\s:|-]+\|?\s*$', lineas[i + 1])
                and '-' in lineas[i + 1]):
            bloque = [linea]
            j = i + 1
            while j < n and lineas[j].lstrip().startswith('|'):
                bloque.append(lineas[j])
                j += 1
            out.append(render_tabla(bloque, prefijo_recursos))
            i = j
            continue
        # regla horizontal
        if linea.strip() == '---':
            out.append('<hr>')
            i += 1
            continue
        # encabezados
        m = re.match(r'^(#{1,6})\s+(.*)$', linea)
        if m:
            nivel = len(m.group(1))
            txt = m.group(2).strip()
            ancla = slug(txt)
            indice_ancla = _estado_anclas['indice']
            if (anclas_canonicas is not None and
                    indice_ancla < len(anclas_canonicas)):
                ancla = anclas_canonicas[indice_ancla]
            if not ancla:
                ancla = 'seccion-%d' % (indice_ancla + 1)
            _estado_anclas['indice'] += 1
            out.append('<h%d id="%s">%s</h%d>'
                       % (nivel, ancla,
                          inline(txt, prefijo_recursos), nivel))
            i += 1
            continue
        # cita
        if linea.lstrip().startswith('>'):
            buf = []
            while i < n and lineas[i].lstrip().startswith('>'):
                buf.append(re.sub(r'^\s*>\s?', '', lineas[i]))
                i += 1
            out.append('<blockquote>%s</blockquote>'
                       % md_a_html(
                           '\n'.join(buf),
                           anclas_canonicas,
                           prefijo_recursos,
                           _estado_anclas
                       ))
            continue
        # listas ordenadas y no ordenadas, incluidas sus sublistas
        if PATRON_LISTA.match(linea):
            bloque, i = render_lista(lineas, i, prefijo_recursos)
            out.append(bloque)
            continue
        # linea en blanco
        if linea.strip() == '':
            i += 1
            continue
        # parrafo (acumula lineas contiguas)
        buf = [linea]
        i += 1
        while (i < n and lineas[i].strip() != ''
               and not lineas[i].startswith('#')
               and not lineas[i].startswith('```')
               and not lineas[i].lstrip().startswith('>')
               and not lineas[i].lstrip().startswith('|')
               and not re.match(r'^\s*[-*]\s+', lineas[i])
               and not re.match(r'^\s*\d+\.\s+', lineas[i])
               and lineas[i].strip() != '---'):
            buf.append(lineas[i])
            i += 1
        out.append(
            '<p>%s</p>' % inline('\n'.join(buf), prefijo_recursos)
        )
    return '\n'.join(out)


def nav(activo, idioma=IDIOMA_BASE):
    items = []
    for _, dst, etiqueta in ORDEN:
        etiqueta = ETIQUETAS_NAV.get(idioma, {}).get(dst, etiqueta)
        clase = ' class="activo"' if dst == activo else ''
        items.append(
            '<li%s><a href="%s">%s</a></li>'
            % (clase, dst, html.escape(etiqueta, quote=False))
        )
    return '<ul>%s</ul>' % ''.join(items)


def enlace_idioma(idioma_actual, idioma_destino, destino):
    """Ruta relativa a la misma pagina en otro idioma."""
    if idioma_actual == IDIOMA_BASE:
        if idioma_destino == IDIOMA_BASE:
            return destino
        return '%s/%s' % (idioma_destino, destino)
    if idioma_destino == idioma_actual:
        return destino
    if idioma_destino == IDIOMA_BASE:
        return '../%s' % destino
    return '../%s/%s' % (idioma_destino, destino)


def selector_idiomas(idioma_actual, destino):
    enlaces = []
    for idioma, abreviatura, nombre in IDIOMAS:
        clases = ['enlace-idioma']
        actual = ''
        if idioma == idioma_actual:
            clases.append('activo')
            actual = ' aria-current="page"'
        bandera = BANDERAS[idioma]
        if bandera:
            icono = (
                '<span class="bandera-emoji" aria-hidden="true">%s</span>'
                % bandera
            )
        else:
            icono = (
                '<span class="bandera bandera-ca" aria-hidden="true"></span>'
            )
        etiqueta = '%s (%s)' % (nombre, idioma)
        enlaces.append(
            '<a class="%s" href="%s" hreflang="%s" lang="%s" '
            'aria-label="%s" title="%s"%s>%s'
            '<span class="codigo-idioma">%s</span></a>'
            % (' '.join(clases),
               html.escape(
                   enlace_idioma(idioma_actual, idioma, destino),
                   quote=True
               ),
               idioma,
               idioma,
               html.escape(etiqueta, quote=True),
               html.escape(etiqueta, quote=True),
               actual,
               icono,
               abreviatura)
        )
    return (
        '<div class="selector-idiomas" role="navigation" '
        'aria-label="%s">%s</div>'
        % (html.escape(TEXTOS_UI[idioma_actual]['selector'], quote=True),
           ''.join(enlaces))
    )


def aviso_fallback(idioma):
    return (
        '<aside class="aviso-fallback" role="note" lang="%s">%s</aside>'
        % (idioma, TEXTOS_UI[idioma]['fallback'])
    )


PLANTILLA = """<!DOCTYPE html>
<html lang="{idioma}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{titulo} — {titulo_manual}</title>
<link rel="stylesheet" href="{prefijo_recursos}estilo.css?v={version_recursos}">
</head>
<body>
<button id="btnMenu" aria-label="{boton_menu}">☰</button>
<nav id="lateral">
<div class="marca">Factuzam<span>{marca}</span></div>
{selector_idiomas}
{nav}
</nav>
<main>
<article lang="{idioma_contenido}">
{aviso_fallback}
{contenido}
</article>
<footer>{pie}</footer>
</main>
<script>
var b=document.getElementById('btnMenu'),l=document.getElementById('lateral');
b.addEventListener('click',function(){{l.classList.toggle('abierto');}});
document.querySelectorAll('.enlace-idioma').forEach(function(a){{
 a.addEventListener('click',function(){{
  if(window.location.hash){{
   a.href=a.href.split('#')[0]+window.location.hash;
  }}
 }});
}});
</script>
</body>
</html>
"""

CSS = """:root{--azul:#1f6feb;--tinta:#1f2328;--gris:#57606a;--linea:#d0d7de;
--fondo:#ffffff;--lateral:#0d1117;--lateralTxt:#c9d1d9;--codigo:#f6f8fa;
--avisoBg:#fff8c5;--avisoBorde:#d4a72c;}
*{box-sizing:border-box;}
body{margin:0;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,
sans-serif;color:var(--tinta);background:var(--fondo);line-height:1.6;}
nav#lateral{position:fixed;top:0;left:0;width:280px;height:100vh;
background:var(--lateral);color:var(--lateralTxt);overflow-y:auto;padding:0;}
nav#lateral .marca{padding:22px 20px;font-size:20px;font-weight:700;
color:#fff;border-bottom:1px solid #21262d;}
nav#lateral .marca span{display:block;font-size:12px;font-weight:400;
color:#8b949e;margin-top:2px;}
.selector-idiomas{display:flex;align-items:center;gap:5px;padding:10px 12px;
border-bottom:1px solid #21262d;}
.selector-idiomas a{display:inline-flex;align-items:center;justify-content:center;
gap:3px;min-width:51px;padding:4px 5px;border:1px solid #30363d;
border-radius:6px;color:var(--lateralTxt);font-size:11px;line-height:1;
text-decoration:none;}
.selector-idiomas a:hover{background:#21262d;color:#fff;text-decoration:none;}
.selector-idiomas a.activo{background:var(--azul);border-color:var(--azul);
color:#fff;font-weight:700;}
.bandera-emoji{font-size:15px;line-height:1;}
.bandera{display:inline-block;width:18px;height:12px;border:1px solid #8b6b16;
border-radius:1px;}
.bandera-ca{background:repeating-linear-gradient(to bottom,
#f6d32d 0 11.111%,#c01c28 11.111% 22.222%);}
.codigo-idioma{line-height:12px;}
nav#lateral ul{list-style:none;margin:0;padding:10px 0;}
nav#lateral li a{display:block;padding:9px 20px;color:var(--lateralTxt);
text-decoration:none;font-size:14px;border-left:3px solid transparent;}
nav#lateral li a:hover{background:#161b22;color:#fff;}
nav#lateral li.activo a{background:#161b22;color:#fff;
border-left-color:var(--azul);font-weight:600;}
main{margin-left:280px;padding:40px 48px 80px;max-width:920px;}
article h1{font-size:30px;border-bottom:2px solid var(--linea);
padding-bottom:12px;margin-top:8px;}
article h2{font-size:23px;border-bottom:1px solid var(--linea);
padding-bottom:6px;margin-top:38px;}
article h3{font-size:18px;margin-top:30px;}
article h4{font-size:16px;margin-top:24px;color:var(--gris);}
a{color:var(--azul);text-decoration:none;}
a:hover{text-decoration:underline;}
code{background:var(--codigo);padding:2px 6px;border-radius:6px;
font-family:SFMono-Regular,Consolas,Liberation Mono,monospace;font-size:85%;}
pre{background:var(--codigo);padding:16px;border-radius:8px;overflow-x:auto;
border:1px solid var(--linea);}
pre code{background:none;padding:0;font-size:13px;line-height:1.45;}
table{border-collapse:collapse;width:100%;margin:18px 0;font-size:14px;}
th,td{border:1px solid var(--linea);padding:8px 12px;text-align:left;
vertical-align:top;}
th{background:var(--codigo);font-weight:600;}
tr:nth-child(even) td{background:#fafbfc;}
blockquote{margin:18px 0;padding:12px 18px;background:var(--avisoBg);
border-left:4px solid var(--avisoBorde);border-radius:0 8px 8px 0;}
blockquote p{margin:6px 0;}
.aviso-fallback{margin:0 0 24px;padding:12px 18px;background:var(--avisoBg);
border-left:4px solid var(--avisoBorde);border-radius:0 8px 8px 0;}
img{max-width:100%;border:1px solid var(--linea);border-radius:8px;
margin:14px 0;background:#fbfbfb;}
hr{border:none;border-top:1px solid var(--linea);margin:32px 0;}
ul,ol{padding-left:26px;}
li{margin:4px 0;}
footer{margin-top:60px;padding-top:20px;border-top:1px solid var(--linea);
color:var(--gris);font-size:13px;}
#btnMenu{display:none;position:fixed;top:12px;left:12px;z-index:20;
background:var(--lateral);color:#fff;border:none;border-radius:8px;
font-size:20px;width:42px;height:42px;cursor:pointer;}
@media(max-width:880px){
 nav#lateral{transform:translateX(-100%);transition:transform .2s;z-index:15;}
 nav#lateral.abierto{transform:translateX(0);}
 main{margin-left:0;padding:64px 20px 60px;}
 #btnMenu{display:block;}
}
"""

# Obliga al navegador a descargar los estilos cuando cambia el generador. Es
# especialmente importante al incorporar elementos nuevos, como el selector
# de idiomas, en equipos que ya habían abierto una versión anterior del manual.
VERSION_RECURSOS = hashlib.sha256(CSS.encode('utf-8')).hexdigest()[:12]


def leer_markdown(ruta):
    with open(ruta, encoding='utf-8') as fichero:
        return fichero.read()


def seleccionar_fuente(ruta_manual, idioma, nombre_md):
    """Elige el capitulo traducido o devuelve el espanol como fallback."""
    ruta_base = os.path.join(ruta_manual, nombre_md)
    if not os.path.isfile(ruta_base):
        raise FileNotFoundError(
            'Falta el capitulo base del manual: %s' % ruta_base
        )
    if idioma != IDIOMA_BASE:
        ruta_traducida = os.path.join(
            ruta_manual, 'i18n', idioma, nombre_md
        )
        if os.path.isfile(ruta_traducida):
            return ruta_traducida, False
    return ruta_base, idioma != IDIOMA_BASE


def copiar_recursos(ruta_manual, salida, copiar_imagenes=True):
    os.makedirs(salida, exist_ok=True)
    with open(
        os.path.join(salida, 'estilo.css'), 'w', encoding='utf-8'
    ) as fichero:
        fichero.write(CSS)
    if copiar_imagenes:
        img_src = os.path.join(ruta_manual, 'img')
        if os.path.isdir(img_src):
            import shutil
            img_dst = os.path.join(salida, 'img')
            os.makedirs(img_dst, exist_ok=True)
            for nombre in os.listdir(img_src):
                origen = os.path.join(img_src, nombre)
                if os.path.isfile(origen):
                    shutil.copy2(origen, os.path.join(img_dst, nombre))


def crear_pagina(texto, texto_base, destino, etiqueta, idioma, fallback,
                 fecha):
    prefijo_recursos = '' if idioma == IDIOMA_BASE else '../'
    textos_ui = TEXTOS_UI[idioma]
    if idioma != IDIOMA_BASE and not fallback:
        anclas = validar_estructura_traduccion(
            texto_base, texto, destino
        )
    else:
        anclas = [
            ancla for _, ancla in estructura_encabezados(texto_base)
        ]
    m = re.search(r'^#\s+(.*)$', texto, re.M)
    titulo = m.group(1).strip() if m else etiqueta
    contenido = md_a_html(texto, anclas, prefijo_recursos)
    idioma_contenido = IDIOMA_BASE if fallback else idioma
    return PLANTILLA.format(
        idioma=idioma,
        idioma_contenido=idioma_contenido,
        version_recursos=VERSION_RECURSOS,
        titulo=html.escape(titulo, quote=False),
        titulo_manual=html.escape(textos_ui['titulo'], quote=False),
        boton_menu=html.escape(textos_ui['boton_menu'], quote=True),
        marca=html.escape(textos_ui['marca'], quote=False),
        prefijo_recursos=prefijo_recursos,
        selector_idiomas=selector_idiomas(idioma, destino),
        nav=nav(destino, idioma),
        aviso_fallback=aviso_fallback(idioma) if fallback else '',
        contenido=contenido,
        pie=html.escape(
            textos_ui['pie'].format(fecha=fecha), quote=False
        )
    )


def generar_sitio(ruta_manual=AQUI, salida=SALIDA, fecha=None,
                   copiar_imagenes=True, mostrar_progreso=True):
    """Genera el sitio espanol y los tres arboles de idioma completos."""
    if fecha is None:
        fecha = datetime.date.today().strftime('%d/%m/%Y')
    copiar_recursos(ruta_manual, salida, copiar_imagenes)
    generados = []
    for idioma, _, _ in IDIOMAS:
        salida_idioma = (
            salida if idioma == IDIOMA_BASE
            else os.path.join(salida, idioma)
        )
        os.makedirs(salida_idioma, exist_ok=True)
        for nombre_md, destino, etiqueta in ORDEN:
            ruta_base = os.path.join(ruta_manual, nombre_md)
            texto_base = leer_markdown(ruta_base)
            ruta_fuente, fallback = seleccionar_fuente(
                ruta_manual, idioma, nombre_md
            )
            texto = (
                texto_base if ruta_fuente == ruta_base
                else leer_markdown(ruta_fuente)
            )
            pagina = crear_pagina(
                texto, texto_base, destino, etiqueta, idioma, fallback,
                fecha
            )
            ruta_destino = os.path.join(salida_idioma, destino)
            with open(ruta_destino, 'w', encoding='utf-8') as fichero:
                fichero.write(pagina)
            generados.append(ruta_destino)
            if mostrar_progreso:
                estado = ' (fallback es-ES)' if fallback else ''
                print(
                    '  [%s] %s -> %s%s'
                    % (idioma, nombre_md, ruta_destino, estado)
                )
    return generados


def main():
    generados = generar_sitio()
    print(
        'Listo: %d paginas (%d por idioma) en %s'
        % (len(generados), len(ORDEN), SALIDA)
    )


if __name__ == '__main__':
    main()
