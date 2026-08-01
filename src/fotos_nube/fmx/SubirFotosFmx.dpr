program SubirFotosFmx;

uses
  System.StartUpCopy,
  FMX.Forms,
  UPrincipal in 'UPrincipal.pas' {frmPrincipal},
  UConfigFotos in 'UConfigFotos.pas',
  UImagenUtil in 'UImagenUtil.pas',
  UColaFotosNube in 'UColaFotosNube.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
