inherited frmModalAddBlockTarifa: TfrmModalAddBlockTarifa
  Caption = 'A'#241'adir Bloque - Carga masiva en Tarifa'
  OnCreate = FormCreate
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    object lblTarifa: TcxLabel
      Left = 12
      Top = 6
      Caption = 'Tarifa destino:'
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
      Width = 105
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
      Width = 110
    end
    object lblMultiplo: TcxLabel
      Left = 660
      Top = 32
      Caption = 'M'#250'ltiplo:'
    end
    object spnMultiplo: TcxCurrencyEdit
      Left = 720
      Top = 28
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00'
      Enabled = False
      TabOrder = 6
      Width = 60
    end
    object lblRestar: TcxLabel
      Left = 790
      Top = 32
      Caption = 'Restar:'
    end
    object spnRestar: TcxCurrencyEdit
      Left = 850
      Top = 28
      Properties.DecimalPlaces = 2
      Properties.DisplayFormat = '0.00'
      Enabled = False
      TabOrder = 7
      Width = 60
    end
    object rgAjusteAlcance: TcxRadioGroup
      Left = 920
      Top = 2
      Caption = ' Aplicar ajuste a '
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
      Enabled = False
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
      Width = 215
    end
    object cbxTarifaOrigen: TcxComboBox
      Left = 230
      Top = 58
      Properties.DropDownListStyle = lsFixedList
      Enabled = False
      TabOrder = 10
      Width = 220
    end
  end
  inherited pnlPreview: TPanel
    inherited grdPreview: TcxGrid
      inherited tvPreview: TcxGridDBTableView
        object colPrevPrecioSalidaOrig: TcxGridDBColumn
          DataBinding.FieldName = 'PRECIO_SALIDA_ORIG'
          Caption = 'P. Salida orig.'
          Width = 90
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00'
        end
        object colPrevPrecioFinalOrig: TcxGridDBColumn
          DataBinding.FieldName = 'PRECIO_FINAL_ORIG'
          Caption = 'P. Final orig.'
          Width = 90
          PropertiesClassName = 'TcxCurrencyEditProperties'
          Properties.DisplayFormat = '#,##0.00'
        end
      end
    end
  end
end
