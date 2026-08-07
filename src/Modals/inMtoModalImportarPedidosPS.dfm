inherited frmModalImportarPedidosPS: TfrmModalImportarPedidosPS
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Importar pedidos de PrestaShop'
  ClientHeight = 540
  ClientWidth = 920
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 920
    Height = 90
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblBaseURL: TcxLabel
      Left = 8
      Top = 8
      Caption = 'URL base API PrestaShop (ej. http://midominio.com/api)'
      TabOrder = 3
      Transparent = True
    end
    object edtBaseURL: TcxTextEdit
      Left = 8
      Top = 28
      TabOrder = 0
      Width = 540
    end
    object lblApiKey: TcxLabel
      Left = 8
      Top = 50
      Caption = 'API Key'
      TabOrder = 4
      Transparent = True
    end
    object edtApiKey: TcxTextEdit
      Left = 8
      Top = 64
      Properties.EchoMode = eemPassword
      TabOrder = 1
      Width = 540
    end
    object btnConectar: TcxButton
      Left = 560
      Top = 26
      Width = 140
      Height = 30
      Caption = 'Conectar y listar'
      TabOrder = 2
      OnClick = btnConectarClick
    end
  end
  object pnlMid: TPanel
    Left = 0
    Top = 90
    Width = 920
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdPedidos: TcxGrid
      Left = 0
      Top = 0
      Width = 920
      Height = 400
      Align = alClient
      TabOrder = 0
      object tvPedidos: TcxGridTableView
        OptionsView.GroupByBox = False
        object colSel: TcxGridColumn
          Caption = 'Sel.'
          PropertiesClassName = 'TcxCheckBoxProperties'
          Width = 50
        end
        object colId: TcxGridColumn
          Caption = 'ID PS'
          Width = 70
        end
        object colRef: TcxGridColumn
          Caption = 'Referencia'
          Width = 110
        end
        object colFecha: TcxGridColumn
          Caption = 'Fecha'
          Width = 130
        end
        object colCliente: TcxGridColumn
          Caption = 'Cliente'
          Width = 220
        end
        object colTotal: TcxGridColumn
          Caption = 'Total'
          Width = 100
        end
        object colEstado: TcxGridColumn
          Caption = 'Estado'
          Width = 160
        end
        object colImportado: TcxGridColumn
          Caption = 'Importado?'
          Width = 80
        end
      end
      object cxgrdlvlPedidos: TcxGridLevel
        GridView = tvPedidos
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 490
    Width = 920
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblEstado: TcxLabel
      Left = 8
      Top = 14
      Caption = 'Listo'
      TabOrder = 2
      Transparent = True
    end
    object btnImportar: TcxButton
      Left = 627
      Top = 12
      Width = 153
      Height = 28
      Caption = 'Importar selecci'#243'n'
      TabOrder = 0
      OnClick = btnImportarClick
    end
    object btnCerrar: TcxButton
      Left = 790
      Top = 12
      Width = 100
      Height = 28
      Caption = 'Cerrar'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
end
