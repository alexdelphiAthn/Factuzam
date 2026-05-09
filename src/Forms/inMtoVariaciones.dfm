inherited frmMtoVariaciones: TfrmMtoVariaciones
  Caption = 'Tipos de Variaciones'
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
            object cxGrdDBTabPrinCODIGO_VAR: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_VAR'
              Options.Editing = False
              Width = 110
            end
            object cxGrdDBTabPrinNOMBRE_VAR: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_VAR'
              Width = 320
            end
            object cxGrdDBTabPrinESACTIVO_VAR: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_VAR'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 80
            end
            object cxGrdDBTabPrinORDEN_VAR: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_VAR'
              PropertiesClassName = 'TcxSpinEditProperties'
              HeaderAlignmentHorz = taRightJustify
              Width = 90
            end
            object cxGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn
              Caption = 'Instante Alta'
              DataBinding.FieldName = 'INSTANTEALTA'
              Options.Editing = False
              Width = 150
            end
            object cxGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn
              Caption = 'Instante Modif'
              DataBinding.FieldName = 'INSTANTEMODIF'
              Options.Editing = False
              Visible = False
              Width = 150
            end
            object cxGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn
              Caption = 'Usuario Alta'
              DataBinding.FieldName = 'USUARIOALTA'
              Options.Editing = False
              Width = 130
            end
            object cxGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn
              Caption = 'Usuario Modif'
              DataBinding.FieldName = 'USUARIOMODIF'
              Options.Editing = False
              Visible = False
              Width = 130
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
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
    DataSet = dmVariaciones.unqryTablaG
    OnStateChange = dsTablaGStateChange
  end
end
