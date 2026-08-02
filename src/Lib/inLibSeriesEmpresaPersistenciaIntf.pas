{******************************************************************************}
{                                                                              }
{  Modulo:       inLibSeriesEmpresaPersistenciaIntf                           }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de persistencia para crear series documentales de una empresa.    }
{******************************************************************************}
unit inLibSeriesEmpresaPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TTiposDocumentoEmpresa = TArray<string>;

  IRepositorioSeriesEmpresa = interface
    ['{B4C6F463-62C4-42AE-A36A-696017F3BED3}']
    function ListarTiposDocumento: TTiposDocumentoEmpresa;
    function CrearSerieSiFalta(
      const AEmpresa, ASerie, ATipo, ASubtipo: string;
      AFechaDesde, AFechaHasta: TDateTime;
      const AUsuario: string): Boolean;
  end;

implementation

end.
