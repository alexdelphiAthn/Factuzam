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
            object cxGrdDBTabPrinID_CONJUNTO_AC: TcxGridDBColumn
              Caption = 'ID Conjunto'
              DataBinding.FieldName = 'ID_CONJUNTO_AC'
              Options.Editing = False
              Width = 100
            end
            object cxGrdDBTabPrinNOMBRE_AC: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_AC'
              Width = 280
            end
            object cxGrdDBTabPrinID_VARIACION_AC: TcxGridDBColumn
              Caption = 'Variaci'#243'n'
              DataBinding.FieldName = 'ID_VARIACION_AC'
              Width = 130
            end
            object cxGrdDBTabPrinID_ATRIBUTO_AC: TcxGridDBColumn
              Caption = 'Atributo'
              DataBinding.FieldName = 'ID_ATRIBUTO_AC'
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
    DataSet = dmAtributosConjuntos.unqryTablaG
    OnStateChange = dsTablaGStateChange
  end
end
