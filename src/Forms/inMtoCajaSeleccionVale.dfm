object frmMtoCajaSeleccionVale: TfrmMtoCajaSeleccionVale
  Left = 0
  Top = 0
  Caption = 'Seleccionar Vale'
  ClientHeight = 520
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -17
  Font.Name = 'Lucida Sans'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 19
  object pnlPrincipal: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 520
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 754
    ExplicitHeight = 511
    object pnlSuperior: TPanel
      Left = 0
      Top = 0
      Width = 760
      Height = 60
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 754
      object lblBuscar: TcxLabel
        Left = 8
        Top = 20
        Caption = 'Buscar vale:'
        TabOrder = 3
        Transparent = True
      end
      object edtBuscar: TcxTextEdit
        Left = 117
        Top = 16
        TabOrder = 0
        OnKeyDown = edtBuscarPropertiesKeyDown
        Width = 233
      end
      object btnBuscar: TcxButton
        Left = 360
        Top = 15
        Width = 113
        Height = 26
        Caption = 'Buscar [Enter]'
        TabOrder = 1
        OnClick = btnBuscarClick
      end
      object lblPin: TcxLabel
        Left = 508
        Top = 18
        Caption = 'PIN:'
        TabOrder = 4
        Transparent = True
      end
      object edtPin: TcxTextEdit
        Left = 542
        Top = 14
        Properties.EchoMode = eemPassword
        TabOrder = 2
        Width = 120
      end
    end
    object cxgrdVales: TcxGrid
      Left = 0
      Top = 60
      Width = 760
      Height = 400
      Align = alClient
      TabOrder = 1
      ExplicitWidth = 754
      ExplicitHeight = 391
      object dbtvVales: TcxGridDBTableView
        OnDblClick = dbtvValesDblClick
        OnFocusedRecordChanged = dbtvValesFocusedRecordChanged
        DataController.DataSource = dsVales
        DataController.KeyFieldNames = 'CODIGO_VL'
        OptionsBehavior.FocusCellOnTab = True
        OptionsBehavior.GoToNextCellOnEnter = True
        OptionsSelection.CellSelect = False
        object colCodigo: TcxGridDBColumn
          Caption = 'C'#243'digo Vale'
          DataBinding.FieldName = 'CODIGO_VL'
          Options.Editing = False
          Width = 180
        end
        object colEstado: TcxGridDBColumn
          Caption = 'Estado'
          DataBinding.FieldName = 'ESTADO_VL'
          Options.Editing = False
          Width = 80
        end
        object colImporte: TcxGridDBColumn
          Caption = 'Importe'
          DataBinding.FieldName = 'IMPORTE_NOMINAL_VL'
          Options.Editing = False
          Width = 90
        end
        object colFechaEmision: TcxGridDBColumn
          Caption = 'Fecha emisi'#243'n'
          DataBinding.FieldName = 'FECHA_EMISION_VL'
          Options.Editing = False
          Width = 139
        end
        object colCaducidad: TcxGridDBColumn
          Caption = 'Caducidad'
          DataBinding.FieldName = 'FECHA_CADUCIDAD_VL'
          Options.Editing = False
          Width = 124
        end
        object colObservaciones: TcxGridDBColumn
          Caption = 'Observaciones'
          DataBinding.FieldName = 'OBSERVACIONES_VL'
          Options.Editing = False
          Width = 160
        end
      end
      object cxgrdlvlVales: TcxGridLevel
        GridView = dbtvVales
      end
    end
    object pnlBotones: TPanel
      Left = 0
      Top = 460
      Width = 760
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      ExplicitTop = 451
      ExplicitWidth = 754
      object btnAceptar: TcxButton
        Left = 480
        Top = 14
        Width = 120
        Height = 32
        Caption = 'Aceptar'
        Default = True
        TabOrder = 0
        OnClick = btnAceptarClick
      end
      object btnCancelar: TcxButton
        Left = 614
        Top = 14
        Width = 120
        Height = 32
        Cancel = True
        Caption = 'Cancelar'
        TabOrder = 1
        OnClick = btnCancelarClick
      end
      object btnF1: TcxButton
        Left = 480
        Top = 14
        Width = 40
        Height = 32
        Caption = 'F1'
        TabOrder = 2
        Visible = False
        OnClick = btnAceptarClick
      end
      object btnF2: TcxButton
        Left = 614
        Top = 14
        Width = 40
        Height = 32
        Caption = 'F2'
        TabOrder = 3
        Visible = False
        OnClick = btnCancelarClick
      end
    end
  end
  object dsVales: TDataSource
    Left = 680
    Top = 8
  end
end
