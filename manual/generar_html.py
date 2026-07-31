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

Salida:
    manual/html/index.html  + un .html por cada capitulo + estilo.css
"""
import os
import re
import html
import datetime

AQUI = os.path.dirname(os.path.abspath(__file__))
SALIDA = os.path.join(AQUI, 'html')

# Orden de los capitulos en el menu lateral. El primero (README) es la
# portada y se publica como index.html.
ORDEN = [
    ('README.md', 'index.html', 'Inicio'),
    ('00-acceso-y-primeros-pasos.md', '00-acceso-y-primeros-pasos.html', '00 · Acceso y primeros pasos'),
    ('01-conceptos-comunes.md', '01-conceptos-comunes.html', '01 · Conceptos comunes'),
    ('02-menu-archivo.md', '02-menu-archivo.html', '02 · Menú Archivo'),
    ('03-menu-compras.md', '03-menu-compras.html', '03 · Menú Compras'),
    ('04-menu-ventas-mayor.md', '04-menu-ventas-mayor.html', '04 · Menú Ventas Mayor'),
    ('05-menu-caja.md', '05-menu-caja.html', '05 · Menú Caja'),
    ('06-menu-almacen.md', '06-menu-almacen.html', '06 · Menú Almacén'),
    ('07-menu-otros.md', '07-menu-otros.html', '07 · Menú Otros'),
    ('08-menu-ayuda.md', '08-menu-ayuda.html', '08 · Menú Ayuda'),
    ('09-instalacion-windows.md', '09-instalacion-windows.html', '09 · Instalación en Windows'),
    ('10-migracion-legacy.md', '10-migracion-legacy.html', '10 · Migración desde legacy'),
    ('11-verifactu.md', '11-verifactu.html', '11 · Verifactu (AEAT)'),
    ('12-cambios-y-novedades.md', '12-cambios-y-novedades.html', '12 · Cambios y novedades'),
    ('13-aplicaciones-moviles.md', '13-aplicaciones-moviles.html', '13 · Aplicaciones móviles'),
    ('14-arquitectura-y-desarrollo.md', '14-arquitectura-y-desarrollo.html', '14 · Arquitectura y desarrollo'),
]
MD2HTML = {md: dst for md, dst, _ in ORDEN}


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


def corregir_enlace(destino):
    """Reescribe enlaces .md -> .html conservando el ancla."""
    ancla = ''
    if '#' in destino:
        destino, ancla = destino.split('#', 1)
        ancla = '#' + ancla
    if destino in MD2HTML:
        destino = MD2HTML[destino]
    return destino + ancla


def inline(texto):
    """Formato en linea: codigo, imagenes, enlaces, negrita, cursiva."""
    texto = html.escape(texto, quote=False)
    codigos = []

    def guarda_codigo(m):
        codigos.append(m.group(1))
        return '\x00%d\x00' % (len(codigos) - 1)

    texto = re.sub(r'`([^`]+)`', guarda_codigo, texto)
    # imagenes ![alt](src)
    texto = re.sub(
        r'!\[([^\]]*)\]\(([^)]+)\)',
        lambda m: '<img src="%s" alt="%s" loading="lazy">'
                  % (html.escape(m.group(2), quote=True), m.group(1)),
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
    # restaurar codigo
    texto = re.sub(r'\x00(\d+)\x00',
                   lambda m: '<code>%s</code>'
                             % html.escape(codigos[int(m.group(1))], quote=False),
                   texto)
    return texto


def render_tabla(filas):
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
    out += ['<th>%s</th>' % inline(c) for c in cabecera]
    out += ['</tr></thead>', '<tbody>']
    for fila in cuerpo:
        out.append('<tr>' + ''.join('<td>%s</td>' % inline(c) for c in fila)
                   + '</tr>')
    out += ['</tbody>', '</table>']
    return '\n'.join(out)


def md_a_html(texto):
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
            out.append(render_tabla(bloque))
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
            out.append('<h%d id="%s">%s</h%d>'
                       % (nivel, ancla, inline(txt), nivel))
            i += 1
            continue
        # cita
        if linea.lstrip().startswith('>'):
            buf = []
            while i < n and lineas[i].lstrip().startswith('>'):
                buf.append(re.sub(r'^\s*>\s?', '', lineas[i]))
                i += 1
            out.append('<blockquote>%s</blockquote>'
                       % md_a_html('\n'.join(buf)))
            continue
        # lista no ordenada
        if re.match(r'^\s*[-*]\s+', linea):
            buf = []
            while i < n and re.match(r'^\s*[-*]\s+', lineas[i]):
                partes = [re.sub(r'^\s*[-*]\s+', '', lineas[i]).strip()]
                i += 1
                while (i < n and re.match(r'^\s{2,}\S', lineas[i])
                       and not re.match(r'^\s*[-*]\s+', lineas[i])
                       and not re.match(r'^\s*\d+\.\s+', lineas[i])):
                    partes.append(lineas[i].strip())
                    i += 1
                buf.append(' '.join(partes))
            out.append('<ul>%s</ul>'
                       % ''.join('<li>%s</li>' % inline(x) for x in buf))
            continue
        # lista ordenada
        if re.match(r'^\s*\d+\.\s+', linea):
            buf = []
            while i < n and re.match(r'^\s*\d+\.\s+', lineas[i]):
                partes = [re.sub(r'^\s*\d+\.\s+', '', lineas[i]).strip()]
                i += 1
                while (i < n and re.match(r'^\s{2,}\S', lineas[i])
                       and not re.match(r'^\s*[-*]\s+', lineas[i])
                       and not re.match(r'^\s*\d+\.\s+', lineas[i])):
                    partes.append(lineas[i].strip())
                    i += 1
                buf.append(' '.join(partes))
            out.append('<ol>%s</ol>'
                       % ''.join('<li>%s</li>' % inline(x) for x in buf))
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
        out.append('<p>%s</p>' % inline('\n'.join(buf)))
    return '\n'.join(out)


def nav(activo):
    items = []
    for _, dst, etiqueta in ORDEN:
        clase = ' class="activo"' if dst == activo else ''
        items.append('<li%s><a href="%s">%s</a></li>' % (clase, dst, etiqueta))
    return '<ul>%s</ul>' % ''.join(items)


PLANTILLA = """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{titulo} — Manual de Factuzam</title>
<link rel="stylesheet" href="estilo.css">
</head>
<body>
<button id="btnMenu" aria-label="Menú">☰</button>
<nav id="lateral">
<div class="marca">Factuzam<span>Manual de usuario</span></div>
{nav}
</nav>
<main>
<article>
{contenido}
</article>
<footer>Manual de Factuzam · generado el {fecha}</footer>
</main>
<script>
var b=document.getElementById('btnMenu'),l=document.getElementById('lateral');
b.addEventListener('click',function(){{l.classList.toggle('abierto');}});
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


def main():
    os.makedirs(SALIDA, exist_ok=True)
    fecha = datetime.date.today().strftime('%d/%m/%Y')
    with open(os.path.join(SALIDA, 'estilo.css'), 'w', encoding='utf-8') as f:
        f.write(CSS)
    # copiar imagenes si existen
    img_src = os.path.join(AQUI, 'img')
    if os.path.isdir(img_src):
        img_dst = os.path.join(SALIDA, 'img')
        os.makedirs(img_dst, exist_ok=True)
        import shutil
        for fn in os.listdir(img_src):
            shutil.copy2(os.path.join(img_src, fn), os.path.join(img_dst, fn))
    generados = 0
    for md, dst, etiqueta in ORDEN:
        ruta = os.path.join(AQUI, md)
        if not os.path.exists(ruta):
            print('  (omitido, no existe) %s' % md)
            continue
        with open(ruta, encoding='utf-8') as f:
            texto = f.read()
        m = re.search(r'^#\s+(.*)$', texto, re.M)
        titulo = m.group(1).strip() if m else etiqueta
        contenido = md_a_html(texto)
        pagina = PLANTILLA.format(titulo=html.escape(titulo, quote=False),
                                  nav=nav(dst), contenido=contenido,
                                  fecha=fecha)
        with open(os.path.join(SALIDA, dst), 'w', encoding='utf-8') as f:
            f.write(pagina)
        generados += 1
        print('  %s -> html/%s' % (md, dst))
    print('Listo: %d paginas en %s' % (generados, SALIDA))


if __name__ == '__main__':
    main()
