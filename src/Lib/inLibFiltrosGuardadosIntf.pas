{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFiltrosGuardadosIntf                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y estructuras del servicio de filtros guardados.                }
{******************************************************************************}
unit inLibFiltrosGuardadosIntf;

interface

uses
  System.Generics.Collections;

type
  TFiltroGuardadoInfo = record
    Id: Int64;
    Nombre: string;
    Descripcion: string;
    Propietario: string;
    EsPropio: Boolean;
  end;

  TFiltrosGuardadosList = TList<TFiltroGuardadoInfo>;

  TDestinoCompartidoInfo = record
    Id: Int64;
    TipoDestino: string;
    UsuarioGrupo: string;
  end;

  TDestinosCompartidosList = TList<TDestinoCompartidoInfo>;

  IFiltrosGuardados = interface
    ['{B09A610D-80AE-48E0-B311-6F72655F3859}']
    function ListarFiltros(
      const AMto, AVista: string
    ): TFiltrosGuardadosList;
    function BuscarFiltroPropio(
      const AMto, AVista, ANombre: string
    ): Int64;
    function GuardarFiltroNuevo(
      const AMto, AVista, ANombre, ADescripcion, AFiltroBase64: string
    ): Int64;
    procedure SobrescribirFiltro(
      AIdFiltro: Int64;
      const ANombre, ADescripcion, AFiltroBase64: string
    );
    procedure RenombrarFiltro(
      AIdFiltro: Int64;
      const ANombre, ADescripcion: string
    );
    procedure BorrarFiltro(AIdFiltro: Int64);
    function EsPropietario(AIdFiltro: Int64): Boolean;
    function CargarFiltroBase64(AIdFiltro: Int64): string;
    function ListarDestinosCompartidos(
      AIdFiltro: Int64
    ): TDestinosCompartidosList;
    procedure CompartirConDestino(
      AIdFiltro: Int64;
      const ATipoDestino, ADestino: string
    );
    procedure QuitarDestinoCompartido(AIdDestino: Int64);
  end;

  IProveedorFiltrosGuardados = interface
    ['{DAC85C81-8021-4BBF-93D6-05A633D7B99D}']
    function GetFiltrosGuardados: IFiltrosGuardados;
    property FiltrosGuardados: IFiltrosGuardados
      read GetFiltrosGuardados;
  end;

implementation

end.
