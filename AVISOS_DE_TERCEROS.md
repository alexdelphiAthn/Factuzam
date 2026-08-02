# Avisos de terceros

Factuzam combina código propio con componentes externos. La licencia
MPL-2.0 del proyecto no sustituye ni amplía los derechos concedidos por las
licencias de esos componentes.

## Dependencias comerciales

La compilación completa puede requerir licencias válidas de:

- Embarcadero Delphi y VCL;
- DevExpress VCL;
- Devart UniDAC;
- FastReport VCL.

También se utilizan componentes de la familia JEDI. Cada dependencia conserva
su licencia y sus condiciones. Los desarrolladores deben obtener sus propias
licencias cuando corresponda. No se debe publicar código fuente, paquetes de
diseño, claves de licencia ni otros archivos de un proveedor comercial salvo
autorización expresa de su contrato.

## Código externo incluido en el árbol

Se han identificado, al menos, los siguientes componentes:

- DCPcrypt, en `src/3rdpartyComp/DCPCrypt-master/`: MIT, según su
  `Readme.txt`.
- SQLBuilder4Delphi, en `src/3rdpartyComp/SQLBuilder4Delphi/`:
  Apache-2.0, según su `LICENSE`.
- SynEdit, en `src/3rdpartyComp/SynEdit/`: MPL-1.1 o GPL, según las
  cabeceras de sus archivos.
- SynPDF/Synopse, en `src/3rdpartyComp/SynPDF/`: licencia triple
  MPL-1.1/GPL-2.0/LGPL-2.1, según sus cabeceras.
- DelphiZXingQRCode, en `src/Lib3par/DelphiZXIngQRCode.pas`: Apache-2.0,
  según su cabecera.
- El formateador SQL, en `src/Lib/sqlformatter/`: Apache-2.0, según sus
  cabeceras.
- Las utilidades SEPA, en `src/Lib3par/uDJMSepa*.pas`: los archivos indican
  su autor y origen, pero queda pendiente confirmar su licencia de
  redistribución.

Los archivos de `src/vcl/` y `src/vcl37/` proceden o derivan de unidades de la
biblioteca VCL. Sus derechos de redistribución deben comprobarse con la
licencia de Embarcadero antes de publicar una distribución del código fuente.
No se consideran código MPL-2.0 de Factuzam.

El archivo `src/Lib/IDETheme.ActnCtrls.pas` referencia material publicado en
Embarcadero CodeCentral. Debe verificarse su licencia original antes de
redistribuirlo.

## Comprobación previa a una publicación

Antes de publicar una versión del repositorio se debe:

1. conservar todas las cabeceras y archivos de licencia de terceros;
2. confirmar los derechos de los archivos cuya licencia no esté indicada;
3. excluir fuentes y paquetes propietarios que no sean redistribuibles;
4. excluir claves, certificados, credenciales y datos de instalaciones;
5. revisar las condiciones de los redistribuibles incluidos en el ejecutable.
