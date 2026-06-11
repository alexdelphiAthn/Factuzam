inherited frmModalVerEfectosRemesa: TfrmModalVerEfectosRemesa
  Caption = 'Efectos de la remesa'
  ClientHeight = 400
  ClientWidth = 780
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  ExplicitWidth = 780
  ExplicitHeight = 400
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 780
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblInfo: TcxLabel
      Left = 16
      Top = 10
      Caption = ' '
      Style.Font.Style = [fsBold]
      Style.IsFontAssigned = True
      Transparent = True
    end
  end
  object pnlGrid: TPanel [1]
    Left = 0
    Top = 40
    Width = 780
    Height = 304
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdEfe: TcxGrid
      Left = 0
      Top = 0
      Width = 780
      Height = 304
      Align = alClient
      TabOrder = 0
      object tvEfe: TcxGridDBTableView
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        object colSerieFac: TcxGridDBColumn
          Caption = 'Serie fra'
          DataBinding.FieldName = 'SERIE_FACC_EFEC'
          Width = 70
        end
        object colNumFac: TcxGridDBColumn
          Caption = 'Nro fra'
          DataBinding.FieldName = 'NUMERO_FACC_EFEC'
          Width = 70
        end
        object colNumEfe: TcxGridDBColumn
          Caption = 'Efecto'
          DataBinding.FieldName = 'NUMERO_EFEC'
          Width = 55
        end
        object colPrv: TcxGridDBColumn
          Caption = 'Proveedor'
          DataBinding.FieldName = 'RAZON_SOCIAL_PRV_EFEC'
          Width = 170
        end
        object colVto: TcxGridDBColumn
          Caption = 'Vencimiento'
          DataBinding.FieldName = 'FECHA_VENCIMIENTO_EFEC'
          Width = 100
        end
        object colImporte: TcxGridDBColumn
          Caption = 'Importe'
          DataBinding.FieldName = 'IMPORTE_EFEC'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Width = 90
        end
        object colPagado: TcxGridDBColumn
          Caption = 'Pagado'
          DataBinding.FieldName = 'IMPORTE_PAGADO_EFEC'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Width = 90
        end
        object colPend: TcxGridDBColumn
          Caption = 'Pendiente'
          DataBinding.FieldName = 'IMPORTE_PENDIENTE_EFEC'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Width = 90
        end
        object colEstado: TcxGridDBColumn
          Caption = 'Estado'
          DataBinding.FieldName = 'ESTADO_EFEC'
          Width = 90
        end
      end
      object lvlEfe: TcxGridLevel
        GridView = tvEfe
      end
    end
  end
  object pnlButton: TPanel [2]
    Left = 0
    Top = 344
    Width = 780
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCerrar: TcxButton
      Left = 606
      Top = 10
      Width = 150
      Height = 36
      Cancel = True
      Caption = '&Cerrar'
      Default = True
      TabOrder = 0
      OnClick = btnCerrarClick
    end
  end
end
