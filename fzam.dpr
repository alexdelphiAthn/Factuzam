program Fzam;

uses
  Forms,
  MidasLib,
  Vcl.Consts in 'src\vcl\Vcl.Consts.pas',
  System.SysConst in 'src\vcl\System.SysConst.pas',
  Sysutils,
  inLibDevExp in 'src\Lib\inLibDevExp.pas',
  inLibDir in 'src\Lib\inLibDir.pas',
  inLibGlobalVar in 'src\Lib\inLibGlobalVar.pas',
  inLibLog in 'src\Lib\inLibLog.pas',
  inLibtb in 'src\Lib\inLibtb.pas',
  inLibUser in 'src\Lib\inLibUser.pas',
  inLibWin in 'src\Lib\inLibWin.pas',
  inLibShowMto in 'src\Lib\inLibShowMto.pas',
  inLibUnitForm in 'src\Lib\inLibUnitForm.pas',
  inLibMsg in 'src\Lib\inLibMsg.pas',
  inLibNet in 'src\Lib\inLibNet.pas',
  inLibScriptDB in 'src\Lib\inLibScriptDB.pas',
  inLibIBAN in 'src\Lib\inLibIBAN.pas',
  inLibFacturas in 'src\Lib\inLibFacturas.pas',
  inMtoFrmBase in 'src\Core\inMtoFrmBase.pas' {frmBase},
  inMtoLogon in 'src\Core\inMtoLogon.pas' {frmLogon},
  inMtoPrincipal in 'src\Core\inMtoPrincipal.pas' {frmMtoPrincipal},
  inMtoGen in 'src\Forms\inMtoGen.pas' {frmMtoGen},
  inMtoFacturas in 'src\Forms\inMtoFacturas.pas' {frmMtoFacturas},
  inMtoArticulos in 'src\Forms\inMtoArticulos.pas' {frmMtoArticulos},
  inMtoClientes in 'src\Forms\inMtoClientes.pas' {frmMtoClientes},
  inMtoContadores in 'src\Forms\inMtoContadores.pas' {frmMtoContadores},
  inMtoEmpresas in 'src\Forms\inMtoEmpresas.pas' {frmMtoEmpresas},
  inMtoFamilias in 'src\Forms\inMtoFamilias.pas' {frmMtoFamilias},
  inMtoFormasdePago in 'src\Forms\inMtoFormasdePago.pas' {frmMtoFormasdePago},
  inMtoGeneradorProcesos in 'src\Forms\inMtoGeneradorProcesos.pas' {frmMtoGeneradorProcesos},
  inMtoGenSearch in 'src\Forms\inMtoGenSearch.pas' {frmMtoSearch},
  inMtoGrupos in 'src\Forms\inMtoGrupos.pas' {frmMtoGrupos},
  inMtoIvas in 'src\Forms\inMtoIvas.pas' {frmMtoIvas},
  inMtoIvasGrupos in 'src\Forms\inMtoIvasGrupos.pas' {frmMtoIvasGrupos},
  inMtoProveedores in 'src\Forms\inMtoProveedores.pas' {frmMtoProveedores},
  inMtoTarifas in 'src\Forms\inMtoTarifas.pas' {frmMtoTarifas},
  inMtoUsuarios in 'src\Forms\inMtoUsuarios.pas' {frmMtoUsuarios},
  inMtoUsuariosPerfiles in 'src\Forms\inMtoUsuariosPerfiles.pas' {frmMtoUsuariosPerfiles},
  inMtoModalArtTar in 'src\Modals\inMtoModalArtTar.pas' {frmMtoModalArtTar},
  inMtoModalFacRec in 'src\Modals\inMtoModalFacRec.pas' {frmGenFacRec},
  inMtoModalGenFilter in 'src\Modals\inMtoModalGenFilter.pas' {frmModalGenFilter},
  inMtoModalGenImp in 'src\Modals\inMtoModalGenImp.pas' {frmPrint},
  inMtoModalGenImpEle in 'src\Modals\inMtoModalGenImpEle.pas' {frmMtoModalGenImpEle},
  inMtoModalGenImpSave in 'src\Modals\inMtoModalGenImpSave.pas' {frmModalGenImpSave},
  inMtoModalGenPass in 'src\Modals\inMtoModalGenPass.pas' {frmModalGenPass},
  inMtoModalImpFac in 'src\Modals\inMtoModalImpFac.pas' {frmPrintFac},
  inMtoModalImpRecFac in 'src\Modals\inMtoModalImpRecFac.pas' {frmPrintRecFac},
  inMtoModalCliEti in 'src\Modals\inMtoModalCliEti.pas' {frmPrintCliEti},
  inMtoSplash in 'src\Core\inMtoSplash.pas' {frmSplash},
  UniDataConn in 'src\DataModules\UniDataConn.pas' {dmConn: TDataModule},
  UniDataGen in 'src\DataModules\UniDataGen.pas' {dmBase: TDataModule},
  UniDataArticulos in 'src\DataModules\UniDataArticulos.pas' {dmArticulos: TdmArticulos},
  UniDataClientes in 'src\DataModules\UniDataClientes.pas' {dmClientes: TdmClientes},
  UniDataContadores in 'src\DataModules\UniDataContadores.pas' {dmContadores: dmContadores},
  UniDataEmpresas in 'src\DataModules\UniDataEmpresas.pas' {dmEmpresas: TdmEmpresas},
  UniDataFamilias in 'src\DataModules\UniDataFamilias.pas' {dmFamilias1. TdmFamilias},
  UniDataFormasdePago in 'src\DataModules\UniDataFormasdePago.pas' {dmFormasdePago: TdmFormasdePago},
  UniDataGeneradorProcesos in 'src\DataModules\UniDataGeneradorProcesos.pas' {dmGeneradorProcesos: TDataModule},
  UniDataGrupos in 'src\DataModules\UniDataGrupos.pas' {dmGrupos: TDataModule},
  UniDataIvas in 'src\DataModules\UniDataIvas.pas' {dmIvas: TDataModule},
  UniDataIvasGrupos in 'src\DataModules\UniDataIvasGrupos.pas' {dmIvasGrupos: TDataModule},
  UniDataPerfiles in 'src\DataModules\UniDataPerfiles.pas' {dmPerfiles: TDataModule},
  UniDataProveedores in 'src\DataModules\UniDataProveedores.pas' {dmProveedores: TDataModule},
  UniDataTarifas in 'src\DataModules\UniDataTarifas.pas' {dmTarifas: TDataModule},
  UniDataUsuarios in 'src\DataModules\UniDataUsuarios.pas' {dmUsuarios: TDataModule},
  UniDataUsuariosPerfiles in 'src\DataModules\UniDataUsuariosPerfiles.pas' {dmUsuariosPerfiles: TDataModule},
  UniDataFacturas in 'src\DataModules\UniDataFacturas.pas' {dmFacturas: TdmFacturas},
  UniDataGenFilter in 'src\DataModules\UniDataGenFilter.pas' {dmGenFilter: TDataModule},
  inMtoPedidos in 'src\Forms\inMtoPedidos.pas',
  UniDataPedidos in 'src\DataModules\UniDataPedidos.pas' {/cxButtonHelper in 'cxButtonHelper.pas';},
  inMtoPaises in 'src\Forms\inMtoPaises.pas' {frmMtoPaises},
  UniDataPaises in 'src\DataModules\UniDataPaises.pas' {dmPaises: TDataModule},
  inLibCertificates in 'src\Lib\inLibCertificates.pas',
  inMtoModalEmpCer in 'src\Modals\inMtoModalEmpCer.pas',
  inMtoCajaMenu in 'src\Forms\inMtoCajaMenu.pas' {frmMtoMenuCaja},
  inMtoCajaOpe in 'src\Forms\inMtoCajaOpe.pas' {frmMtoOpeCaja},
  UniDataCaja in 'src\DataModules\UniDataCaja.pas' {dmCajaOpe},
  inMtoCajaFaseCobro in 'src\Forms\inMtoCajaFaseCobro.pas' {frmMtoCajaFaseCobro},
  inLibDefaultValues in 'src\Lib\inLibDefaultValues.pas',
  inLibGenBusq in 'src\Lib\inLibGenBusq.pas',
  inMtoAlmacenes in 'src\Forms\inMtoAlmacenes.pas' {frmMtoAlmacenes},
  UniDataAlmacenes in 'src\DataModules\UniDataAlmacenes.pas' {dmAlmacenes: TDataModule};

var
  frmLogon: TfrmLogon;
  AutoLoginSuccessful: Boolean;

begin
//  {$IFDEF DEBUG}
//      ReportMemoryLeaksOnShutdown := True;
//   {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Fzam';
  frmLogon := TfrmLogon.Create(Application);
  try
    AutoLoginSuccessful := False;
    if (frmLogon.IsInitializeAuto) then
    begin
      frmLogon.btnAceptarClick(nil);
      AutoLoginSuccessful := (frmLogon.sSuccess = 'S');
    end;
    if (not AutoLoginSuccessful) then
    begin
      frmLogon.ShowModal;
      //frmLogon.Caption := Application.Title;
    end;
    if (frmLogon.sSuccess <> 'S') then
      Exit;
  finally
    frmLogon.Free;
  end;
  Application.CreateForm(TfrmMtoPrincipal, frmMtoPrincipal);
  Application.Run;
end.
