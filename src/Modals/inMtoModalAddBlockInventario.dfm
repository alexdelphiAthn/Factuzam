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
    ExplicitWidth = 1178
    inherited chkSoloActivos: TcxCheckBox
      ExplicitWidth = 203
      ExplicitHeight = 23
    end
    inherited chkExcluirYaCargados: TcxCheckBox
      Left = 221
      Top = 6
      ExplicitLeft = 221
      ExplicitTop = 6
      ExplicitWidth = 265
      ExplicitHeight = 23
    end
    inherited chkSoloConStock: TcxCheckBox
      Left = 494
      Top = 6
      ExplicitLeft = 494
      ExplicitTop = 6
      ExplicitWidth = 225
      ExplicitHeight = 23
    end
    inherited btnPrevisualizar: TcxButton
      Left = 928
      Width = 122
      ExplicitLeft = 928
      ExplicitWidth = 122
    end
  end
  inherited pcFiltros: TcxPageControl
    Top = 120
    Height = 368
    ExplicitTop = 120
    ExplicitWidth = 1178
    ExplicitHeight = 360
    ClientRectBottom = 366
    inherited tsFamilias: TcxTabSheet
      ExplicitWidth = 1174
      ExplicitHeight = 329
      inherited pnlFamiliasTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1174
        inherited chkPropagarHijos: TcxCheckBox
          ExplicitWidth = 299
          ExplicitHeight = 23
        end
        inherited btnExpandirFamilias: TcxButton
          Left = 313
          ExplicitLeft = 313
        end
        inherited btnContraerFamilias: TcxButton
          Left = 409
          ExplicitLeft = 409
        end
        inherited btnQuitarSelFamilias: TcxButton
          Left = 505
          Width = 163
          ExplicitLeft = 505
          ExplicitWidth = 163
        end
        inherited lblSelFamilias: TcxLabel
          Left = 674
          Top = 6
          ExplicitLeft = 674
          ExplicitTop = 6
        end
      end
      inherited tlFamilias: TcxDBTreeList
        Height = 302
        ExplicitWidth = 1174
        ExplicitHeight = 294
      end
    end
    inherited tsProveedores: TcxTabSheet
      ExplicitHeight = 337
      inherited pnlProveedoresTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited edtFiltroProveedor: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited chkSoloPrincipal: TcxCheckBox
          ExplicitWidth = 268
          ExplicitHeight = 23
        end
        inherited btnQuitarSelProveedores: TcxButton
          Left = 544
          Width = 166
          ExplicitLeft = 544
          ExplicitWidth = 166
        end
        inherited lblSelProveedores: TcxLabel
          Left = 716
          Top = 6
          ExplicitLeft = 716
          ExplicitTop = 6
        end
      end
      inherited grdProveedores: TcxGrid
        Height = 302
        ExplicitWidth = 1176
        ExplicitHeight = 302
      end
    end
    inherited tsPropiedades: TcxTabSheet
      ExplicitHeight = 337
      inherited pnlPropiedadesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        ExplicitLeft = 32
        ExplicitTop = -6
        inherited cbxPropiedad: TcxComboBox
          Left = 165
          Top = 2
          ExplicitLeft = 165
          ExplicitTop = 2
          ExplicitHeight = 27
        end
        inherited btnQuitarSelPropiedades: TcxButton
          Left = 492
          Width = 155
          ExplicitLeft = 492
          ExplicitWidth = 155
        end
        inherited lblSelPropiedades: TcxLabel
          Left = 657
          Top = 6
          ExplicitLeft = 657
          ExplicitTop = 6
        end
      end
      inherited grdPropValores: TcxGrid
        Height = 302
        ExplicitWidth = 1176
        ExplicitHeight = 302
      end
    end
    inherited tsAlmacenes: TcxTabSheet
      ExplicitHeight = 337
      inherited pnlAlmacenesTop: TPanel
        Height = 113
        StyleElements = [seFont, seClient, seBorder]
        ExplicitHeight = 113
        inherited rgStockCombinacion: TcxRadioGroup
          ExplicitWidth = 786
          ExplicitHeight = 65
          Height = 65
          Width = 786
        end
        inherited btnMarcarTodosAlm: TcxButton
          Left = 470
          Top = 37
          ExplicitLeft = 470
          ExplicitTop = 37
        end
        inherited btnDesmarcarTodosAlm: TcxButton
          Left = 618
          Top = 37
          Width = 144
          ExplicitLeft = 618
          ExplicitTop = 37
          ExplicitWidth = 144
        end
        inherited lblSelAlmacenes: TcxLabel
          Top = 37
          ExplicitTop = 37
        end
      end
      inherited chkLstAlmacenes: TcxCheckListBox
        Top = 113
        Height = 224
        ExplicitHeight = 257
      end
    end
    inherited tsFechaAlta: TcxTabSheet
      ExplicitHeight = 337
      inherited chkAplicarFechaAlta: TcxCheckBox
        ExplicitWidth = 322
        ExplicitHeight = 23
      end
      inherited dtAltaDesde: TcxDateEdit
        ExplicitHeight = 27
      end
      inherited dtAltaHasta: TcxDateEdit
        ExplicitHeight = 27
      end
    end
    inherited tsVentas: TcxTabSheet
      ExplicitHeight = 337
      inherited chkConVenta: TcxCheckBox
        ExplicitWidth = 297
        ExplicitHeight = 23
      end
      inherited dtVtaDesde: TcxDateEdit
        ExplicitHeight = 27
      end
      inherited dtVtaHasta: TcxDateEdit
        ExplicitHeight = 27
      end
      inherited rgConSinVenta: TcxRadioGroup
        ExplicitHeight = 80
        Height = 80
      end
      inherited spnNumMinVtas: TcxSpinEdit
        Left = 252
        ExplicitLeft = 252
        ExplicitHeight = 27
      end
    end
  end
  inherited splitterPreview: TcxSplitter
    ExplicitTop = 480
    ExplicitWidth = 1178
  end
  inherited pnlPreview: TPanel
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 490
    ExplicitWidth = 1178
    inherited grdPreview: TcxGrid
      ExplicitTop = 0
      ExplicitWidth = 1178
      ExplicitHeight = 220
      inherited tvPreview: TcxGridDBTableView
        inherited colPrevFamilia: TcxGridDBColumn
          Width = 203
        end
        inherited colPrevYaCargado: TcxGridDBColumn
          Width = 110
        end
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
    ExplicitTop = 710
    ExplicitWidth = 1178
  end
end
