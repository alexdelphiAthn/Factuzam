unit UniDataCaja;

interface

uses
  System.SysUtils, System.Classes, Vcl.ExtCtrls, Data.DB, Datasnap.Provider,
  Datasnap.DBClient, UniProvider, MySQLUniProvider, DBAccess, Uni;

type
  TdmDataCaja = class(TDataModule)
    cdsLineas:TClientDataSet;
    cdsCabecera:TClientDataSet;
    DataSetProviderLineas:TDataSetProvider;
    DataSetProviderCabecera:TDataSetProvider;
    dsCabecera:TDataSource;
    dsLineas:TDataSource;
    UniConnection1: TUniConnection;
    MySQLUniProvider1: TMySQLUniProvider;
    cdsCabeceraNRO_FACTURA: TStringField;
    cdsCabeceraSERIE_FACTURA: TStringField;
    cdsCabeceraFECHA_FACTURA: TDateField;
    cdsCabeceraCODIGO_EMPLEADO: TStringField;
    cdsCabeceraNOMBRE_EMPLEADO: TStringField;
    cdsCabeceraESCONSOLIDADA_FACTURA: TStringField;
    cdsCabeceraINSTANTECONSO_FACTURA: TDateTimeField;
    cdsCabeceraTIPO_FACTURA: TStringField;
    cdsCabeceraFASE_FACTURA: TStringField;
    cdsCabeceraCODIGO_EMPRESA_FACTURA: TStringField;
    cdsCabeceraRAZONSOCIAL_EMPRESA_FACTURA: TStringField;
    cdsCabeceraNIF_EMPRESA_FACTURA: TStringField;
    cdsCabeceraMOVIL_EMPRESA_FACTURA: TStringField;
    cdsCabeceraEMAIL_EMPRESA_FACTURA: TStringField;
    cdsCabeceraDIRECCION1_EMPRESA_FACTURA: TStringField;
    cdsCabeceraDIRECCION2_EMPRESA_FACTURA: TStringField;
    cdsCabeceraPOBLACION_EMPRESA_FACTURA: TStringField;
    cdsCabeceraPROVINCIA_EMPRESA_FACTURA: TStringField;
    cdsCabeceraCODIGO_PAIS_EMPRESA_FACTURA: TStringField;
    cdsCabeceraNOMBRE_PAIS_EMPRESA_FACTURA: TStringField;
    cdsCabeceraCPOSTAL_EMPRESA_FACTURA: TStringField;
    cdsCabeceraESRETENCIONES_EMPRESA_FACTURA: TStringField;
    cdsCabeceraGRUPO_ZONA_IVA_EMPRESA_FACTURA: TStringField;
    cdsCabeceraESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA: TStringField;
    cdsCabeceraCODIGO_CLIENTE_FACTURA: TStringField;
    cdsCabeceraRAZONSOCIAL_CLIENTE_FACTURA: TStringField;
    cdsCabeceraNIF_CLIENTE_FACTURA: TStringField;
    cdsCabeceraMOVIL_CLIENTE_FACTURA: TStringField;
    cdsCabeceraEMAIL_CLIENTE_FACTURA: TStringField;
    cdsCabeceraDIRECCION1_CLIENTE_FACTURA: TStringField;
    cdsCabeceraDIRECCION2_CLIENTE_FACTURA: TStringField;
    cdsCabeceraPOBLACION_CLIENTE_FACTURA: TStringField;
    cdsCabeceraPROVINCIA_CLIENTE_FACTURA: TStringField;
    cdsCabeceraCPOSTAL_CLIENTE_FACTURA: TStringField;
    cdsCabeceraCODIGO_PAIS_CLIENTE_FACTURA: TStringField;
    cdsCabeceraNOMBRE_PAIS_CLIENTE_FACTURA: TStringField;
    cdsCabeceraCODIGO_IVA_FACTURA: TStringField;
    cdsCabeceraESIVA_RECARGO_CLIENTE_FACTURA: TStringField;
    cdsCabeceraESIVA_EXENTO_CLIENTE_FACTURA: TStringField;
    cdsCabeceraESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA: TStringField;
    cdsCabeceraESRETENCIONES_CLIENTE_FACTURA: TStringField;
    cdsCabeceraTARIFA_ARTICULO_CLIENTE_FACTURA: TStringField;
    cdsCabeceraESIMP_INCL_TARIFA_CLIENTE_FACTURA: TStringField;
    cdsCabeceraESINTRACOMUNITARIO_CLIENTE_FACTURA: TStringField;
    cdsCabeceraESIRPF_IMP_INCL_ZONA_IVA_FACTURA: TStringField;
    cdsCabeceraESAPLICA_RE_ZONA_IVA_FACTURA: TStringField;
    cdsCabeceraESIVAAGRICOLA_ZONA_IVA_FACTURA: TStringField;
    cdsCabeceraPALABRA_REPORTS_ZONA_IVA_FACTURA: TStringField;
    cdsCabeceraESVENTA_ACTIVO_FIJO_FACTURA: TStringField;
    cdsCabeceraPORCEN_IVAN_FACTURA: TBCDField;
    cdsCabeceraTOTAL_BASEI_IVAN_FACTURA: TBCDField;
    cdsCabeceraTOTAL_IVAN_FACTURA: TBCDField;
    cdsCabeceraPORCEN_REN_FACTURA: TBCDField;
    cdsCabeceraTOTAL_REN_FACTURA: TBCDField;
    cdsCabeceraPORCEN_IVAR_FACTURA: TBCDField;
    cdsCabeceraTOTAL_BASEI_IVAR_FACTURA: TBCDField;
    cdsCabeceraTOTAL_IVAR_FACTURA: TBCDField;
    cdsCabeceraPORCEN_RER_FACTURA: TBCDField;
    cdsCabeceraTOTAL_RER_FACTURA: TBCDField;
    cdsCabeceraPORCEN_IVAS_FACTURA: TBCDField;
    cdsCabeceraTOTAL_BASEI_IVAS_FACTURA: TBCDField;
    cdsCabeceraTOTAL_IVAS_FACTURA: TBCDField;
    cdsCabeceraPORCEN_RES_FACTURA: TBCDField;
    cdsCabeceraTOTAL_RES_FACTURA: TBCDField;
    cdsCabeceraPORCEN_IVAE_FACTURA: TBCDField;
    cdsCabeceraTOTAL_BASEI_IVAE_FACTURA: TBCDField;
    cdsCabeceraTOTAL_IVAE_FACTURA: TBCDField;
    cdsCabeceraPORCEN_REE_FACTURA: TBCDField;
    cdsCabeceraTOTAL_REE_FACTURA: TBCDField;
    cdsCabeceraTOTAL_BASES_FACTURA: TBCDField;
    cdsCabeceraTOTAL_IMPUESTOS_FACTURA: TBCDField;
    cdsCabeceraPORCEN_RETENCION_FACTURA: TBCDField;
    cdsCabeceraTOTAL_RETENCION_FACTURA: TBCDField;
    cdsCabeceraTOTAL_LIQUIDO_FACTURA: TBCDField;
    cdsCabeceraNRO_FACTURA_ABONO_FACTURA: TStringField;
    cdsCabeceraSERIE_FACTURA_ABONO_FACTURA: TStringField;
    cdsCabeceraFORMA_PAGO_FACTURA: TStringField;
    cdsCabeceraTEXTO_LEGAL_FACTURA_CLIENTE_FACTURA: TStringField;
    cdsCabeceraTEXTO_LEGAL_FACTURA_EMPRESA_FACTURA: TStringField;
    cdsCabeceraCOMENTARIOS_FACTURA: TStringField;
    cdsCabeceraCONTADOR_LINEAS_FACTURA: TStringField;
    cdsCabeceraESCREARARTICULOS_FACTURA: TStringField;
    cdsCabeceraESDESCRIPCIONES_AMP_FACTURA: TStringField;
    cdsCabeceraESFECHADEENTREGA_FACTURA: TStringField;
    cdsCabeceraXML_FACTURA: TMemoField;
    cdsCabeceraINSTANTEALTA: TDateTimeField;
    cdsCabeceraINSTANTEMODIF: TDateTimeField;
    cdsCabeceraUSUARIOALTA: TStringField;
    cdsCabeceraUSUARIOMODIF: TStringField;
    cdsLineasNRO_FACTURA_LINEA: TStringField;
    cdsLineasSERIE_FACTURA_LINEA: TStringField;
    cdsLineasLINEA_FACTURA_LINEA: TStringField;
    cdsLineasCODIGO_EMPLEADO: TStringField;
    cdsLineasCODIGO_ARTICULO_FACTURA_LINEA: TStringField;
    cdsLineasDESCRIPCION_ARTICULO_FACTURA_LINEA: TStringField;
    cdsLineasCODIGO_FAMILIA_FACTURA_LINEA: TStringField;
    cdsLineasNOMBRE_FAMILIA_FACTURA_LINEA: TStringField;
    cdsLineasCANTIDAD_FACTURA_LINEA: TBCDField;
    cdsLineasTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TStringField;
    cdsLineasPRECIOSALIDA_FACTURA_LINEA: TBCDField;
    cdsLineasPORCEN_DTO_FACTURA_LINEA: TBCDField;
    cdsLineasPRECIO_DTO_FACTURA_LINEA: TBCDField;
    cdsLineasPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TBCDField;
    cdsLineasPORCEN_IVA_FACTURA_LINEA: TBCDField;
    cdsLineasPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TBCDField;
    cdsLineasTIPOIVA_ARTICULO_FACTURA_LINEA: TStringField;
    cdsLineasTOTAL_FACTURA_LINEA: TBCDField;
    cdsLineasTOTAL_FACTURASIVA_LINEA: TBCDField;
    cdsLineasESIMP_INCL_TARIFA_FACTURA_LINEA: TStringField;
    cdsLineasCODIGO_TARIFA_FACTURA_LINEA: TStringField;
    cdsLineasPRECIO_ULT_COMPRA_FACTURA_LINEA: TBCDField;
    cdsLineasCODIGO_PROVEEDOR_FACTURA_LINEA: TStringField;
    cdsLineasRAZONSOCIAL_PROVEEDOR_FACTURA_LINEA: TStringField;
    cdsLineasESPROVEEDORPRINCIPAL_FACTURA_LINEA: TStringField;
    cdsLineasFECHA_ENTREGA_FACTURA_LINEA: TDateTimeField;
    cdsLineasINSTANTEALTA: TDateTimeField;
    cdsLineasINSTANTEMODIF: TDateTimeField;
    cdsLineasUSUARIOALTA: TStringField;
    cdsLineasUSUARIOMODIF: TStringField;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dmDataCaja: TdmDataCaja;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
