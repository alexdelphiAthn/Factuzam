inherited frmModalVerPagosEfecto: TfrmModalVerPagosEfecto
  Caption = 'Historico de pagos del efecto'
  ClientHeight = 380
  ClientWidth = 620
  StyleElements = [seFont, seClient, seBorder]
  OnCreate = FormCreate
  ExplicitWidth = 620
  ExplicitHeight = 380
  TextHeight = 19
  object pnlTop: TPanel [0]
    Left = 0
    Top = 0
    Width = 620
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
    Width = 620
    Height = 284
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdPagos: TcxGrid
      Left = 0
      Top = 0
      Width = 620
      Height = 284
      Align = alClient
      TabOrder = 0
      object tvPagos: TcxGridDBTableView
        OptionsData.Deleting = False
        OptionsData.Editing = False
        OptionsData.Inserting = False
        OptionsView.GroupByBox = False
        object colPagNum: TcxGridDBColumn
          Caption = 'Pago'
          DataBinding.FieldName = 'NUMERO_PAGO_EFECPAG'
          Width = 50
        end
        object colPagFecha: TcxGridDBColumn
          Caption = 'Fecha'
          DataBinding.FieldName = 'FECHA_EFECPAG'
          Width = 100
        end
        object colPagImporte: TcxGridDBColumn
          Caption = 'Importe'
          DataBinding.FieldName = 'IMPORTE_EFECPAG'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Width = 110
        end
        object colPagTipo: TcxGridDBColumn
          Caption = 'Tipo'
          DataBinding.FieldName = 'TIPO_EFECPAG'
          Width = 120
        end
        object colPagRef: TcxGridDBColumn
          Caption = 'Referencia'
          DataBinding.FieldName = 'REFERENCIA_EFECPAG'
          Width = 140
        end
        object colPagEntidad: TcxGridDBColumn
          Caption = 'Entidad'
          DataBinding.FieldName = 'ENTIDAD_PAGO_EFECPAG'
          Width = 140
        end
      end
      object lvlPagos: TcxGridLevel
        GridView = tvPagos
      end
    end
  end
  object pnlButton: TPanel [2]
    Left = 0
    Top = 324
    Width = 620
    Height = 56
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCerrar: TcxButton
      Left = 446
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
