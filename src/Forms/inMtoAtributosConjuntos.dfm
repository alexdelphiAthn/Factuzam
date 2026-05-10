inherited frmMtoAtributosConjuntos: TfrmMtoAtributosConjuntos
  Caption = 'Colecciones de Atributos'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinID_AC: TcxGridDBColumn
              Caption = 'ID Conjunto'
              DataBinding.FieldName = 'ID_AC'
              Options.Editing = False
              Width = 100
            end
            object cxGrdDBTabPrinNOMBRE_AC: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_AC'
              Width = 280
            end
            object cxGrdDBTabPrinID_VAR_AC: TcxGridDBColumn
              Caption = 'Variaci'#243'n'
              DataBinding.FieldName = 'ID_VAR_AC'
              Width = 130
            end
            object cxGrdDBTabPrinID_VA_AC: TcxGridDBColumn
              Caption = 'Atributo'
              DataBinding.FieldName = 'ID_VA_AC'
              Width = 130
            end
            object cxGrdDBTabPrinESACTIVO_AC: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_AC'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object cxGrdDBTabPrinINSTANTE_ALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTE_ALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTE_MODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTE_MODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIO_ALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIO_MODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIO_MODIF'
              Options.Editing = False
              Visible = False
              Width = 130
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 943
          Height = 105
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 105
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblNombre: TcxLabel
              Left = 16
              Top = 16
              Caption = 'Nombre'
              TabOrder = 4
              Transparent = True
            end
            object txtNOMBRE_AC: TcxDBTextEdit
              Left = 120
              Top = 13
              DataBinding.DataField = 'NOMBRE_AC'
              DataBinding.DataSource = dsTablaG
              TabOrder = 0
              Width = 360
            end
            object chkESACTIVO_AC: TcxDBCheckBox
              Left = 500
              Top = 16
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_AC'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 1
              Transparent = True
            end
            object lblIdVar: TcxLabel
              Left = 16
              Top = 48
              Caption = 'Variaci'#243'n'
              TabOrder = 5
              Transparent = True
            end
            object txtID_VAR_AC: TcxDBTextEdit
              Left = 120
              Top = 45
              DataBinding.DataField = 'ID_VAR_AC'
              DataBinding.DataSource = dsTablaG
              TabOrder = 2
              Width = 140
            end
            object lblIdVa: TcxLabel
              Left = 280
              Top = 48
              Caption = 'Atributo'
              TabOrder = 6
              Transparent = True
            end
            object txtID_VA_AC: TcxDBTextEdit
              Left = 360
              Top = 45
              DataBinding.DataField = 'ID_VA_AC'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 120
            end
            object lblIdAc: TcxLabel
              Left = 16
              Top = 78
              Caption = 'ID Conjunto'
              TabOrder = 7
              Transparent = True
            end
            object txtID_AC: TcxDBTextEdit
              Left = 120
              Top = 75
              DataBinding.DataField = 'ID_AC'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 8
              Width = 100
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 105
          Width = 943
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 113
          Width = 943
          Height = 371
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 943
            Height = 371
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsValores
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 367
            ClientRectLeft = 4
            ClientRectRight = 939
            ClientRectTop = 30
            object tsValores: TcxTabSheet
              Caption = '&1_Valores'
              ImageIndex = 0
              object cxgrdValores: TcxGrid
                Left = 0
                Top = 0
                Width = 935
                Height = 337
                Align = alClient
                TabOrder = 0
                object tvValores: TcxGridDBTableView
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Visible = True
                  DataController.DataModeController.SmartRefresh = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsCustomize.ColumnGrouping = False
                  OptionsData.Appending = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  OptionsView.NoDataToDisplayInfoText = '<No hay valores en este conjunto>'
                  object tvValoresID_AC_ACD: TcxGridDBColumn
                    Caption = 'ID Conjunto'
                    DataBinding.FieldName = 'ID_AC_ACD'
                    Options.Editing = False
                    Visible = False
                    Width = 110
                  end
                  object tvValoresID_AV_ACD: TcxGridDBColumn
                    Caption = 'ID Valor'
                    DataBinding.FieldName = 'ID_AV_ACD'
                    Width = 100
                  end
                  object tvValoresAV: TcxGridDBColumn
                    Caption = 'Valor'
                    DataBinding.FieldName = 'AV'
                    Options.Editing = False
                    Width = 160
                  end
                  object tvValoresDESCRIPCION_AV: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_AV'
                    Options.Editing = False
                    Width = 280
                  end
                  object tvValoresESACTIVO_AV: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_AV'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Options.Editing = False
                    Width = 70
                  end
                  object tvValoresORDEN_ACD: TcxGridDBColumn
                    Caption = 'Orden'
                    DataBinding.FieldName = 'ORDEN_ACD'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 100
                  end
                end
                object cxgrdlvlValores: TcxGridLevel
                  GridView = tvValores
                end
              end
            end
            object tsAuditoria: TcxTabSheet
              Caption = '&2_Otros'
              ImageIndex = 1
              object pnlAuditoria: TPanel
                Left = 0
                Top = 0
                Width = 935
                Height = 337
                Align = alClient
                BevelOuter = bvNone
                TabOrder = 0
                object lblUsuarioAlta: TcxLabel
                  Left = 16
                  Top = 16
                  Caption = 'Usuario Alta'
                  TabOrder = 4
                  Transparent = True
                end
                object txtUSUARIOALTA: TcxDBTextEdit
                  Left = 160
                  Top = 13
                  DataBinding.DataField = 'USUARIO_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Width = 200
                end
                object lblInstanteAlta: TcxLabel
                  Left = 16
                  Top = 48
                  Caption = 'Instante Alta'
                  TabOrder = 5
                  Transparent = True
                end
                object txtINSTANTEALTA: TcxDBTextEdit
                  Left = 160
                  Top = 45
                  DataBinding.DataField = 'INSTANTE_ALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 1
                  Width = 200
                end
                object lblUsuarioModif: TcxLabel
                  Left = 400
                  Top = 16
                  Caption = 'Usuario Modificaci'#243'n'
                  TabOrder = 6
                  Transparent = True
                end
                object txtUSUARIOMODIF: TcxDBTextEdit
                  Left = 560
                  Top = 13
                  DataBinding.DataField = 'USUARIO_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Width = 200
                end
                object lblInstanteModif: TcxLabel
                  Left = 400
                  Top = 48
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 7
                  Transparent = True
                end
                object txtINSTANTEMODIF: TcxDBTextEdit
                  Left = 560
                  Top = 45
                  DataBinding.DataField = 'INSTANTE_MODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 200
                end
              end
            end
          end
        end
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 240
          ExplicitWidth = 240
        end
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmAtributosConjuntos.unqryTablaG
    OnStateChange = dsTablaGStateChange
  end
end
