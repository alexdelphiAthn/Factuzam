{******************************************************************************}
{                                                                              }
{  Módulo:       RecuentoFzam                                                  }
{    Tipo:       Proyecto (App FMX Android)                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    App de recuento de inventarios para terminal de mano (Android FMX).       }
{    Recuenta escaneando códigos de barras y sube los eventos al servidor      }
{    REST (PHP) que hace de puente con Factuzam. Diseño completo en            }
{    DESARROLLOS EN CURSO/recuento_inventarios_app.md.                         }
{******************************************************************************}
program RecuentoFzam;

uses
  System.StartUpCopy,
  FMX.Forms,
  RecuentoModelo in 'RecuentoModelo.pas',
  RecuentoConfig in 'RecuentoConfig.pas',
  RecuentoApi in 'RecuentoApi.pas',
  RecuentoLocal in 'RecuentoLocal.pas',
  RecuentoSync in 'RecuentoSync.pas',
  fRecuentoMenu in 'fRecuentoMenu.pas',
  fRecuentoSelector in 'fRecuentoSelector.pas',
  fRecuentoConteo in 'fRecuentoConteo.pas',
  fRecuentoConfig in 'fRecuentoConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMenu, frmMenu);
  Application.Run;
end.
