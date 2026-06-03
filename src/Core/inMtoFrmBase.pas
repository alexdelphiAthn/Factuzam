{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoFrmBase                                                  }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/02/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Este formulario es el formulario base para todos los demás. Tiene la      }
{    traducción al Español de Developer Express. Sólo sirve a propósito de     }
{    herencia para generar otros formularios                                   }
{******************************************************************************}
unit inMtoFrmBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxClasses, cxLocalization, cxContainer,
  cxEdit, cxLabel, dxSkinsCore, dxSkinsDefaultPainters, cxLookAndFeels,
  dxSkinsForm, dxSkinBlack, dxSkinBlue, dxSkinBlueprint, dxSkinDarkRoom,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinHighContrast, dxSkinMetropolis, dxSkinMetropolisDark,
  dxSkinOffice2010Black, dxSkinOffice2010Blue, dxSkinOffice2010Silver,
  dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinSeven, dxSkinSevenClassic, dxSkinSharp,
  dxSkinSharpPlus, dxSkinSpringTime, dxSkinTheAsphaltWorld, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinStardust, dxSkinSummer2008,
  dxSkinValentine, dxSkinXmas2008Blue, dxSkinscxPCPainter, dxCore, cxStyles,
  dxSkinBasic, dxSkinCaramel, dxSkinCoffee, dxSkinDarkSide, dxSkinGlassOceans,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMoneyTwins, dxSkinOffice2007Black, dxSkinOffice2007Blue,
  dxSkinOffice2007Green, dxSkinOffice2007Pink, dxSkinOffice2007Silver,
  dxSkinOffice2016Colorful, dxSkinOffice2016Dark, dxSkinOffice2019Black,
  dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray, dxSkinOffice2019White,
  dxSkinPumpkin, dxSkinSilver, dxSkinTheBezier, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, JvComponentBase,
  JvEnterTab;

type
  TfrmBase = class(TForm)
    Localizer1: TcxLocalizer;
    jvntrstb1: TJvEnterAsTab;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  protected
    // Hooks de log avanzado a nivel de formulario. Se loguean solo si
    // ltAvanzado esta activo en TLog (parametro appLogAvanzado).
    procedure DoShow; override;
    procedure DoClose(var Action: TCloseAction); override;
  public
    { Public declarations }
    // Articulo/sku del registro/linea en foco, para la consulta de stock
    // global (Ctrl+U, capturado en inMtoPrincipal). Por defecto vacio; los
    // formularios con articulo activo lo sobreescriben.
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); virtual;
  end;

var
  frmBase: TfrmBase;

implementation

uses
  inLibLog;

{$R *.dfm}
{$R CXLOCALIZATION.res}

procedure TfrmBase.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  Localizer1.Locale := 1034;
  Localizer1.Active := True;
  // Etiquetas TcxLabel transparentes (sin fondo solido) en toda la jerarquia
  // que herede de TfrmBase. Centralizado aqui para no repetirlo pantalla a
  // pantalla y cubrir tambien los labels que se anadan en el futuro.
  for i := 0 to ComponentCount - 1 do
    if Components[i] is TcxLabel then
      TcxLabel(Components[i]).Transparent := True;
end;

procedure TfrmBase.DoShow;
begin
  inherited;
  if (Log <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, Self.ClassName, 'Show', Self.Name);
end;

procedure TfrmBase.DoClose(var Action: TCloseAction);
begin
  if (Log <> nil) and Log.IsLogTypeEnabled(ltAvanzado) then
    Log.LogEvento(Self.UnitName, Self.ClassName, 'Close', Self.Name);
  inherited;
end;

procedure TfrmBase.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  // Por defecto un formulario no aporta articulo en foco para Ctrl+U.
  ACodArt := '';
  ACodSku := '';
end;

{
Cómo heredar un form sin haber pasado por File New Others Inheritance.....
Primero poniendo en la definición de la clase, añadiendo el unit a uses y luego
TFormOtherType = class(InheritedFormType)
y después pasando por el dfm coomo se explica a continuación

https://stackoverflow.com/questions/70742195/
                                    how-to-make-an-old-form-inherit-from-another


Open dfm file in some other text editor and replace object with inherited

object FrmMyForm : TFrmMyForm

to

inherited FrmMyForm : TFrmMyForm

However, Delphi has issues with opening such forms
if they don't belong to the same project. For instance,
if you have base form declared in a package and you are
using it to inherit forms in application or another package.

If you have problem opening such forms, make sure that you first
open base form and then inherited.
}
end.
