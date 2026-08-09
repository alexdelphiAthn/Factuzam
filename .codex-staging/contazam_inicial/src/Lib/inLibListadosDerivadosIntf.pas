{******************************************************************************}
{                                                                              }
{  Módulo:       inLibListadosDerivadosIntf                                   }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos neutrales para formatos FastReport derivados y sus alcances.   }
{******************************************************************************}
unit inLibListadosDerivadosIntf;

interface

uses
  System.Classes;

type
  TContextoListadosDerivados = record
    RecursoBase: string;
    Empresa: string;
    Usuario: string;
  end;

  TAlcanceListadoDerivado = record
    Alcance: string;
    Empresa: string;
    Grupo: string;
    Usuario: string;
  end;

  TListadoDerivado = record
    Id: Int64;
    RecursoBase: string;
    Nombre: string;
    Descripcion: string;
    Alcance: TAlcanceListadoDerivado;
    Version: Integer;
    UsuarioModificacion: string;
  end;

  TListadosDerivados = TArray<TListadoDerivado>;
  TGruposListadoDerivado = TArray<string>;

  TSolicitudGuardarListadoDerivado = record
    Id: Int64;
    Contexto: TContextoListadosDerivados;
    Nombre: string;
    Descripcion: string;
    Alcance: TAlcanceListadoDerivado;
  end;

  IRepositorioListadosDerivados = interface
    ['{2BD0D8A4-FCD4-45EB-A7DC-9DBD8498F8AF}']
    function BuscarId(
      const AContexto: TContextoListadosDerivados;
      const ANombre: string;
      const AAlcance: TAlcanceListadoDerivado): Int64;
    function Guardar(
      const ASolicitud: TSolicitudGuardarListadoDerivado;
      AContenido: TStream): TListadoDerivado;
    function Leer(
      const AContexto: TContextoListadosDerivados;
      AId: Int64;
      AContenido: TStream): Boolean;
    function Listar(
      const AContexto: TContextoListadosDerivados): TListadosDerivados;
    function ListarGrupos(
      const AUsuario: string): TGruposListadoDerivado;
  end;

implementation

end.
