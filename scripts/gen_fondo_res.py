#!/usr/bin/env python3
"""Genera fondo.res con un recurso RCDATA llamado 'FONDO' a partir de fondo.png.

Formato .res (Win32 PE resource file):
  Cada entrada = RESOURCEHEADER (Pascal-aligned) + data + padding a DWORD.
  El primer entry es uno vacio (size=0, headersize=32, type=0, name=0).

RESOURCEHEADER:
  DWORD DataSize
  DWORD HeaderSize
  Unicode/Ordinal Type   (0xFFFF + WORD si ordinal)
  Unicode/Ordinal Name   (0xFFFF + WORD si ordinal, o string Unicode null-term)
  padding a DWORD
  DWORD DataVersion
  WORD  MemoryFlags
  WORD  LanguageId
  DWORD Version
  DWORD Characteristics
"""
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PNG_PATH = os.path.join(ROOT, 'fondo.png')
RES_PATH = os.path.join(ROOT, 'fondo.res')

RT_RCDATA = 10
RESOURCE_NAME = 'FONDO'
LANG_NEUTRAL = 0x0000


def align_dword(buf: bytearray) -> None:
    while len(buf) % 4 != 0:
        buf.append(0)


def ordinal(n: int) -> bytes:
    return struct.pack('<HH', 0xFFFF, n)


def unicode_name(s: str) -> bytes:
    return s.encode('utf-16-le') + b'\x00\x00'


def build_entry(rtype: int, name: str, data: bytes) -> bytes:
    type_bytes = ordinal(rtype)
    name_bytes = unicode_name(name)

    header_body = bytearray()
    header_body += type_bytes
    header_body += name_bytes
    align_dword(header_body)
    header_body += struct.pack('<I', 0)            # DataVersion
    header_body += struct.pack('<H', 0x0030)       # MemoryFlags: MOVEABLE|PURE
    header_body += struct.pack('<H', LANG_NEUTRAL) # LanguageId
    header_body += struct.pack('<I', 0)            # Version
    header_body += struct.pack('<I', 0)            # Characteristics

    header_size = 8 + len(header_body)  # +8 for DataSize+HeaderSize themselves

    out = bytearray()
    out += struct.pack('<II', len(data), header_size)
    out += header_body
    out += data
    align_dword(out)
    return bytes(out)


def build_empty_entry() -> bytes:
    """Entrada de header vacia que debe ir primero en cada .res."""
    body = bytearray()
    body += struct.pack('<II', 0, 32)              # DataSize=0, HeaderSize=32
    body += ordinal(0)                             # Type ordinal 0
    body += ordinal(0)                             # Name ordinal 0
    body += struct.pack('<I', 0)                   # DataVersion
    body += struct.pack('<H', 0)                   # MemoryFlags
    body += struct.pack('<H', 0)                   # LanguageId
    body += struct.pack('<I', 0)                   # Version
    body += struct.pack('<I', 0)                   # Characteristics
    return bytes(body)


def main() -> int:
    if not os.path.exists(PNG_PATH):
        print(f'No existe {PNG_PATH}', file=sys.stderr)
        return 1
    with open(PNG_PATH, 'rb') as f:
        png_data = f.read()
    res_bytes = build_empty_entry() + build_entry(RT_RCDATA, RESOURCE_NAME,
                                                  png_data)
    with open(RES_PATH, 'wb') as f:
        f.write(res_bytes)
    print(f'Generado {RES_PATH} ({len(res_bytes)} bytes, '
          f'PNG embebido {len(png_data)} bytes)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
