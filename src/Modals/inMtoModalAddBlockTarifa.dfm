inherited frmModalAddBlockTarifa: TfrmModalAddBlockTarifa
  Caption = 'A'#241'adir Bloque - Carga masiva en Tarifa'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1182
    object lblTarifa: TcxLabel
      Left = 12
      Top = 6
      Caption = 'Tarifa destino:'
      TabOrder = 11
    end
    object cbxTarifa: TcxComboBox
      Left = 12
      Top = 28
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 0
      Width = 200
    end
    object lblFechaDesde: TcxLabel
      Left = 220
      Top = 6
      Caption = 'Fecha desde:'
      TabOrder = 12
    end
    object dtFechaDesde: TcxDateEdit
      Left = 220
      Top = 28
      TabOrder = 1
      Width = 110
    end
    object chkConFechaHasta: TcxCheckBox
      Left = 340
      Top = 28
      Caption = 'Fecha hasta:'
      Properties.OnChange = chkConFechaHastaPropertiesChange
      TabOrder = 2
    end
    object dtFechaHasta: TcxDateEdit
      Left = 450
      Top = 28
      Enabled = False
      TabOrder = 3
      Width = 110
    end
    object lblPorcenDto: TcxLabel
      Left = 580
      Top = 6
      Caption = '% Dto:'
      TabOrder = 13
    end
    object spnPorcenDto: TcxCurrencyEdit
      Left = 580
      Top = 28
      Properties.DisplayFormat = '0.00 %'
      TabOrder = 4
      Width = 65
    end
    object chkAjustarPrecio: TcxCheckBox
      Left = 660
      Top = 4
      Caption = 'Ajustar precio'
      Properties.OnChange = chkAjustarPrecioPropertiesChange
      TabOrder = 5
    end
    object lblMultiplo: TcxLabel
      Left = 660
      Top = 32
      Caption = 'M'#250'ltiplo:'
      TabOrder = 14
    end
    object spnMultiplo: TcxCurrencyEdit
      Left = 720
      Top = 28
      Enabled = False
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00'
      TabOrder = 6
      Width = 60
    end
    object lblRestar: TcxLabel
      Left = 790
      Top = 32
      Caption = 'Restar:'
      TabOrder = 15
    end
    object spnRestar: TcxCurrencyEdit
      Left = 850
      Top = 28
      Enabled = False
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00'
      TabOrder = 7
      Width = 60
    end
    object rgAjusteAlcance: TcxRadioGroup
      Left = 920
      Top = 2
      Caption = ' Aplicar ajuste a '
      Enabled = False
      Properties.Columns = 3
      Properties.Items = <
        item
          Caption = 'Final'
        end
        item
          Caption = 'Salida'
        end
        item
          Caption = 'Ambos'
        end>
      ItemIndex = 0
      TabOrder = 8
      Height = 50
      Width = 245
    end
    object chkCopiarDeTarifa: TcxCheckBox
      Left = 12
      Top = 60
      Caption = 'Copiar precios de tarifa'
      Properties.OnChange = chkCopiarDeTarifaPropertiesChange
      TabOrder = 9
    end
    object cbxTarifaOrigen: TcxComboBox
      Left = 230
      Top = 58
      Enabled = False
      Properties.DropDownListStyle = lsFixedList
      TabOrder = 10
      Width = 220
    end
  end
  inherited pnlCabeceraComun: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited chkSoloActivos: TcxCheckBox
      ExplicitWidth = 121
    end
    inherited chkExcluirYaCargados: TcxCheckBox
      ExplicitWidth = 121
    end
    inherited chkSoloConStock: TcxCheckBox
      ExplicitWidth = 121
    end
  end
  inherited pcFiltros: TcxPageControl
    inherited tsFamilias: TcxTabSheet
      ExplicitLeft = 2
      ExplicitTop = 29
      ExplicitWidth = 1176
      ExplicitHeight = 307
      inherited pnlFamiliasTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1176
        inherited chkPropagarHijos: TcxCheckBox
          ExplicitWidth = 121
        end
      end
    end
    inherited tsProveedores: TcxTabSheet
      ExplicitLeft = 2
      ExplicitTop = 29
      ExplicitWidth = 1176
      ExplicitHeight = 307
      inherited pnlProveedoresTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1176
        inherited chkSoloPrincipal: TcxCheckBox
          ExplicitWidth = 121
        end
      end
    end
    inherited tsPropiedades: TcxTabSheet
      ExplicitLeft = 2
      ExplicitTop = 29
      ExplicitWidth = 1176
      ExplicitHeight = 307
      inherited pnlPropiedadesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1176
      end
    end
    inherited tsAlmacenes: TcxTabSheet
      inherited pnlAlmacenesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    inherited tsFechaAlta: TcxTabSheet
      ExplicitLeft = 2
      ExplicitTop = 29
      ExplicitWidth = 1176
      ExplicitHeight = 307
      inherited chkAplicarFechaAlta: TcxCheckBox
        ExplicitWidth = 121
      end
    end
    inherited tsVentas: TcxTabSheet
      inherited chkConVenta: TcxCheckBox
        ExplicitWidth = 121
      end
    end
  end
  inherited pnlPreview: TPanel
    StyleElements = [seFont, seClient, seBorder]
    inherited grdPreview: TcxGrid
      inherited tvPreview: TcxGridDBTableView
        object colPrevPrecioSalidaOrig: TcxGridDBColumn
          Caption = 'P. Salida orig.'
          DataBinding.FieldName = 'PRECIO_SALIDA_ORIG'
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00'
          Width = 90
        end
        object colPrevPrecioFinalOrig: TcxGridDBColumn
          Caption = 'P. Final orig.'
          DataBinding.FieldName = 'PRECIO_FINAL_ORIG'
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
