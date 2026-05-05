inherited frmModalAddBlockInventario: TfrmModalAddBlockInventario
  Caption = 'A'#241'adir Bloque - Carga masiva en Inventario'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    Height = 70
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1178
    ExplicitHeight = 70
    object lblInventarioInfo: TcxLabel
      Left = 12
      Top = 12
      Caption = 'Inventario destino'
      TabOrder = 0
    end
    object lblNotaCarga: TcxLabel
      Left = 12
      Top = 38
      Caption = 
        'Se a'#241'adir'#225' una l'#237'nea por cada SKU con stock>0 en el almac'#233'n del ' +
        'inventario. Las cantidades te'#243'ricas se calcular'#225'n despu'#233's pulsan' +
        'do "Recalcular te'#243'rico/PMP".'
      Style.TextColor = clNavy
      TabOrder = 1
    end
  end
  inherited pnlCabeceraComun: TPanel
    Top = 70
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 70
  end
  inherited pcFiltros: TcxPageControl
    Top = 120
    Height = 368
    ExplicitTop = 120
    ExplicitHeight = 376
    ClientRectBottom = 366
    inherited tsFamilias: TcxTabSheet
      ExplicitHeight = 329
      inherited pnlFamiliasTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited tlFamilias: TcxDBTreeList
        Height = 302
        ExplicitHeight = 294
      end
    end
    inherited tsProveedores: TcxTabSheet
      ExplicitHeight = 337
      inherited pnlProveedoresTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited grdProveedores: TcxGrid
        Height = 302
        ExplicitHeight = 302
      end
    end
    inherited tsPropiedades: TcxTabSheet
      ExplicitHeight = 337
      inherited pnlPropiedadesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited grdPropValores: TcxGrid
        Height = 302
        ExplicitHeight = 302
      end
    end
    inherited tsAlmacenes: TcxTabSheet
      ExplicitHeight = 345
      inherited pnlAlmacenesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited chkLstAlmacenes: TcxCheckListBox
        Height = 257
        ExplicitHeight = 265
      end
    end
    inherited tsFechaAlta: TcxTabSheet
      ExplicitHeight = 337
    end
    inherited tsVentas: TcxTabSheet
      ExplicitHeight = 345
    end
  end
  inherited pnlPreview: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited grdPreview: TcxGrid
      inherited tvPreview: TcxGridDBTableView
        object colPrevSkusConStock: TcxGridDBColumn
          Caption = 'SKUs c/ stock'
          DataBinding.FieldName = 'NUM_SKUS_CON_STOCK'
          HeaderAlignmentHorz = taRightJustify
          Width = 90
        end
        object colPrevPMPActual: TcxGridDBColumn
          Caption = 'PMP medio'
          DataBinding.FieldName = 'PMP_ACTUAL'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00'
          Width = 90
        end
      end
    end
  end
  inherited pnlBotonera: TPanel
    StyleElements = [seFont, seClient, seBorder]
  end
end
