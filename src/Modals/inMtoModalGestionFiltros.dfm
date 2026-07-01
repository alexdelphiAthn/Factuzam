object frmModalGestionFiltros: TfrmModalGestionFiltros
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Filtros guardados'
  ClientHeight = 448
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Pitch = fpFixed
  Font.Style = []
  Font.Quality = fqClearTypeNatural
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object lblCompartidoCon: TcxLabel
    Left = 8
    Top = 236
    Caption = 'Compartido con'
    TabOrder = 1
    Transparent = True
  end
  object cxgrdFiltros: TcxGrid
    Left = 8
    Top = 8
    Width = 744
    Height = 220
    TabOrder = 0
    object tvFiltros: TcxGridDBTableView
      OnDblClick = tvFiltrosDblClick
      OnFocusedRecordChanged = tvFiltrosFocusedRecordChanged
      DataController.KeyFieldNames = 'ID_FILT'
      OptionsBehavior.FocusCellOnTab = True
      OptionsBehavior.GoToNextCellOnEnter = True
      OptionsSelection.CellSelect = False
      OptionsData.Editing = False
      OptionsData.Inserting = False
      OptionsData.Deleting = False
      object tvFiltrosNOMBRE_FILT: TcxGridDBColumn
        Caption = 'Nombre'
        DataBinding.FieldName = 'NOMBRE_FILT'
        Options.Editing = False
        Width = 200
      end
      object tvFiltrosDESCRIPCION_FILT: TcxGridDBColumn
        Caption = 'Descripcion'
        DataBinding.FieldName = 'DESCRIPCION_FILT'
        Options.Editing = False
        Width = 340
      end
      object tvFiltrosUSUARIO_PROPIETARIO_FILT: TcxGridDBColumn
        Caption = 'Propietario'
        DataBinding.FieldName = 'USUARIO_PROPIETARIO_FILT'
        Options.Editing = False
        Width = 180
      end
    end
    object lvlFiltros: TcxGridLevel
      GridView = tvFiltros
    end
  end
  object lbCompartidoCon: TcxListBox
    Left = 8
    Top = 254
    Width = 744
    Height = 100
    TabOrder = 2
  end
  object btnCompartirUsuario: TcxButton
    Left = 8
    Top = 364
    Width = 170
    Height = 25
    Caption = 'Compartir con &usuario...'
    TabOrder = 3
    OnClick = btnCompartirUsuarioClick
  end
  object btnCompartirGrupo: TcxButton
    Left = 186
    Top = 364
    Width = 170
    Height = 25
    Caption = 'Compartir con &grupo...'
    TabOrder = 4
    OnClick = btnCompartirGrupoClick
  end
  object btnCompartirTodos: TcxButton
    Left = 364
    Top = 364
    Width = 170
    Height = 25
    Caption = 'Compartir con &todos'
    TabOrder = 5
    OnClick = btnCompartirTodosClick
  end
  object btnQuitarCompartido: TcxButton
    Left = 542
    Top = 364
    Width = 210
    Height = 25
    Caption = '&Quitar destino seleccionado'
    TabOrder = 6
    OnClick = btnQuitarCompartidoClick
  end
  object btnAplicar: TcxButton
    Left = 8
    Top = 404
    Width = 120
    Height = 28
    Caption = '&Aplicar'
    Default = True
    TabOrder = 7
    OnClick = btnAplicarClick
  end
  object btnRenombrar: TcxButton
    Left = 136
    Top = 404
    Width = 120
    Height = 28
    Caption = '&Renombrar...'
    TabOrder = 8
    OnClick = btnRenombrarClick
  end
  object btnBorrar: TcxButton
    Left = 264
    Top = 404
    Width = 120
    Height = 28
    Caption = 'Bo&rrar'
    TabOrder = 9
    OnClick = btnBorrarClick
  end
  object btnCerrar: TcxButton
    Left = 632
    Top = 404
    Width = 120
    Height = 28
    Cancel = True
    Caption = '&Cerrar'
    TabOrder = 10
    OnClick = btnCerrarClick
  end
end
