{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMovVentasArtExcelTests                                   }
{    Tipo:       Pruebas (DUnitX)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prueba de snapshot del exportador migrado inLibMovVentasArtExcel. Lo      }
{    ejecuta contra el doble TEscritorHojaCalculoFalso con un dataset en       }
{    memoria (TClientDataSet, sin BBDD) y afirma las celdas clave: título,     }
{    cabecera, detalle (valor + formato + alineación), totales y anchos.       }
{    Al no tocar DevExpress, corre en un runner de consola.                    }
{******************************************************************************}
unit inLibMovVentasArtExcelTests;

interface

uses
  DUnitX.TestFramework, inLibHojaCalculoIntf, inLibHojaCalculoFalso;

type
  [TestFixture]
  TPruebasMovVentasArtExcel = class
  private
    FFake: TEscritorHojaCalculoFalso;   // para consultar lo registrado
    FEscritor: IEscritorHojaCalculo;    // dueño del ciclo de vida (refcount)
  public
    [Setup]
    procedure Preparar;
    [TearDown]
    procedure Limpiar;
    [Test]
    procedure Snapshot_SinGrupos;
  end;

implementation

uses
  System.SysUtils, System.Variants, Data.DB, Datasnap.DBClient,
  inLibMovVentasArtExcel;

procedure TPruebasMovVentasArtExcel.Preparar;
begin
  FFake := TEscritorHojaCalculoFalso.Create;
  FEscritor := FFake;   // refcount 0 -> 1; la interfaz posee el objeto
end;

procedure TPruebasMovVentasArtExcel.Limpiar;
begin
  FEscritor := nil;     // refcount 1 -> 0: libera FFake (no hacer Free manual)
  FFake := nil;
end;

procedure TPruebasMovVentasArtExcel.Snapshot_SinGrupos;
var
  cds: TClientDataSet;
begin
  cds := TClientDataSet.Create(nil);
  try
    cds.FieldDefs.Add('CODIGO_ART_ART', ftString, 30);
    cds.FieldDefs.Add('DESCRIPCION_ART', ftString, 100);
    cds.FieldDefs.Add('UNI_ENT_TOT', ftFloat);
    cds.FieldDefs.Add('IMP_ENT_TOT', ftFloat);
    cds.FieldDefs.Add('UDS_VENTA', ftFloat);
    cds.FieldDefs.Add('IMP_VENTA', ftFloat);
    cds.FieldDefs.Add('IMP_COSTE', ftFloat);
    cds.FieldDefs.Add('BENEFICIO', ftFloat);
    cds.FieldDefs.Add('PCT_BNFCO', ftFloat);
    cds.FieldDefs.Add('VENTA_ENT', ftFloat);
    cds.FieldDefs.Add('VENT_ENT', ftFloat);
    cds.FieldDefs.Add('MARGEN1', ftFloat);
    cds.FieldDefs.Add('MARGEN2', ftFloat);
    cds.FieldDefs.Add('PCT_VDTO', ftFloat);
    cds.FieldDefs.Add('PCT_VLAST', ftFloat);
    cds.CreateDataSet;
    cds.Append;
    cds.FieldByName('CODIGO_ART_ART').AsString := 'A001';
    cds.FieldByName('DESCRIPCION_ART').AsString := 'Camiseta';
    cds.FieldByName('UNI_ENT_TOT').AsFloat := 10;
    cds.FieldByName('IMP_ENT_TOT').AsFloat := 100;
    cds.FieldByName('UDS_VENTA').AsFloat := 8;
    cds.FieldByName('IMP_VENTA').AsFloat := 160;
    cds.FieldByName('IMP_COSTE').AsFloat := 80;
    cds.FieldByName('BENEFICIO').AsFloat := 80;
    cds.FieldByName('PCT_BNFCO').AsFloat := 100;
    cds.FieldByName('VENTA_ENT').AsFloat := 60;
    cds.FieldByName('VENT_ENT').AsFloat := 60;
    cds.FieldByName('MARGEN1').AsFloat := 50;
    cds.FieldByName('MARGEN2').AsFloat := 37.5;
    cds.FieldByName('PCT_VDTO').AsFloat := 80;
    cds.FieldByName('PCT_VLAST').AsFloat := 160;
    cds.Post;
    cds.First;
    ExportarMovVentasArtExcel(FEscritor, cds);
    // Hoja y título.
    Assert.AreEqual('Ventas', FFake.HojaActual);
    Assert.AreEqual('MOVIMIENTOS DE VENTAS POR ARTICULOS Y FECHAS',
      VarToStr(FFake.Valor(1, 0)));
    Assert.AreEqual(14, FFake.TamFuente(1, 0));
    Assert.IsTrue(FFake.EsNegrita(1, 0));
    // Cabecera (fila 3): 'Artículo', negrita, fondo gris y borde inferior.
    Assert.AreEqual('Art' + #237 + 'culo', VarToStr(FFake.Valor(3, 0)));
    Assert.IsTrue(FFake.EsNegrita(3, 0));
    Assert.AreEqual(Integer($00EEEEEE), Integer(FFake.Fondo(3, 0)));
    Assert.AreEqual(Ord(ebFino), Ord(FFake.Borde(3, 0, lbInferior)));
    // Detalle (fila 4): texto, valor numérico con formato y alineación.
    Assert.AreEqual('A001  Camiseta', VarToStr(FFake.Valor(4, 0)));
    Assert.AreEqual(Double(10), Double(FFake.Valor(4, 1)), 0.001);
    Assert.AreEqual('#,##0', FFake.Formato(4, 1));
    Assert.AreEqual(Ord(acDerecha), Ord(FFake.Alineacion(4, 1)));
    // Totales (fila 5): 'TOTAL GENERAL', negrita, fondo grupo y borde superior.
    Assert.AreEqual('TOTAL GENERAL', VarToStr(FFake.Valor(5, 0)));
    Assert.IsTrue(FFake.EsNegrita(5, 0));
    Assert.AreEqual(Integer($00EED7BD), Integer(FFake.Fondo(5, 0)));
    Assert.AreEqual(Ord(ebFino), Ord(FFake.Borde(5, 0, lbSuperior)));
    // Anchos de columna.
    Assert.AreEqual(240, FFake.AnchoDe(0));
    Assert.AreEqual(72, FFake.AnchoDe(1));
  finally
    cds.Free;
  end;
end;

end.
