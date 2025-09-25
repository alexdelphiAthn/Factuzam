inherited frmMtoIvas: TfrmMtoIvas
  Caption = 'IVA'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsCustomize.ColumnExpressionEditing = True
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_IVA: TcxGridDBColumn
              Caption = 'C'#243'digo IVA'
              DataBinding.FieldName = 'CODIGO_IVA'
              Width = 111
            end
            object cxGrdDBTabPrinGRUPO_ZONA_IVA: TcxGridDBColumn
              Caption = 'Zona IVA'
              DataBinding.FieldName = 'GRUPO_ZONA_IVA'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.DropDownListStyle = lsFixedList
              Properties.KeyFieldNames = 'GRUPO_ZONA_IVA'
              Properties.ListColumns = <
                item
                  MinWidth = 50
                  FieldName = 'GRUPO_ZONA_IVA'
                end
                item
                  FieldName = 'DESCRIPCION_ZONA_IVA'
                end>
              Properties.ListOptions.ShowHeader = False
              Properties.ListSource = dmIvas.dsZonas
              Width = 217
            end
            object cxGrdDBTabPrinDESCRIPCION_ZONA_IVA: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_ZONA_IVA'
              Width = 277
            end
            object cxGrdDBTabPrinPORCENNORMAL_IVA: TcxGridDBColumn
              Caption = '%Normal'
              DataBinding.FieldName = 'PORCENNORMAL_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 102
            end
            object cxGrdDBTabPrinPORCENNORMAL_RE_IVA: TcxGridDBColumn
              Caption = '%RE Normal'
              DataBinding.FieldName = 'PORCENNORMAL_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 121
            end
            object cxGrdDBTabPrinPORCENREDUCIDO_IVA: TcxGridDBColumn
              Caption = '% Reducido'
              DataBinding.FieldName = 'PORCENREDUCIDO_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 123
            end
            object cxGrdDBTabPrinPORCENREDUCIDO_RE_IVA: TcxGridDBColumn
              Caption = '%RE Reducido'
              DataBinding.FieldName = 'PORCENREDUCIDO_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 158
            end
            object cxGrdDBTabPrinPORCENSUPERREDUCIDO_IVA: TcxGridDBColumn
              Caption = '%S'#250'perReducido'
              DataBinding.FieldName = 'PORCENSUPERREDUCIDO_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 170
            end
            object cxGrdDBTabPrinPORCENSUPERREDUCIDO_RE_IVA: TcxGridDBColumn
              Caption = '%RE SuperReducido'
              DataBinding.FieldName = 'PORCENSUPERREDUCIDO_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 213
            end
            object cxGrdDBTabPrinPORCENEXENTO_IVA: TcxGridDBColumn
              Caption = '%Exento'
              DataBinding.FieldName = 'PORCENEXENTO_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 88
            end
            object cxGrdDBTabPrinPORCENEXENTO_RE_IVA: TcxGridDBColumn
              Caption = '%RE Exento'
              DataBinding.FieldName = 'PORCENEXENTO_RE_IVA'
              PropertiesClassName = 'TcxSpinEditProperties'
              Properties.DisplayFormat = '0.00 %'
              Properties.EditFormat = '0.00 %'
              Properties.MaxValue = 100.000000000000000000
              Width = 129
            end
            object cxGrdDBTabPrinFECHA_DESDE_IVA: TcxGridDBColumn
              Caption = 'Validez Desde'
              DataBinding.FieldName = 'FECHA_DESDE_IVA'
              Width = 138
            end
            object cxGrdDBTabPrinFECHA_HASTA_IVA: TcxGridDBColumn
              Caption = 'Validez Hasta'
              DataBinding.FieldName = 'FECHA_HASTA_IVA'
              Width = 121
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTEMODIF'
              Visible = False
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              DataBinding.FieldName = 'INSTANTEALTA'
              Visible = False
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIOALTA'
              Visible = False
            end
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              DataBinding.FieldName = 'USUARIOMODIF'
              Visible = False
            end
            object cxGrdDBTabPrinESAPLICA_RE_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESAPLICA_RE_ZONA_IVA'
              Visible = False
            end
            object cxGrdDBTabPrinESIVAAGRICOLA_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESIVAAGRICOLA_ZONA_IVA'
              Visible = False
            end
            object cxGrdDBTabPrinESDEFAULT_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESDEFAULT_ZONA_IVA'
              Visible = False
            end
            object cxGrdDBTabPrinESIRPF_IMP_INCL_ZONA_IVA: TcxGridDBColumn
              DataBinding.FieldName = 'ESIRPF_IMP_INCL_ZONA_IVA'
              Visible = False
            end
            object cxGrdDBTabPrinPALABRA_REPORTS_ZONA_IVA: TcxGridDBColumn
              Caption = 'Palabra IVA'
              DataBinding.FieldName = 'PALABRA_REPORTS_ZONA_IVA'
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        Enabled = False
        TabVisible = False
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmIvas.unqryTablaG
  end
end
