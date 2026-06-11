{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEfectosCompra                                           }
{    Tipo:       Data Module                                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de efectos de pago (vi_efectos_compra).                      }
{******************************************************************************}
unit UniDataEfectosCompra;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
  inLibUser, UniDataConn;

type
  TdmEfectosCompra = class(TdmBase)
  private
    { Private declarations }
  public
    // Registra un pago sobre el efecto (PRC_EFEC_REGISTRAR_PAGO) y refresca
    // la cartera. Devuelve el nro de pago (>0) o 0/-1 si no se pudo.
    function RegistrarPago(const ASerie, ANumero: string; ANumEfec: Integer;
      AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
  end;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmEfectosCompra.RegistrarPago(const ASerie, ANumero: string;
  ANumEfec: Integer; AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia: string): Integer;
var
  sp: TUniStoredProc;
begin
  sp := TUniStoredProc.Create(nil);
  try
    sp.Connection     := inLibGlobalVar.oConn;
    sp.StoredProcName := 'PRC_EFEC_REGISTRAR_PAGO';
    sp.Params.Clear;
    sp.Params.CreateParam(ftString,  'p_SERIE',      ptInput);
    sp.Params.CreateParam(ftString,  'p_NUMERO',     ptInput);
    sp.Params.CreateParam(ftInteger, 'p_NUM_EFEC',   ptInput);
    sp.Params.CreateParam(ftDate,    'p_FECHA',      ptInput);
    sp.Params.CreateParam(ftFloat,   'p_IMPORTE',    ptInput);
    sp.Params.CreateParam(ftString,  'p_TIPO',       ptInput);
    sp.Params.CreateParam(ftString,  'p_REFERENCIA', ptInput);
    sp.Params.CreateParam(ftString,  'p_ENTIDAD',    ptInput);
    sp.Params.CreateParam(ftString,  'p_USUARIO',    ptInput);
    sp.Params.CreateParam(ftInteger, 'p_RESULTADO',  ptOutput);
    sp.ParamByName('p_SERIE').AsString      := ASerie;
    sp.ParamByName('p_NUMERO').AsString     := ANumero;
    sp.ParamByName('p_NUM_EFEC').AsInteger  := ANumEfec;
    sp.ParamByName('p_FECHA').AsDateTime    := AFecha;
    sp.ParamByName('p_IMPORTE').AsFloat     := AImporte;
    sp.ParamByName('p_TIPO').AsString       := ATipo;
    sp.ParamByName('p_REFERENCIA').AsString := AReferencia;
    sp.ParamByName('p_ENTIDAD').AsString    := '';
    sp.ParamByName('p_USUARIO').AsString    := oUser;
    sp.ExecProc;
    Result := sp.ParamByName('p_RESULTADO').AsInteger;
  finally
    FreeAndNil(sp);
  end;
  if (unqryTablaG <> nil) and unqryTablaG.Active then
  begin
    unqryTablaG.Close;
    unqryTablaG.Open;
  end;
end;

initialization
  ForceReferenceToClass(TdmEfectosCompra);
end.
