{******************************************************************************}
{                                                                              }
{  Modulo:       ColumnSKUcxGridTest                                           }
{    Tipo:       Proyecto de prueba independiente                              }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid fuera de fzam.dproj: logon minimo de conexion      }
{    MariaDB (inMtoPruebaColumnasSkuLogon, guarda .ini junto al exe) que       }
{    deja lista inLibGlobalVar.oConn y abre el banco de pruebas                }
{    (inMtoPruebaColumnasSku).                                                 }
{                                                                              }
{    Las dependencias de src (inLibGridArticulos, paleta, validador...) se     }
{    resuelven por las rutas de busqueda del .dproj; NO se duplica ninguna     }
{    unidad del proyecto principal.                                            }
{******************************************************************************}
program ColumnSKUcxGridTest;

uses
  Vcl.Forms,
  inLibColumnasSkuIntf in 'inLibColumnasSkuIntf.pas',
  inLibColumnasSkuModoSku in 'inLibColumnasSkuModoSku.pas',
  inLibColumnasSkuModoDesglose in 'inLibColumnasSkuModoDesglose.pas',
  inLibColumnasSkuModoTallas in 'inLibColumnasSkuModoTallas.pas',
  inLibColumnasSku in 'inLibColumnasSku.pas',
  inMtoPruebaColumnasSkuLogon in 'inMtoPruebaColumnasSkuLogon.pas'
    {frmMtoPruebaColumnasSkuLogon},
  inMtoPruebaColumnasSku in 'inMtoPruebaColumnasSku.pas'
    {frmMtoPruebaColumnasSku};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Prueba ColumnSKUcxGrid';
  // Sin conexion no hay prueba: el logon deja oConn lista o se sale.
  if TfrmMtoPruebaColumnasSkuLogon.ConectarBBDD then
  begin
    Application.CreateForm(TfrmMtoPruebaColumnasSku,
                           frmMtoPruebaColumnasSku);
    Application.Run;
  end;
end.
