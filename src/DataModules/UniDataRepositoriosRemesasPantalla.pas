{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosRemesasPantalla                           }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de remesas requeridos por las pantallas.                      }
{******************************************************************************}
unit UniDataRepositoriosRemesasPantalla;

interface

uses
  Uni, inLibRepositoriosPantallaIntf,
  inLibCargaEfectosRemesaPersistenciaIntf,
  UniDataRepositoriosGeneralesPantalla;

type
  TRepositoriosRemesasPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosRemesasPantalla)
  public
    function CrearRepositorioCargaEfectosRemesa(
      AConexion: TUniConnection = nil): IRepositorioCargaEfectosRemesa;
  end;

implementation

uses
  UniDataCargaEfectosRemesaRepositorio;

function TRepositoriosRemesasPantallaUniDAC.
  CrearRepositorioCargaEfectosRemesa(
  AConexion: TUniConnection): IRepositorioCargaEfectosRemesa;
begin
  Result := CrearRepositorioCargaEfectosRemesaUniDAC(
    Conexion(AConexion));
end;

end.
