inherited frmMtoComprasPlantillas: TfrmMtoComprasPlantillas
  Caption = 'Plantillas de Sesiones de Compra'
  ClientHeight = 700
  ClientWidth = 1100
  OnCreate = FormCreate
  ExplicitWidth = 1100
  ExplicitHeight = 700
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 960
    Height = 700
    inherited pcPantalla: TcxPageControl
      Width = 960
      Height = 660
      ClientRectBottom = 656
      ClientRectRight = 956
      inherited tsLista: TcxTabSheet
        inherited cxgrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcCodigoSespl: TcxGridDBColumn
              Caption = 'C'#243'digo'
              DataBinding.FieldName = 'CODIGO_SESPL'
              Width = 100
            end
            object dbcNombreSespl: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_SESPL'
              Width = 250
            end
            object dbcCodigoPrvSespl: TcxGridDBColumn
              Caption = 'Proveedor'
              DataBinding.FieldName = 'CODIGO_PRV_SESPL'
              Width = 100
            end
            object dbcCodigoFamSespl: TcxGridDBColumn
              Caption = 'Familia'
              DataBinding.FieldName = 'CODIGO_FAM_SESPL'
              Width = 100
            end
            object dbcEsactivaSespl: TcxGridDBColumn
              Caption = 'Activa'
              DataBinding.FieldName = 'ESACTIVA_SESPL'
              Width = 70
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        object pcPlantilla: TcxPageControl
          Left = 0
          Top = 0
          Width = 952
          Height = 626
          Align = alClient
          TabOrder = 0
          Properties.ActivePage = tsDatos
          ClientRectBottom = 622
          ClientRectLeft = 4
          ClientRectRight = 948
          ClientRectTop = 30
          object tsDatos: TcxTabSheet
            Caption = 'Datos'
            object gbDatos: TcxGroupBox
              Left = 8
              Top = 8
              Width = 928
              Height = 580
              Caption = ' Cabecera de plantilla '
              TabOrder = 0
              object lblCodigo: TcxLabel
                Left = 16
                Top = 24
                Caption = 'C'#243'digo'
              end
              object txtCodigo: TcxDBTextEdit
                Left = 100
                Top = 22
                DataBinding.DataField = 'CODIGO_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 0
                Width = 120
              end
              object lblNombre: TcxLabel
                Left = 16
                Top = 60
                Caption = 'Nombre'
              end
              object txtNombre: TcxDBTextEdit
                Left = 100
                Top = 58
                DataBinding.DataField = 'NOMBRE_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 400
              end
              object lblDescripcion: TcxLabel
                Left = 16
                Top = 96
                Caption = 'Descripci'#243'n'
              end
              object txtDescripcion: TcxDBTextEdit
                Left = 100
                Top = 94
                DataBinding.DataField = 'DESCRIPCION_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 2
                Width = 700
              end
              object lblProveedor: TcxLabel
                Left = 16
                Top = 132
                Caption = 'Proveedor'
              end
              object cbbProveedor: TcxDBLookupComboBox
                Left = 100
                Top = 130
                DataBinding.DataField = 'CODIGO_PRV_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 3
                Width = 280
              end
              object lblFamilia: TcxLabel
                Left = 400
                Top = 132
                Caption = 'Familia'
              end
              object cbbFamilia: TcxDBLookupComboBox
                Left = 460
                Top = 130
                DataBinding.DataField = 'CODIGO_FAM_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 4
                Width = 200
              end
              object lblVariacion: TcxLabel
                Left = 16
                Top = 168
                Caption = 'Variaci'#243'n'
              end
              object cbbVariacion: TcxDBLookupComboBox
                Left = 100
                Top = 166
                DataBinding.DataField = 'CODIGO_VAR_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 5
                Width = 200
              end
              object chkVarFija: TcxDBCheckBox
                Left = 320
                Top = 166
                Caption = 'Variaci'#243'n fija por l'#237'nea'
                DataBinding.DataField = 'ESVAR_FIJA_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 6
                Width = 200
              end
              object lblConjPivot: TcxLabel
                Left = 16
                Top = 204
                Caption = 'Conj. pivot'
              end
              object cbbConjuntoPivot: TcxDBLookupComboBox
                Left = 100
                Top = 202
                DataBinding.DataField = 'ID_AC_PIVOT_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 7
                Width = 280
              end
              object lblConjFila: TcxLabel
                Left = 16
                Top = 240
                Caption = 'Conj. fila'
              end
              object cbbConjuntoFila: TcxDBLookupComboBox
                Left = 100
                Top = 238
                DataBinding.DataField = 'ID_AC_FILA_SESPL'
                DataBinding.DataSource = dsTablaG
                TabOrder = 8
                Width = 280
              end
              object chkActiva: TcxDBCheckBox
                Left = 16
                Top = 280
                Caption = 'Plantilla activa'
                DataBinding.DataField = 'ESACTIVA_SESPL'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 9
                Width = 200
              end
            end
          end
          object tsPropsPlantilla: TcxTabSheet
            Caption = 'Propiedades'
            object cxgrdProps: TcxGrid
              Left = 0
              Top = 36
              Width = 944
              Height = 552
              Align = alClient
              TabOrder = 0
              object tvProps: TcxGridDBTableView
                DataController.DataSource = nil
                Navigator.Buttons.CustomButtons = <>
                object dbcPropsCodigo: TcxGridDBColumn
                  Caption = 'C'#243'digo'
                  DataBinding.FieldName = 'CODIGO_PROP_SESPLPROP'
                end
                object dbcPropsFijo: TcxGridDBColumn
                  Caption = 'Fijo'
                  DataBinding.FieldName = 'ESFIJO_SESPLPROP'
                end
                object dbcPropsValor: TcxGridDBColumn
                  Caption = 'Valor por defecto'
                  DataBinding.FieldName = 'VALOR_DEFECTO_SESPLPROP'
                end
              end
              object glProps: TcxGridLevel
                GridView = tvProps
              end
            end
            object btnAddProp: TcxButton
              Left = 8
              Top = 4
              Width = 100
              Height = 28
              Caption = '+ A'#241'adir'
              TabOrder = 1
              OnClick = btnAddPropClick
            end
            object btnDelProp: TcxButton
              Left = 116
              Top = 4
              Width = 100
              Height = 28
              Caption = '- Borrar'
              TabOrder = 2
              OnClick = btnDelPropClick
            end
          end
          object tsKitsPlantilla: TcxTabSheet
            Caption = 'Kits'
            object cxgrdKits: TcxGrid
              Left = 0
              Top = 36
              Width = 400
              Height = 552
              Align = alLeft
              TabOrder = 0
              object tvKits: TcxGridDBTableView
                DataController.DataSource = nil
                Navigator.Buttons.CustomButtons = <>
                object dbcKitsCodigo: TcxGridDBColumn
                  Caption = 'C'#243'digo'
                  DataBinding.FieldName = 'CODIGO_SESPLKIT'
                end
                object dbcKitsNombre: TcxGridDBColumn
                  Caption = 'Nombre'
                  DataBinding.FieldName = 'NOMBRE_SESPLKIT'
                end
              end
              object glKits: TcxGridLevel
                GridView = tvKits
              end
            end
            object cxgrdKitsDet: TcxGrid
              Left = 400
              Top = 36
              Width = 544
              Height = 552
              Align = alClient
              TabOrder = 1
              object tvKitsDet: TcxGridDBTableView
                DataController.DataSource = nil
                Navigator.Buttons.CustomButtons = <>
                object dbcKitsDetValor: TcxGridDBColumn
                  Caption = 'Valor (talla)'
                  DataBinding.FieldName = 'VALOR_DESTINO_SESPLKITD'
                end
                object dbcKitsDetCantidad: TcxGridDBColumn
                  Caption = 'Cantidad'
                  DataBinding.FieldName = 'CANTIDAD_SESPLKITD'
                end
              end
              object glKitsDet: TcxGridLevel
                GridView = tvKitsDet
              end
            end
            object btnAddKit: TcxButton
              Left = 8
              Top = 4
              Width = 100
              Height = 28
              Caption = '+ Kit'
              TabOrder = 2
              OnClick = btnAddKitClick
            end
            object btnDelKit: TcxButton
              Left = 116
              Top = 4
              Width = 100
              Height = 28
              Caption = '- Kit'
              TabOrder = 3
              OnClick = btnDelKitClick
            end
          end
        end
      end
    end
  end
  object unqryPlantillas: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_plantillas'
      'ORDER BY NOMBRE_SESPL')
    Left = 12
    Top = 8
  end
  object unqryPlantillaProps: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_plantillas_props'
      'WHERE CODIGO_SESPL_SESPLPROP = :CODIGO_SESPL'
      'ORDER BY ORDEN_SESPLPROP')
    MasterSource = dsTablaG
    Left = 64
    Top = 8
  end
  object dsPlantillaProps: TDataSource
    DataSet = unqryPlantillaProps
    Left = 64
    Top = 56
  end
  object unqryPlantillaKits: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_plantillas_kits'
      'WHERE CODIGO_SESPL_SESPLKIT = :CODIGO_SESPL'
      'ORDER BY ORDEN_SESPLKIT')
    MasterSource = dsTablaG
    Left = 116
    Top = 8
  end
  object dsPlantillaKits: TDataSource
    DataSet = unqryPlantillaKits
    Left = 116
    Top = 56
  end
  object unqryPlantillaKitsDet: TUniQuery
    SQL.Strings = (
      'SELECT * FROM fza_compras_plantillas_kits_det'
      'WHERE CODIGO_SESPL_SESPLKITD = :CODIGO_SESPL_SESPLKIT'
      '  AND CODIGO_SESPLKIT_SESPLKITD = :CODIGO_SESPLKIT'
      'ORDER BY ORDEN_SESPLKITD')
    MasterSource = dsPlantillaKits
    Left = 168
    Top = 8
  end
  object dsPlantillaKitsDet: TDataSource
    DataSet = unqryPlantillaKitsDet
    Left = 168
    Top = 56
  end
end
