{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraduccionesInforme                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Traducción de los textos visibles de un informe FastReport ya             }
{    cargado. Las plantillas predeterminadas usan las claves                   }
{    FastReport.<unidad>.Predeterminado.<objeto>.Memo con recorrido de         }
{    clases heredadas; los formatos personalizados se traducen buscando        }
{    el texto español de cada memo en el catálogo (D22-B).                     }
{******************************************************************************}
unit inLibTraduccionesInforme;

interface

uses
  System.Classes, frxClass, inLibTraduccionesIntf;

procedure TraducirInformeFastReport(
  AInforme: TfrxReport;
  AInstancia: TComponent;
  const ATraducciones: IServicioTraducciones;
  AEsPersonalizado: Boolean);

implementation

uses
  System.SysUtils;

const
  SALTO_FINAL = #13#10;

function TraducirMemoPredeterminado(
  AInstancia: TComponent;
  const ATraducciones: IServicioTraducciones;
  const ANombreObjeto, ATexto: string;
  out ATraducido: string): Boolean;
var
  Clase: TClass;
  Clave: string;
begin
  Result := False;
  ATraducido := ATexto;
  if Assigned(AInstancia) and
     (ANombreObjeto <> '') then
  begin
    // Igual que en los DFM: primero la clase concreta y después sus
    // ancestros, para reutilizar el catálogo del formulario base.
    Clase := AInstancia.ClassType;
    while Assigned(Clase) and
          Clase.InheritsFrom(TComponent) and
          not Result do
    begin
      Clave := 'FastReport.' + Clase.UnitName +
        '.Predeterminado.' + ANombreObjeto + '.Memo';
      if ATraducciones.ExisteTraduccion(Clave) then
      begin
        ATraducido := ATraducciones.Traducir(Clave, ATexto);
        Result := True;
      end
      else
        Clase := Clase.ClassParent;
    end;
  end;
end;

procedure TraducirInformeFastReport(
  AInforme: TfrxReport;
  AInstancia: TComponent;
  const ATraducciones: IServicioTraducciones;
  AEsPersonalizado: Boolean);
var
  i: Integer;
  EsPseudo: Boolean;
  TeniaSalto: Boolean;
  Memo: TfrxCustomMemoView;
  Texto: string;
  Traducido: string;
begin
  if Assigned(AInforme) and
     Assigned(ATraducciones) then
  begin
    EsPseudo := SameText(ATraducciones.Idioma, IDIOMA_PSEUDO);
    if EsPseudo or
       not SameText(ATraducciones.Idioma, IDIOMA_ESPANOL) then
    begin
      for i := 0 to AInforme.AllObjects.Count - 1 do
      begin
        if TObject(AInforme.AllObjects[i]) is TfrxCustomMemoView then
        begin
          Memo := TfrxCustomMemoView(AInforme.AllObjects[i]);
          Texto := Memo.Text;
          // El memo termina con un salto de línea que no forma
          // parte del texto catalogado en fza_traducciones.
          TeniaSalto := Texto.EndsWith(SALTO_FINAL);
          if TeniaSalto then
            SetLength(Texto, Length(Texto) - Length(SALTO_FINAL));
          if Texto <> '' then
          begin
            if EsPseudo or AEsPersonalizado then
              Traducido := ATraducciones.TraducirTextoInforme(Texto)
            else if not TraducirMemoPredeterminado(
                          AInstancia,
                          ATraducciones,
                          Memo.Name,
                          Texto,
                          Traducido) then
              Traducido := ATraducciones.TraducirTextoInforme(Texto);
            if Traducido <> Texto then
            begin
              if TeniaSalto then
                Memo.Text := Traducido + SALTO_FINAL
              else
                Memo.Text := Traducido;
            end;
          end;
        end;
      end;
    end;
  end;
end;

end.
