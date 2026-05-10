object frmModalFacturarAlbaranesFechas: TfrmModalFacturarAlbaranesFechas
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Facturar albaranes por fechas / serie'
  ClientHeight = 540
  ClientWidth = 980
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 90
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 0
    object lblSerie: TcxLabel
      Left = 8
      Top = 8
      Caption = 'Serie albar'#225'n'
    end
    object edtSerie: TcxTextEdit
      Left = 8
      Top = 28
      TabOrder = 0
      Width = 90
    end
    object lblFechaDesde: TcxLabel
      Left = 110
      Top = 8
      Caption = 'Fecha desde'
    end
    object dteDesde: TcxDateEdit
      Left = 110
      Top = 28
      TabOrder = 1
      Width = 130
    end
    object lblFechaHasta: TcxLabel
      Left = 252
      Top = 8
      Caption = 'Fecha hasta'
    end
    object dteHasta: TcxDateEdit
      Left = 252
      Top = 28
      TabOrder = 2
      Width = 130
    end
    object chkAgruparPorCliente: TcxCheckBox
      Left = 392
      Top = 28
      Caption = 'Una factura por cliente (consolidar)'
      TabOrder = 3
      Width = 240
    end
    object btnBuscar: TcxButton
      Left = 640
      Top = 26
      Width = 130
      Height = 30
      Caption = 'Buscar'
      OnClick = btnBuscarClick
      TabOrder = 4
      Style.Font.Style = [fsBold]
    end
  end
  object pnlMid: TPanel
    Left = 0
    Top = 90
    Width = 980
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object cxgrdAlbaranes: TcxGrid
      Left = 0
      Top = 0
      Width = 980
      Height = 400
      Align = alClient
      TabOrder = 0
      object tvAlbaranes: TcxGridTableView
        DataController.Summary.DefaultGroupSummaryItems = <>
        DataController.Summary.FooterSummaryItems = <>
        DataController.Summary.SummaryGroups = <>
        OptionsView.GroupByBox = False
        object colSel: TcxGridColumn
          Caption = 'Sel.'
          PropertiesClassName = 'TcxCheckBoxProperties'
          Width = 50
        end
        object colNumero: TcxGridColumn
          Caption = 'N'#250'mero'
          Width = 90
        end
        object colSerie: TcxGridColumn
          Caption = 'Serie'
          Width = 70
        end
        object colFecha: TcxGridColumn
          Caption = 'Fecha'
          Width = 110
        end
        object colCliente: TcxGridColumn
          Caption = 'C'#243'd. Cliente'
          Width = 100
        end
        object colRazonSocial: TcxGridColumn
          Caption = 'Raz'#243'n Social'
          Width = 290
        end
        object colTotal: TcxGridColumn
          Caption = 'Total'
          Width = 110
        end
      end
      object cxgrdlvlAlbaranes: TcxGridLevel
        GridView = tvAlbaranes
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 490
    Width = 980
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblEstado: TcxLabel
      Left = 8
      Top = 14
      Caption = 'Listo'
      Style.Font.Style = [fsItalic]
    end
    object btnSeleccionarTodos: TcxButton
      Left = 540
      Top = 12
      Width = 140
      Height = 28
      Caption = 'Marcar / Desmarcar'
      OnClick = btnSeleccionarTodosClick
      TabOrder = 0
    end
    object btnFacturar: TcxButton
      Left = 690
      Top = 12
      Width = 170
      Height = 28
      Caption = 'Generar facturas'
      OnClick = btnFacturarClick
      TabOrder = 1
      Style.Font.Style = [fsBold]
    end
    object btnCerrar: TcxButton
      Left = 870
      Top = 12
      Width = 100
      Height = 28
      Caption = 'Cerrar'
      OnClick = btnCerrarClick
      TabOrder = 2
    end
  end
  object qBuscar: TUniQuery
    SQL.Strings = (
      'SELECT 1')
    Left = 800
    Top = 56
  end
end
