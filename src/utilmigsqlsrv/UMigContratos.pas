{******************************************************************************}
{                                                                              }
{  Módulo:       UMigContratos                                                 }
{    Tipo:       Contratos                                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos segregados para ejecutar y extender migraciones por dominio.    }
{******************************************************************************}
unit UMigContratos;

interface

uses
  Uni;

type
  TMigLogProc = reference to procedure(const sMensaje: string);
  TMigProgressProc = reference to procedure(
    const sDominio: string;
    iRow, iTotal: Integer);
  TMigStats = record
    Leidas: Integer;
    Insertadas: Integer;
    Saltadas: Integer;
    Errores: Integer;
  end;
  IDatosMigracion = interface
    ['{6D019930-B62F-47D4-85C8-4B1392B2F699}']
    function ConexionOrigen: TUniConnection;
    function ConexionDestino: TUniConnection;
    function ContarOrigen(const sSelectCount: string): Integer;
  end;
  IRegistroMigracion = interface
    ['{35AF3B45-C631-4728-844A-B2BFB26750C7}']
    procedure Log(const sMensaje: string); overload;
    procedure Log(
      const sFormato: string;
      const aArgs: array of const); overload;
    procedure LogSalto(
      const sDominio, sCodigo, sMotivo: string;
      const sDescOrigen: string = '';
      const sDescDestino: string = '');
    procedure LogError(
      const sDominio, sCodigo, sError: string;
      const sDescOrigen: string = '';
      const sPista: string = '');
  end;
  IProgresoMigracion = interface
    ['{E0260974-B8B3-45A7-A4A6-7DAA999AE90D}']
    procedure EstablecerTotal(iTotal: Integer);
    procedure Avanzar(iCount: Integer = 1);
  end;
  ICancelacionMigracion = interface
    ['{CF4ED86D-2303-4A06-A7C5-F0467C39464B}']
    function EstaCancelada: Boolean;
  end;
  IFotosMigracion = interface
    ['{B64C7CDE-9FE7-4495-B761-AC3AB5AD50F9}']
    function DirectorioOrigen: string;
    function DirectorioDestino: string;
    function NumeroHilos: Integer;
  end;
  IAlmacenesMigracion = interface
    ['{8416151C-BA76-4D5A-8FAF-D33A372E857F}']
    function TieneDeposito(iEmpresa: Integer): Boolean;
    function EsDeposito(iEmpresa, iAlmacen: Integer): Boolean;
  end;
  IContextoMigracion = interface
    ['{DAD879D6-E757-4498-9544-5A55D88CC16C}']
    function Datos: IDatosMigracion;
    function Registro: IRegistroMigracion;
    function Progreso: IProgresoMigracion;
    function Cancelacion: ICancelacionMigracion;
    function Fotos: IFotosMigracion;
    function Almacenes: IAlmacenesMigracion;
    function Usuario: string;
  end;
  TMigProc = reference to procedure(
    const AContexto: IContextoMigracion;
    var AEstadisticas: TMigStats);
  IMigracion = interface
    ['{9D10504A-0C10-4F7F-B319-568E64108882}']
    function Codigo: string;
    function Nombre: string;
    function Descripcion: string;
    function Dependencias: TArray<string>;
    function EsIndependiente: Boolean;
    procedure Ejecutar(
      const AContexto: IContextoMigracion;
      var AEstadisticas: TMigStats);
  end;

implementation

end.
