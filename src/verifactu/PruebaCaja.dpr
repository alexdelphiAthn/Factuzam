program PruebaCaja;

uses
  Vcl.Forms,
  inMtoCajaMenu in 'inMtoCajaMenu.pas' {frmMtoMenuCaja},
  inMtoCajaOpe in 'inMtoCajaOpe.pas' {frmMtoOpeCaja},
  UniDataCaja in 'UniDataCaja.pas' {dmDataCaja: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdmDataCaja, dmDataCaja);
  Application.CreateForm(TfrmMtoMenuCaja, frmMtoMenuCaja);
  Application.Run;
end.
