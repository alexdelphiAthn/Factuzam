{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuNoVerifactuExportIntf                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de lectura para exportar registros NO VERI*FACTU.                  }
{******************************************************************************}
unit inLibVerifactuNoVerifactuExportIntf;

interface

uses
  Data.DB, Uni;

type
  // Los TDataSet devueltos pertenecen al llamador.
  IRepositorioExportacionNoVerifactu = interface
    ['{71ABBD4E-BC62-4934-AF74-6A550F996183}']
    function ColumnasFirmaEventosDisponibles: Boolean;
    function ColumnasFirmaFacturacionDisponibles: Boolean;
    function ContarEventosSinFirma: Integer;
    function ContarFacturasSinFirma: Integer;
    function BuscarEventos: TDataSet;
    function BuscarFacturacion: TDataSet;
  end;
  TFabricaCrearRepositorioExportacionNoVerifactu = function(
    AConexion: TUniConnection): IRepositorioExportacionNoVerifactu;
  TFabricaRepositorioExportacionNoVerifactu = class
  private
    class var FFabrica: TFabricaCrearRepositorioExportacionNoVerifactu;
  public
    class procedure Registrar(
      AFabrica: TFabricaCrearRepositorioExportacionNoVerifactu);
    class function Crear(
      AConexion: TUniConnection): IRepositorioExportacionNoVerifactu;
  end;

implementation

uses
  System.SysUtils, inLibMsgVerifactu;

class procedure TFabricaRepositorioExportacionNoVerifactu.Registrar(
  AFabrica: TFabricaCrearRepositorioExportacionNoVerifactu);
begin
  FFabrica := AFabrica;
end;

class function TFabricaRepositorioExportacionNoVerifactu.Crear(
  AConexion: TUniConnection): IRepositorioExportacionNoVerifactu;
begin
  if not Assigned(FFabrica) then
    raise Exception.Create(
      SErrorRepositorioExportacionNoVerifactuNoRegistrado);
  Result := FFabrica(AConexion);
end;

end.
