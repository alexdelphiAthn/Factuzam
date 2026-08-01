inherited frmModalAddBlockDocumentoTrabajo: TfrmModalAddBlockDocumentoTrabajo
  Caption = 'A'#241'adir Bloque - Documento de Trabajo'
  StyleElements = [seFont, seClient, seBorder]
  TextHeight = 19
  inherited pnlCabeceraExtra: TPanel
    Height = 64
    StyleElements = [seFont, seClient, seBorder]
    ExplicitHeight = 64
    object lblDocumentoInfo: TcxLabel
      Left = 12
      Top = 12
      Caption = 'Documento destino'
      TabOrder = 0
      Transparent = True
    end
    object lblNotaCarga: TcxLabel
      Left = 12
      Top = 38
      Caption = 
        'Se a'#241'adir'#225' una l'#237'nea por cada SKU con stock positivo en los alma' +
        'cenes seleccionados. La cantidad operativa quedar'#225' a 1.'
      Style.TextColor = clNavy
      TabOrder = 1
      Transparent = True
    end
  end
  inherited pnlCabeceraComun: TPanel
    Top = 64
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 64
    inherited chkExcluirYaCargados: TcxCheckBox
      Left = 221
      Top = 6
      ExplicitLeft = 221
      ExplicitTop = 6
    end
    inherited chkSoloConStock: TcxCheckBox
      Left = 494
      Top = 6
      ExplicitLeft = 494
      ExplicitTop = 6
    end
    inherited lblStockAviso: TcxLabel
      Left = 18
      Top = 30
      ExplicitLeft = 18
      ExplicitTop = 30
    end
    inherited btnPrevisualizar: TcxButton
      Left = 928
      Width = 122
      ExplicitLeft = 928
      ExplicitWidth = 122
    end
  end
  inherited pcFiltros: TcxPageControl
    Top = 114
    Height = 374
    ExplicitTop = 114
    ExplicitHeight = 374
    ClientRectBottom = 372
    inherited tsFamilias: TcxTabSheet
      inherited pnlFamiliasTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
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
        Height = 308
        ExplicitHeight = 308
      end
    end
    inherited tsProveedores: TcxTabSheet
      inherited pnlProveedoresTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
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
        Height = 308
        ExplicitHeight = 308
      end
    end
    inherited tsPropiedades: TcxTabSheet
      inherited pnlPropiedadesTop: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited cbxPropiedad: TcxComboBox
          Left = 165
          Top = 2
          ExplicitLeft = 165
          ExplicitTop = 2
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
        Height = 308
        ExplicitHeight = 308
      end
    end
    inherited tsAlmacenes: TcxTabSheet
      inherited pnlAlmacenesTop: TPanel
        Height = 113
        StyleElements = [seFont, seClient, seBorder]
        ExplicitHeight = 113
        inherited rgStockCombinacion: TcxRadioGroup
          Height = 65
          Width = 786
          ExplicitWidth = 786
          ExplicitHeight = 65
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
        Height = 230
        ExplicitTop = 113
        ExplicitHeight = 230
      end
    end
  end
  inherited pnlPreview: TPanel
    StyleElements = [seFont, seClient, seBorder]
  end
  inherited pnlBotonera: TPanel
    StyleElements = [seFont, seClient, seBorder]
  end
end
