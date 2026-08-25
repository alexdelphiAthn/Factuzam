"""Lectura mínima de credenciales genéricas del almacén seguro de Windows."""

from __future__ import annotations

import os


class CredentialStoreError(RuntimeError):
    """La credencial no existe o no puede leerse de forma segura."""


def read_windows_generic_credential(target: str) -> str:
    """Devuelve el secreto de una credencial genérica sin registrarlo.

    El módulo importa la API Win32 de forma perezosa para que el paquete siga
    siendo importable en otros sistemas. La contraseña nunca forma parte de
    mensajes de error ni de la representación de la configuración.
    """

    target = target.strip()
    if (
        not target
        or len(target) > 512
        or any(ord(character) < 32 or ord(character) == 127 for character in target)
    ):
        raise CredentialStoreError("La referencia de credencial no es válida.")
    if os.name != "nt":
        raise CredentialStoreError(
            "El almacén de credenciales de Windows solo está disponible en Windows."
        )

    import ctypes
    from ctypes import wintypes

    class FileTime(ctypes.Structure):
        _fields_ = [
            ("low", wintypes.DWORD),
            ("high", wintypes.DWORD),
        ]

    class Credential(ctypes.Structure):
        _fields_ = [
            ("flags", wintypes.DWORD),
            ("type", wintypes.DWORD),
            ("target_name", wintypes.LPWSTR),
            ("comment", wintypes.LPWSTR),
            ("last_written", FileTime),
            ("blob_size", wintypes.DWORD),
            ("blob", ctypes.POINTER(ctypes.c_ubyte)),
            ("persist", wintypes.DWORD),
            ("attribute_count", wintypes.DWORD),
            ("attributes", ctypes.c_void_p),
            ("target_alias", wintypes.LPWSTR),
            ("user_name", wintypes.LPWSTR),
        ]

    credential_pointer = ctypes.POINTER(Credential)
    advapi32 = ctypes.WinDLL("Advapi32.dll", use_last_error=True)
    advapi32.CredReadW.argtypes = [
        wintypes.LPCWSTR,
        wintypes.DWORD,
        wintypes.DWORD,
        ctypes.POINTER(credential_pointer),
    ]
    advapi32.CredReadW.restype = wintypes.BOOL
    advapi32.CredFree.argtypes = [ctypes.c_void_p]

    credential = credential_pointer()
    if not advapi32.CredReadW(target, 1, 0, ctypes.byref(credential)):
        error_code = ctypes.get_last_error()
        if error_code == 1168:
            raise CredentialStoreError(
                "La credencial configurada no existe en el almacén de Windows."
            )
        raise CredentialStoreError(
            "No se pudo leer la credencial desde el almacén de Windows."
        )

    try:
        blob_size = credential.contents.blob_size
        if blob_size <= 0 or blob_size % 2 != 0 or blob_size > 5_120:
            raise CredentialStoreError(
                "La credencial de Windows tiene un formato no válido."
            )
        raw_value = ctypes.string_at(credential.contents.blob, blob_size)
        try:
            value = raw_value.decode("utf-16-le")
        except UnicodeDecodeError:
            raise CredentialStoreError(
                "La credencial de Windows tiene un formato no válido."
            ) from None
        if not value or not value.strip():
            raise CredentialStoreError(
                "La credencial de Windows no contiene una contraseña válida."
            )
        return value
    finally:
        advapi32.CredFree(credential)


__all__ = ["CredentialStoreError", "read_windows_generic_credential"]
