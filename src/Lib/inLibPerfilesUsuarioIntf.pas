{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPerfilesUsuarioIntf                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y estructuras para la persistencia de perfiles de usuario.      }
{******************************************************************************}
unit inLibPerfilesUsuarioIntf;

interface

uses
  System.Generics.Collections;

const
  PERFIL_TODOS = 'Todos';

type
  TDictValue = record
    sValue: string;
    sValueText: WideString;
  end;

  TProfileDicc = TDictionary<string, TDictValue>;

  TPerfilItem = record
    UserGroup: string;
    KeyPerfil: string;
    SubKey: string;
    Value: string;
  end;

  TPerfilList = TList<TPerfilItem>;

  IPerfilesUsuario = interface
    ['{76B2E17F-A962-4F37-8C33-72F44C8B63D7}']
    procedure GrabarPerfil(
      const AUsuarioGrupo, AClave, ASubclave, AValor: string;
      const AValorTexto: WideString = '');
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
    procedure EliminarPerfil(
      const AUsuarioGrupo, AClave: string;
      const ASubclave: string = '');
    function ObtenerValorPerfil(
      const AClave, ASubclave, AValorPredeterminado: string
    ): string;
    function ObtenerSubclavePerfil(
      const AClave: string;
      const AValorPredeterminado: string = ''
    ): string;
    procedure PrecargarPerfilesUsuario;
    function CargarPerfilFormulario(
      const AFormulario: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    function CargarPerfilFormulario(
      const AFormulario, AUsuario, AGrupo: string;
      out APerfil: TProfileDicc
    ): Boolean; overload;
    procedure ResincronizarPerfilFormulario(const AFormulario: string);
    procedure InvalidarCachePerfiles;
  end;

  IProveedorPerfilesUsuario = interface
    ['{5D4A522A-54B3-40E5-A388-790D59C8E12E}']
    function GetPerfilesUsuario: IPerfilesUsuario;
    property PerfilesUsuario: IPerfilesUsuario read GetPerfilesUsuario;
  end;

implementation

end.
