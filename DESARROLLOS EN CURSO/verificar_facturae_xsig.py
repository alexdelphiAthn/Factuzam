from pathlib import Path
import sys

from lxml import etree
from signxml import XMLVerifier
from signxml.xades import XAdESVerifier


def certificado_pem(raiz):
    nodos = raiz.xpath('//*[local-name()="X509Certificate"]')
    if not nodos:
        raise RuntimeError("No se encontro ds:X509Certificate.")
    base64_cert = "".join((nodos[0].text or "").split())
    return (
        "-----BEGIN CERTIFICATE-----\n"
        + base64_cert
        + "\n-----END CERTIFICATE-----\n"
    )


def verificar(ruta):
    raiz = etree.parse(str(ruta)).getroot()
    cert = certificado_pem(raiz)
    XMLVerifier().verify(raiz, x509_cert=cert, require_x509=False)
    XAdESVerifier().verify(raiz, x509_cert=cert, require_x509=False)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python verificar_facturae_xsig.py fichero.xsig")
        sys.exit(2)
    fichero = Path(sys.argv[1])
    try:
        verificar(fichero)
    except Exception as exc:
        print("ERROR:", type(exc).__name__, str(exc))
        sys.exit(1)
    print("OK: firma XMLDSig/XAdES verificable localmente")
