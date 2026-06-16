# Publicacion de librerias fiscales en GitHub

## Objetivo

Publicar en una cuenta de GitHub un conjunto reutilizable de librerias Delphi
para:

- Firma XML XAdES con certificado del almacen de Windows.
- Facturae 3.2.2 firmada.
- Registros Verifactu y NO VERI*FACTU.
- Exportacion y verificacion local de libros NO VERI*FACTU.
- Validacion auxiliar de NIF/NIE/CIF y control de reloj fiscal.

La base existe en Factuzam, pero no conviene publicar los ficheros tal cual sin
separar nucleo fiscal y adaptadores de producto. Hay unidades que dependen de
UniDAC, FastReport, parametros internos, tablas `fza_*` y variables globales de
Factuzam. En el repositorio publico esas dependencias deben quedar fuera o en
una carpeta `adapters/factuzam`.

## Seleccion de ficheros

### Publicables casi directos

| Uso | Fichero actual | Nombre publico recomendado | Ajuste necesario |
|-----|----------------|----------------------------|------------------|
| Firma XAdES | `src/Lib/inLibXades.pas` | `src/Fiscal.Xades.pas` | Cambiar cabecera/licencia y nombre de `unit`. No depende de Factuzam. |
| NIF/NIE/CIF | `src/Lib/inLibDocumentoFiscal.pas` | `src/Fiscal.DocumentoFiscal.pas` | Cambiar cabecera/licencia y nombre de `unit`. |
| Ejemplo NO VERI*FACTU AEAT | `DESARROLLOS EN CURSO/ejnoverifactu/*.xml` | `examples/noverifactu-aeat/` | Mantener como ejemplos tecnicos; no modificar XML firmado si se usa para contraste. |

`inLibXades.pas` usa API criptografica de Windows, CAPI/CNG y almacen personal
`MY`. No necesita CryptoLib4Pascal, OpenSSL, `.ps1` ni procesos externos.

### Publicables tras refactor pequeno

| Uso | Fichero actual | Nombre publico recomendado | Cambio necesario |
|-----|----------------|----------------------------|------------------|
| Reloj fiscal NTP | `src/Lib/inLibRelojFiscal.pas` | `src/Fiscal.RelojFiscal.pas` | Quitar `inLibAppParam`; recibir servidores, margen y timeout por record. Depende de Indy `IdSNTP`. |
| Verificador NO VERI*FACTU | `src/Lib/inLibVerifactuNoVerifactuVerify.pas` | `src/Fiscal.NoVerifactu.Verify.pas` | Quitar `inLibVerifactu`; pasar el modo esperado como parametro (`SIN` / `NO_VERIFACTU`). |
| QR Verifactu | parte de `src/verifactu/inLibVerifactu.pas` | `src/Fiscal.Verifactu.QR.pas` | Extraer solo `ConstruirUrlQR`, formato de importe/NIF y PNG QR. Sacar FastReport a otro adaptador. |

Si se incluye `src/Lib3par/DelphiZXIngQRCode.pas`, conservar su licencia
Apache 2.0 en `NOTICE` o en una carpeta `third_party`.

### Publicables tras refactor medio

| Uso | Fichero actual | Nombre publico recomendado | Cambio necesario |
|-----|----------------|----------------------------|------------------|
| Facturae | `src/Lib/inLibFacturae.pas` | `src/Fiscal.Facturae.pas` | La API publica no debe recibir `TUniConnection`; debe recibir records de factura, emisor, receptor y lineas. |
| Export NO VERI*FACTU | `src/Lib/inLibVerifactuNoVerifactuExport.pas` | `src/Fiscal.NoVerifactu.Export.pas` | La API publica no debe leer tablas `fza_*`; debe recibir colecciones de registros ya firmados. |
| Eventos NO VERI*FACTU | parte de `src/verifactu/inLibVerifactu.pas` | `src/Fiscal.NoVerifactu.Eventos.pas` | Extraer `ConstruirXmlEventoSif` y firma de evento; quitar BBDD, FastReport y parametros globales. |

### Publicables tras refactor grande

| Uso | Fichero actual | Nombre publico recomendado | Cambio necesario |
|-----|----------------|----------------------------|------------------|
| Registro alta/anulacion Verifactu | `src/verifactu/inLibVerifactuEnvio.pas` | `src/Fiscal.Verifactu.Registros.pas` | Extraer tipos publicos de factura y cadena; publicar builders XML sin UniDAC. |
| Cliente SOAP AEAT | `src/verifactu/inLibVerifactuEnvio.pas` | `src/Fiscal.Verifactu.ClienteAeat.pas` | Separar envio HTTP/SOAP y seleccion de certificado TLS. No mezclar con lectura de factura. |
| Integracion Factuzam | `src/verifactu/inLibVerifactuCola.pas`, pantallas y data modules | `adapters/factuzam/` o no publicar | Solo como ejemplo de integracion, no como libreria generica. |

## Ficheros que no conviene publicar

No incluir en el repositorio publico:

- `factuzam_original.sql`.
- Ficheros `.dfm`, formularios, data modules y pantallas de Factuzam.
- `src/verifactu/UniData*.pas/.dfm`.
- `src/verifactu/inMto*.pas/.dfm`.
- `src/Lib/inLibGlobalVar.pas`, `inLibAppParam.pas`, `inLibFotos.pas`.
- XML reales generados con NIF, certificados o datos de clientes reales.
- Capturas, logs, informes de error o ficheros `.xsig` reales.
- Librerias de terceros sin revisar licencia y atribucion.

## Estructura recomendada del repo publico

```text
factuzam-fiscal-delphi/
├── LICENSE
├── NOTICE
├── README.md
├── docs/
│   ├── facturae.md
│   ├── verifactu.md
│   ├── noverifactu.md
│   └── xades.md
├── src/
│   ├── Fiscal.Xades.pas
│   ├── Fiscal.DocumentoFiscal.pas
│   ├── Fiscal.RelojFiscal.pas
│   ├── Fiscal.Facturae.Types.pas
│   ├── Fiscal.Facturae.pas
│   ├── Fiscal.Verifactu.Types.pas
│   ├── Fiscal.Verifactu.QR.pas
│   ├── Fiscal.Verifactu.Registros.pas
│   ├── Fiscal.Verifactu.ClienteAeat.pas
│   ├── Fiscal.NoVerifactu.Eventos.pas
│   ├── Fiscal.NoVerifactu.Export.pas
│   └── Fiscal.NoVerifactu.Verify.pas
├── adapters/
│   └── factuzam/
│       ├── Factuzam.Facturae.Adapter.pas
│       └── Factuzam.Verifactu.Adapter.pas
├── examples/
│   ├── 01-xades/
│   ├── 02-facturae/
│   ├── 03-verifactu-registro/
│   ├── 04-noverifactu-export/
│   └── 05-noverifactu-verify/
└── tests/
```

La licencia natural es MPL-2.0, porque es la licencia raiz actual del
repositorio. Las cabeceras de los `.pas` publicos deberian dejar de decir
`Todos los derechos reservados` sin mas contexto y anadir una nota clara:

```text
SPDX-License-Identifier: MPL-2.0
```

## API publica recomendada

La regla principal es que el nucleo no dependa de BBDD. La aplicacion que use
la libreria debe construir records y decidir donde persistir.

Tipos recomendados:

```pascal
type
  TFiscalCertificado = record
    NumeroSerie: string;
    Titular: string;
  end;

  TFiscalParte = record
    Nif: string;
    Nombre: string;
    Direccion: string;
    CodigoPostal: string;
    Poblacion: string;
    Provincia: string;
    PaisIso2: string;
    PaisFacturae: string;
  end;

  TFiscalLineaFactura = record
    Descripcion: string;
    Cantidad: Double;
    PrecioUnitario: Double;
    Base: Double;
    TipoIva: Double;
    CuotaIva: Double;
    TipoRecargo: Double;
    CuotaRecargo: Double;
  end;

  TNoVerifactuModo = (nvmSinVerifactu, nvmNoVerifactu);
```

Adaptadores recomendados:

```pascal
function FacturaFactuzamARegistroVerifactu(...): TRegistroVerifactu;
function FacturaFactuzamAFacturae(...): TFacturaeFactura;
```

Asi el repo publico es reutilizable por cualquier ERP y Factuzam conserva su
adaptador propio.

## Ejemplo 1: firmar XML con XAdES

Uso actual de la unidad `inLibXades.pas`, equivalente a la futura
`Fiscal.Xades.pas`:

```pascal
uses
  System.SysUtils, System.IOUtils, inLibXades;

procedure FirmarXmlFacturae;
var
  oOpciones: TXadesOpciones;
  oDatosCert: TXadesDatosCertificado;
  sXmlBase: string;
  sXmlFirmado: string;
begin
  sXmlBase := TFile.ReadAllText('factura_sin_firma.xml', TEncoding.UTF8);
  oOpciones := OpcionesXadesFacturae('EDOC-2026-A1-000005');
  oOpciones.RolFirmante := 'emisor';
  sXmlFirmado := FirmarXmlXadesEnveloped(
    sXmlBase,
    'SERIE_CERTIFICADO_WINDOWS',
    'TITULAR O CN DEL CERTIFICADO',
    oOpciones,
    oDatosCert);
  TFile.WriteAllText('factura_firmada.xsig', sXmlFirmado, TEncoding.UTF8);
end;
```

Para NO VERI*FACTU cambia solo la politica:

```pascal
oOpciones := OpcionesXadesNoVerifactu('FZ-FACTURA-' + sHuella);
```

## Ejemplo 2: generar Facturae

Uso actual dentro de Factuzam:

```pascal
uses
  inLibFacturae;

procedure EmitirEDocFactura;
var
  oResultado: TFacturaeResultado;
begin
  oResultado := EmitirFacturae(
    oConn,
    '2026.A1',
    '000005',
    'C:\Temp\eDoc_2026_A1_000005.xsig');
end;
```

Uso recomendado para el repo publico:

```pascal
uses
  Fiscal.Facturae, Fiscal.Xades;

procedure EmitirFacturaePortable;
var
  oFactura: TFacturaeFactura;
  oCertificado: TFiscalCertificado;
  oDatosCert: TXadesDatosCertificado;
  oOpciones: TXadesOpciones;
  sXmlBase: string;
  sXmlFirmado: string;
begin
  oFactura.Version := '3.2.2';
  oFactura.Serie := '2026.A1';
  oFactura.Numero := '000005';
  oFactura.FechaExpedicion := EncodeDate(2026, 2, 26);
  oFactura.Emisor.Nif := 'A00000000';
  oFactura.Emisor.Nombre := 'EMPRESA DEMO SL';
  oFactura.Receptor.Nif := 'P0700000A';
  oFactura.Receptor.Nombre := 'AYUNTAMIENTO DEMO';
  oFactura.OficinaContable := 'L01070184';
  oFactura.OrganoGestor := 'L01070184';
  oFactura.UnidadTramitadora := 'L01070184';
  oFactura.FormaPagoFacturae := '01';
  oFactura.FechaVencimiento := oFactura.FechaExpedicion;
  oFactura.Lineas.Add(LineaFacturaeDemo);
  sXmlBase := ConstruirXmlFacturae(oFactura);
  oOpciones := OpcionesXadesFacturae('EDOC-' + oFactura.Serie + '-' +
    oFactura.Numero);
  oOpciones.RolFirmante := 'emisor';
  sXmlFirmado := FirmarXmlXadesEnveloped(
    sXmlBase,
    oCertificado.NumeroSerie,
    oCertificado.Titular,
    oOpciones,
    oDatosCert);
  GuardarFacturaeFirmada(sXmlFirmado);
end;
```

## Ejemplo 3: generar registro Verifactu / NO VERI*FACTU

Uso actual dentro de Factuzam:

```pascal
uses
  inLibVerifactuEnvio;

procedure GenerarRegistroLocalNoVerifactu;
var
  oResultado: TResultadoEnvioVerifactu;
begin
  oResultado := GenerarRegistroFacturaLocal(
    oConn,
    '2026.A1',
    '000005',
    'ALTA');
  GuardarRegistroFiscal(oResultado.RegistroXmlFirmado,
    oResultado.ChainHash,
    oResultado.FirmaDigital);
end;
```

Uso recomendado para el repo publico:

```pascal
uses
  Fiscal.Verifactu.Registros, Fiscal.Xades;

procedure GenerarAltaNoVerifactuPortable;
var
  oFactura: TRegistroFacturaVerifactu;
  oCadena: TCadenaVerifactuAnterior;
  oDatosCert: TXadesDatosCertificado;
  oOpciones: TXadesOpciones;
  sRegistro: string;
  sRegistroFirmado: string;
  sHuella: string;
begin
  oFactura.NifEmisor := 'A00000000';
  oFactura.NombreEmisor := 'EMPRESA DEMO SL';
  oFactura.Serie := '2026.A1';
  oFactura.Numero := '000005';
  oFactura.FechaExpedicion := EncodeDate(2026, 2, 26);
  oFactura.TipoFactura := 'F1';
  oFactura.DescripcionOperacion := 'Venta demo';
  oFactura.CuotaTotal := 36.54;
  oFactura.ImporteTotal := 210.54;
  oFactura.BandasIva.Add(BandaIvaDemo);
  oCadena.EsPrimero := True;
  sRegistro := ConstruirRegistroAltaVerifactu(oFactura, oCadena, sHuella);
  oOpciones := OpcionesXadesNoVerifactu('FZ-FACTURA-' + sHuella);
  sRegistroFirmado := FirmarXmlXadesEnveloped(
    sRegistro,
    'SERIE_CERTIFICADO_WINDOWS',
    'TITULAR O CN DEL CERTIFICADO',
    oOpciones,
    oDatosCert);
  GuardarRegistroNoVerifactu(sRegistroFirmado, sHuella, oDatosCert);
end;
```

En modo Verifactu online, el mismo `sRegistro` se envuelve en SOAP y se envia
al endpoint AEAT. En modo NO VERI*FACTU, el registro se firma y se conserva en
local al crear la factura.

## Ejemplo 4: registrar evento NO VERI*FACTU

Uso actual dentro de Factuzam:

```pascal
uses
  inLibVerifactu;

procedure RegistrarCambioConfiguracionFiscal;
begin
  RegistrarEventoVerifactu(
    oConn,
    cEventoNoVerifactuCambioConfig,
    'Cambio de configuracion Verifactu',
    'PARAMETRO=appVerifactuModo');
end;
```

Uso recomendado para el repo publico:

```pascal
uses
  Fiscal.NoVerifactu.Eventos, Fiscal.Xades;

procedure RegistrarEventoPortable;
var
  oEvento: TEventoNoVerifactu;
  oAnterior: TEventoNoVerifactuAnterior;
  oDatosCert: TXadesDatosCertificado;
  oOpciones: TXadesOpciones;
  sXml: string;
  sXmlFirmado: string;
  sHuella: string;
begin
  oEvento.TipoEvento := nveCambioConfiguracion;
  oEvento.FechaHoraHuso := NowConHusoHorario;
  oEvento.Descripcion := 'Cambio de configuracion Verifactu';
  oEvento.NifObligado := 'A00000000';
  oEvento.NombreObligado := 'EMPRESA DEMO SL';
  sXml := ConstruirXmlEventoNoVerifactu(oEvento, oAnterior, sHuella);
  oOpciones := OpcionesXadesNoVerifactu('FZ-EVENTO-' + sHuella);
  oOpciones.NombreNodoInsercionFirma := 'sf:Evento';
  sXmlFirmado := FirmarXmlXadesEnveloped(
    sXml,
    'SERIE_CERTIFICADO_WINDOWS',
    'TITULAR O CN DEL CERTIFICADO',
    oOpciones,
    oDatosCert);
  GuardarEventoNoVerifactu(sXmlFirmado, sHuella, oDatosCert);
end;
```

## Ejemplo 5: exportar libros NO VERI*FACTU

Uso actual dentro de Factuzam:

```pascal
uses
  inLibVerifactuNoVerifactuExport;

procedure ExportarLibrosNoVerifactu;
var
  oResultado: TResultadoExportacionNoVerifactu;
begin
  oResultado := ExportarRegistrosNoVerifactu(
    oConn,
    'C:\Temp\NoVerifactu_20260616_055119.xml');
end;
```

Uso recomendado para el repo publico:

```pascal
uses
  Fiscal.NoVerifactu.Export;

procedure ExportarLibrosPortable;
var
  oLibro: TNoVerifactuLibro;
  oResultado: TNoVerifactuExportResultado;
begin
  oLibro.Modo := nvmNoVerifactu;
  oLibro.Eventos.Add(EventoFirmadoYaPersistido);
  oLibro.RegistrosFacturacion.Add(RegistroFirmadoYaPersistido);
  oResultado := ExportarNoVerifactu(
    oLibro,
    'C:\Temp\NoVerifactu_20260616_055119');
end;
```

La exportacion no debe firmar el contenedor final. Debe empaquetar registros y
eventos que ya fueron firmados cuando se crearon.

## Ejemplo 6: verificar libros NO VERI*FACTU

Uso actual dentro de Factuzam:

```pascal
uses
  System.IOUtils, inLibVerifactuNoVerifactuVerify;

procedure VerificarLibrosNoVerifactu;
var
  oResultado: TResultadoVerificacionNoVerifactu;
  sEventos: string;
  sFacturacion: string;
  sInforme: string;
begin
  InferirFicherosNoVerifactu(
    'C:\Temp\NoVerifactu_20260616_055119_eventos.xml',
    sEventos,
    sFacturacion);
  oResultado := VerificarFicherosNoVerifactu(sEventos, sFacturacion);
  sInforme := NombreInformeErroresNoVerifactu(sEventos);
  TFile.WriteAllText(sInforme,
    ResumenVerificacionNoVerifactu(oResultado) + sLineBreak +
    oResultado.Detalle,
    TEncoding.UTF8);
end;
```

Uso recomendado para el repo publico:

```pascal
uses
  Fiscal.NoVerifactu.Verify;

procedure VerificarLibrosPortable;
var
  oOpciones: TNoVerifactuVerifyOptions;
  oResultado: TNoVerifactuVerifyResult;
begin
  oOpciones.ModoEsperado := nvmNoVerifactu;
  oOpciones.ExigirXadesLegal := True;
  oResultado := VerificarFicherosNoVerifactu(
    'C:\Temp\NoVerifactu_20260616_055119_eventos.xml',
    'C:\Temp\NoVerifactu_20260616_055119_facturacion.xml',
    oOpciones);
end;
```

## Ejemplo 7: comprobar reloj fiscal

Uso actual dentro de Factuzam:

```pascal
uses
  inLibRelojFiscal;

procedure AntesDeCrearRegistroFiscal;
begin
  ExigirRelojFiscal('Alta de factura NO VERI*FACTU');
end;
```

Uso recomendado para el repo publico:

```pascal
uses
  Fiscal.RelojFiscal;

procedure ComprobarRelojPortable;
var
  oOpciones: TRelojFiscalOpciones;
  oResultado: TResultadoRelojFiscal;
begin
  oOpciones.Servidores := 'time.google.com,time.windows.com,pool.ntp.org';
  oOpciones.MargenSegundos := 60;
  oOpciones.TimeoutMs := 1500;
  if not ComprobarRelojFiscal(oOpciones, oResultado) then
    raise Exception.Create(oResultado.Mensaje);
end;
```

## Prioridad de publicacion

1. Publicar primero `Fiscal.Xades`, `Fiscal.DocumentoFiscal` y un ejemplo de
   Facturae firmado. Es lo mas reutilizable y con menos acoplamiento.
2. Despues publicar `Fiscal.NoVerifactu.Verify`, porque permite comprobar
   ficheros sin depender de BBDD.
3. Despues publicar `Fiscal.Facturae` con API por records.
4. Despues publicar `Fiscal.NoVerifactu.Export` y eventos.
5. Dejar Verifactu SOAP para el final: es la parte con mas acoplamiento a
   cadena, BBDD, certificado TLS y respuesta AEAT.

## Checklist antes de subir a GitHub

- Cambiar nombres de unidad a nombres neutros (`Fiscal.*`).
- Quitar dependencias de `Uni`, `DBAccess`, `inLibGlobalVar`,
  `inLibAppParam`, `frxClass`, pantallas y tablas `fza_*` del nucleo.
- Anadir `README.md` con aviso de que no sustituye asesoramiento fiscal ni
  validacion oficial.
- Anadir `LICENSE` MPL-2.0 y `NOTICE` para terceros.
- No publicar certificados, XML reales, NIF reales ni informes de clientes.
- Anadir ejemplos con datos ficticios y certificados de prueba.
- Anadir tests con XML oficiales o sinteticos.
- Mantener `.pas` en UTF-8 con BOM y CRLF si se quiere seguir el estilo
  Delphi usado en Factuzam.
