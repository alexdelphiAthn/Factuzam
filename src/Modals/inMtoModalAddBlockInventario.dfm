inherited frmModalAddBlockInventario: TfrmModalAddBlockInventario
  Caption = 'A'#241'adir Bloque - Carga masiva en Inventario'
  OnCreate = FormCreate
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    Height = 70
    object lblInventarioInfo: TcxLabel
      Left = 12
      Top = 12
      Caption = 'Inventario destino'
      Style.Font.Style = [fsBold]
    end
    object lblNotaCarga: TcxLabel
      Left = 12
      Top = 38
      Caption = 'Se a'#241'adir'#225' una l'#237'nea por cada SKU con stock>0 en el almac'#233'n del inventario. Las cantidades te'#243'ricas se calcular'#225'n despu'#233's pulsando "Recalcular te'#243'rico/PMP".'
      Style.Font.Style = [fsItalic]
      Style.TextColor = clNavy
    end
  end
  inherited pnlPreview: TPanel
    inherited grdPreview: TcxGrid
      inherited tvPreview: TcxGridDBTableView
        object colPrevSkusConStock: TcxGridDBColumn
          DataBinding.FieldName = 'NUM_SKUS_CON_STOCK'
          Caption = 'SKUs c/ stock'
          Width = 90
          HeaderAlignmentHorz = taRightJustify
        end
        object colPrevPMPActual: TcxGridDBColumn
          DataBinding.FieldName = 'PMP_ACTUAL'
          Caption = 'PMP medio'
          Width = 90
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00'
        end
      end
    end
  end
end
