inherited frmMtoInventarios: TfrmMtoInventarios
  Caption = 'Mantenimiento de Inventarios'
  ClientHeight = 720
  ClientWidth = 1280
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1280
  ExplicitHeight = 720
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 1140
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 1140
    ExplicitHeight = 720
    inherited pcPantalla: TcxPageControl
      Width = 1140
      Height = 680
      ExplicitWidth = 1140
      ExplicitHeight = 680
      ClientRectBottom = 678
      ClientRectRight = 1138
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1136
        ExplicitHeight = 649
        inherited cxGrdPrincipal: TcxGrid
          Width = 1136
          Height = 649
          ExplicitWidth = 1136
          ExplicitHeight = 649
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 2
        ExplicitTop = 29
        ExplicitWidth = 1136
        ExplicitHeight = 649
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 1136
          Height = 174
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 1136
            Height = 174
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblEmpresa: TcxLabel
              Left = 32
              Top = 15
              Caption = 'Empresa'
              TabOrder = 0
            end
            object cbbCODIGO_EMPRESA_INVENTARIO: TcxDBLookupComboBox
              Left = 121
              Top = 11
              DataBinding.DataField = 'CODIGO_EMPRESA_INVENTARIO'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'CODIGO_EMPRESA'
              Properties.ListColumns = <
                item
                  Width = 80
                  FieldName = 'CODIGO_EMPRESA'
                end
                item
                  Width = 200
                  FieldName = 'RAZONSOCIAL_EMPRESA'
                end>
              TabOrder = 1
              Width = 280
            end
            object lblAlmacen: TcxLabel
              Left = 31
              Top = 47
              Caption = 'Almac'#233'n'
              TabOrder = 2
            end
            object cbbCODIGO_ALMACEN_INVENTARIO: TcxDBLookupComboBox
              Left = 121
              Top = 43
              DataBinding.DataField = 'CODIGO_ALMACEN_INVENTARIO'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'CODIGO_ALMACEN'
              Properties.ListColumns = <
                item
                  Width = 80
                  FieldName = 'CODIGO_ALMACEN'
                end
                item
                  Width = 200
                  FieldName = 'DESCRIPCION_ALMACEN'
                end>
              TabOrder = 3
              Width = 280
            end
            object lblSerie: TcxLabel
              Left = 62
              Top = 85
              Caption = 'Serie'
              TabOrder = 4
            end
            object cbbSERIE_INVENTARIO: TcxDBLookupComboBox
              Left = 121
              Top = 78
              DataBinding.DataField = 'SERIE_INVENTARIO'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'SERIE_SERIE'
              Properties.ListColumns = <
                item
                  Width = 100
                  FieldName = 'SERIE_SERIE'
                end>
              TabOrder = 5
              Width = 120
            end
            object lblNumero: TcxLabel
              Left = 35
              Top = 115
              Caption = 'N'#250'mero'
              TabOrder = 6
            end
            object txtNRO_INVENTARIO: TcxDBTextEdit
              Left = 121
              Top = 111
              DataBinding.DataField = 'NRO_INVENTARIO'
              DataBinding.DataSource = dsTablaG
              TabOrder = 7
              Width = 174
            end
            object lblFecha: TcxLabel
              Left = 353
              Top = 115
              Caption = 'Fecha'
              TabOrder = 8
            end
            object dtFECHA_INVENTARIO: TcxDBDateEdit
              Left = 418
              Top = 111
              DataBinding.DataField = 'FECHA_INVENTARIO'
              DataBinding.DataSource = dsTablaG
              TabOrder = 9
              Width = 228
            end
            object lblEstado: TcxLabel
              Left = 346
              Top = 85
              Caption = 'Estado'
              TabOrder = 10
            end
            object txtESTADO_INVENTARIO: TcxDBTextEdit
              Left = 418
              Top = 78
              DataBinding.DataField = 'ESTADO_INVENTARIO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 11
              Width = 228
            end
            object lblDescripcion: TcxLabel
              Left = 3
              Top = 144
              Caption = 'Descripci'#243'n'
              TabOrder = 12
            end
            object txtDESCRIPCION_INVENTARIO: TcxDBTextEdit
              Left = 121
              Top = 144
              DataBinding.DataField = 'DESCRIPCION_INVENTARIO'
              DataBinding.DataSource = dsTablaG
              TabOrder = 13
              Width = 457
            end
          end
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 184
          Width = 1136
          Height = 465
          Align = alClient
          TabOrder = 1
          object pcDetail: TcxPageControl
            Left = 1
            Top = 1
            Width = 1134
            Height = 463
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsDetalle
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 461
            ClientRectLeft = 2
            ClientRectRight = 1132
            ClientRectTop = 29
            object tsDetalle: TcxTabSheet
              Caption = '2. Detalle del inventario'
              ImageIndex = 1
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
              object pnlDetalleTop: TPanel
                Left = 0
                Top = 0
                Width = 1130
                Height = 50
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object btnAnadirLinea: TcxButton
                  Left = 7
                  Top = 11
                  Width = 130
                  Height = 30
                  Caption = '+ A'#241'adir l'#237'nea'
                  TabOrder = 0
                  OnClick = btnAnadirLineaClick
                end
                object btnEliminarLinea: TcxButton
                  Left = 147
                  Top = 11
                  Width = 154
                  Height = 30
                  Caption = '- Eliminar l'#237'nea'
                  TabOrder = 1
                  OnClick = btnEliminarLineaClick
                end
                object btnRecalcularDetalle: TcxButton
                  Left = 307
                  Top = 11
                  Width = 237
                  Height = 30
                  Caption = 'Recalcular te'#243'rico/PMP'
                  TabOrder = 2
                  OnClick = btnRecalcularDetalleClick
                end
                object btnCargarExcel: TcxButton
                  Left = 559
                  Top = 11
                  Width = 145
                  Height = 30
                  Caption = 'Cargar Excel'
                  TabOrder = 3
                  OnClick = btnCargarExcelClick
                end
                object btnExportarMovs: TcxButton
                  Left = 718
                  Top = 11
                  Width = 150
                  Height = 30
                  Caption = 'Exportar a Excel'
                  TabOrder = 4
                  OnClick = btnExportarMovsClick
                end
              end
              object cxgrdLineas: TcxGrid
                Left = 0
                Top = 50
                Width = 1130
                Height = 382
                Align = alClient
                TabOrder = 1
                object tvLineas: TcxGridDBTableView
                  OnEditing = tvLineasEditing
                  OnFocusedRecordChanged = tvLineasFocusedRecordChanged
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#,##0.00'
                      Kind = skSum
                      FieldName = 'CANTIDAD_DIFERENCIA_INVENTARIO_LINEA'
                    end
                    item
                      Format = '#,##0.00 '#8364
                      Kind = skSum
                      FieldName = 'TOTAL_COSTE_DIFERENCIA_LINEA'
                    end>
                  OptionsBehavior.IncSearch = True
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  object tvLineasLINEA: TcxGridDBColumn
                    Caption = 'L'#237'nea'
                    DataBinding.FieldName = 'LINEA_INVENTARIO_LINEA'
                    Options.Editing = False
                    Width = 68
                  end
                  object tvLineasARTICULO: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ARTICULO_INVENTARIO_LINEA'
                    Width = 130
                  end
                  object tvLineasUNIDAD: TcxGridDBColumn
                    Caption = 'SKU completo'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_INVENTARIO_LINEA'
                    Width = 180
                  end
                  object tvLineasDESCRIPCION: TcxGridDBColumn
                    Caption = 'Descripci'#243'n'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_INVENTARIO_LINEA'
                    Options.Editing = False
                    Width = 220
                  end
                  object tvLineasSKU1: TcxGridDBColumn
                    Tag = 1
                    Caption = 'SKU 1'
                    DataBinding.FieldName = 'ATTR1_VALOR'
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU2: TcxGridDBColumn
                    Tag = 2
                    Caption = 'SKU 2'
                    DataBinding.FieldName = 'ATTR2_VALOR'
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU3: TcxGridDBColumn
                    Tag = 3
                    Caption = 'SKU 3'
                    DataBinding.FieldName = 'ATTR3_VALOR'
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU4: TcxGridDBColumn
                    Tag = 4
                    Caption = 'SKU 4'
                    DataBinding.FieldName = 'ATTR4_VALOR'
                    Visible = False
                    Width = 80
                  end
                  object tvLineasSKU5: TcxGridDBColumn
                    Tag = 5
                    Caption = 'SKU 5'
                    DataBinding.FieldName = 'ATTR5_VALOR'
                    Visible = False
                    Width = 80
                  end
                  object tvLineasLOTE: TcxGridDBColumn
                    Caption = 'Lote'
                    DataBinding.FieldName = 'LOTE_INVENTARIO_LINEA'
                    Visible = False
                    Width = 80
                  end
                  object tvLineasCADUCIDAD: TcxGridDBColumn
                    Caption = 'Caducidad'
                    DataBinding.FieldName = 'FECHA_CADUCIDAD_INVENTARIO_LINEA'
                    Visible = False
                    Width = 90
                  end
                  object tvLineasUDS_TEORICAS: TcxGridDBColumn
                    Caption = 'Uds. te'#243'ricas'
                    DataBinding.FieldName = 'CANTIDAD_TEORICA_INVENTARIO_LINEA'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 141
                  end
                  object tvLineasUDS_FISICAS: TcxGridDBColumn
                    Caption = 'Recuento'
                    DataBinding.FieldName = 'CANTIDAD_FISICA_INVENTARIO_LINEA'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 110
                  end
                  object tvLineasPMP_ACTUAL: TcxGridDBColumn
                    Caption = 'PMP actual'
                    DataBinding.FieldName = 'PRECIO_MEDIO_INVENTARIO_LINEA'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 119
                  end
                  object tvLineasPMP_NUEVO: TcxGridDBColumn
                    Caption = 'PMP nuevo'
                    DataBinding.FieldName = 'PRECIO_MEDIO_NUEVO_INVENTARIO_LINEA'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 128
                  end
                  object tvLineasDIF_UNIDADES: TcxGridDBColumn
                    Caption = 'Dif. uds.'
                    DataBinding.FieldName = 'CANTIDAD_DIFERENCIA_INVENTARIO_LINEA'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 90
                  end
                  object tvLineasDIF_COSTE: TcxGridDBColumn
                    Caption = 'Dif. coste'
                    DataBinding.FieldName = 'TOTAL_COSTE_DIFERENCIA_LINEA'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 110
                  end
                  object tvLineasUDS_REGULARIZADAS: TcxGridDBColumn
                    Caption = 'Uds. regul.'
                    DataBinding.FieldName = 'UDS_REGULARIZADAS'
                    HeaderAlignmentHorz = taRightJustify
                    Options.Editing = False
                    Width = 116
                  end
                  object tvLineasFECHA_RECUENTO: TcxGridDBColumn
                    Caption = 'Hora recuento'
                    DataBinding.FieldName = 'FECHA_RECUENTO_INVENTARIO_LINEA'
                    Options.Editing = False
                    Width = 212
                  end
                  object tvLineasUSUARIO: TcxGridDBColumn
                    Caption = 'Usuario'
                    DataBinding.FieldName = 'USUARIOMODIF'
                    Visible = False
                    Options.Editing = False
                    Width = 110
                  end
                end
                object cxgrdlvlLineas: TcxGridLevel
                  GridView = tvLineas
                end
              end
            end
            object tsMovsRegul: TcxTabSheet
              Caption = '3. Movimientos regularizados'
              ImageIndex = 2
              object pnlMovsTop: TPanel
                Left = 0
                Top = 0
                Width = 1130
                Height = 50
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object lblInfoMovs: TcxLabel
                  Left = 16
                  Top = 16
                  Caption = 'Movimientos generados al aplicar este inventario en el Kardex'
                  TabOrder = 1
                end
                object btnEliminarRegularizacion: TcxButton
                  Left = 560
                  Top = 10
                  Width = 120
                  Height = 30
                  Caption = 'Eliminar regularizaci'#243'n'
                  TabOrder = 0
                  OnClick = btnEliminarRegularizacionClick
                end
              end
              object cxgrdMovs: TcxGrid
                Left = 0
                Top = 50
                Width = 1130
                Height = 382
                Align = alClient
                TabOrder = 1
                object tvMovs: TcxGridDBTableView
                  OptionsData.Deleting = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  object tvMovsNUMERO: TcxGridDBColumn
                    Caption = 'N'#250'mero'
                    DataBinding.FieldName = 'NUMERO_MOV'
                    Width = 160
                  end
                  object tvMovsTIPO: TcxGridDBColumn
                    Caption = 'Tipo'
                    DataBinding.FieldName = 'TIPO_MOVIMIENTO_MOV'
                    Width = 50
                  end
                  object tvMovsARTICULO: TcxGridDBColumn
                    Caption = 'Art'#237'culo'
                    DataBinding.FieldName = 'CODIGO_ARTICULO_MOV'
                    Width = 130
                  end
                  object tvMovsUNIDAD: TcxGridDBColumn
                    Caption = 'SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_MOV'
                    Width = 200
                  end
                  object tvMovsCANTIDAD: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_MOV'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 100
                  end
                  object tvMovsPRECIO: TcxGridDBColumn
                    Caption = 'PMP'
                    DataBinding.FieldName = 'PRECIO_MEDIO_MOV'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 100
                  end
                  object tvMovsCOSTE: TcxGridDBColumn
                    Caption = 'Coste'
                    DataBinding.FieldName = 'COSTE_MOV'
                    HeaderAlignmentHorz = taRightJustify
                    Width = 110
                  end
                  object tvMovsFECHA: TcxGridDBColumn
                    Caption = 'Fecha'
                    DataBinding.FieldName = 'FECHA_MOV'
                    Width = 140
                  end
                  object tvMovsACTIVO: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_MOV'
                    Width = 60
                  end
                end
                object cxgrdlvlMovs: TcxGridLevel
                  GridView = tvMovs
                end
              end
            end
            object tsCabecera: TcxTabSheet
              Caption = '4.Otros'
              ImageIndex = 0
              object pnlCabecera: TPanel
                Left = 0
                Top = 0
                Width = 1130
                Height = 480
                Align = alTop
                BevelOuter = bvNone
                TabOrder = 0
                object lblObservaciones: TcxLabel
                  Left = 24
                  Top = 196
                  Caption = 'Observaciones'
                  TabOrder = 2
                end
                object mmoOBSERVACIONES_INVENTARIO: TcxDBMemo
                  Left = 156
                  Top = 194
                  DataBinding.DataField = 'OBSERVACIONES_INVENTARIO'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 0
                  Height = 90
                  Width = 574
                end
                object pnlTotales: TGroupBox
                  Left = 21
                  Top = 24
                  Width = 480
                  Height = 130
                  Caption = '  Totales del descuadre  '
                  TabOrder = 1
                  object lblTotalUnidades: TcxLabel
                    Left = 16
                    Top = 32
                    Caption = 'Total unidades de descuadre'
                    TabOrder = 2
                  end
                  object txtTOTAL_UNIDADES_DIFERENCIA: TcxDBTextEdit
                    Left = 265
                    Top = 30
                    DataBinding.DataField = 'TOTAL_UNIDADES_DIFERENCIA_INVENTARIO'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 0
                    Width = 177
                  end
                  object lblTotalEuros: TcxLabel
                    Left = 52
                    Top = 76
                    Caption = 'Variaci'#243'n econ'#243'mica ('#8364')'
                    TabOrder = 3
                  end
                  object txtTOTAL_EUROS_DIFERENCIA: TcxDBTextEdit
                    Left = 265
                    Top = 74
                    DataBinding.DataField = 'TOTAL_EUROS_DIFERENCIA_INVENTARIO'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 1
                    Width = 177
                  end
                end
                object pnlAuditoria: TPanel
                  Left = 21
                  Top = 306
                  Width = 684
                  Height = 110
                  BevelOuter = bvLowered
                  TabOrder = 3
                  object lblUsuarioAlta: TcxLabel
                    Left = 8
                    Top = 8
                    Caption = 'Alta'
                    TabOrder = 4
                  end
                  object txtUSUARIOALTA: TcxDBTextEdit
                    Left = 74
                    Top = 6
                    DataBinding.DataField = 'USUARIOALTA'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 0
                    Width = 166
                  end
                  object lblInstanteAlta: TcxLabel
                    Left = 245
                    Top = 8
                    Caption = 'Fecha Alta'
                    TabOrder = 5
                  end
                  object txtINSTANTEALTA: TcxDBTextEdit
                    Left = 364
                    Top = 6
                    DataBinding.DataField = 'INSTANTEALTA'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 1
                    Width = 285
                  end
                  object lblUsuarioModif: TcxLabel
                    Left = 8
                    Top = 50
                    Caption = 'Modif.'
                    TabOrder = 6
                  end
                  object txtUSUARIOMODIF: TcxDBTextEdit
                    Left = 74
                    Top = 48
                    DataBinding.DataField = 'USUARIOMODIF'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 2
                    Width = 166
                  end
                  object lblInstanteModif: TcxLabel
                    Left = 245
                    Top = 50
                    Caption = 'Fecha Modif.'
                    TabOrder = 7
                  end
                  object txtINSTANTEMODIF: TcxDBTextEdit
                    Left = 364
                    Top = 48
                    DataBinding.DataField = 'INSTANTEMODIF'
                    DataBinding.DataSource = dsTablaG
                    Properties.ReadOnly = True
                    TabOrder = 3
                    Width = 285
                  end
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 174
          Width = 1136
          Height = 10
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
          ExplicitTop = 175
          ExplicitWidth = 10
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 1136
        ExplicitHeight = 649
        inherited pnlPerfilTop: TPanel
          Width = 1136
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1136
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 1136
          Height = 592
          StyleElements = [seFont, seClient, seBorder]
          ExplicitWidth = 1136
          ExplicitHeight = 592
          inherited cxgrdPerfil: TcxGrid
            Width = 1136
            Height = 592
            ExplicitWidth = 1136
            ExplicitHeight = 592
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 1140
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1140
      inherited pnlTopGrid: TPanel
        Width = 1140
        StyleElements = [seFont, seClient, seBorder]
        ExplicitWidth = 1140
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 1140
    Height = 720
    StyleElements = [seFont, seClient, seBorder]
    ExplicitLeft = 1140
    ExplicitHeight = 720
    inherited pButtonGen: TPanel
      Top = 522
      StyleElements = [seFont, seClient, seBorder]
      ExplicitTop = 522
    end
    inherited pButtonBDStat: TPanel
      StyleElements = [seFont, seClient, seBorder]
      inherited pnStateDataSet: TPanel
        StyleElements = [seFont, seClient, seBorder]
        inherited lblEditMode: TcxLabel
          Left = 17
          Top = 7
          ExplicitLeft = 17
          ExplicitTop = 7
        end
      end
      inherited pnlDataSetName: TPanel
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object btnAplicar: TcxButton
      Left = 0
      Top = 333
      Width = 137
      Height = 40
      Caption = 'Regularizar'
      TabOrder = 2
      OnClick = btnAplicarClick
    end
    object cxButton1: TcxButton
      Left = 0
      Top = 282
      Width = 137
      Height = 40
      Caption = 'Cargar'
      OptionsImage.ImageIndex = 0
      TabOrder = 3
      OnClick = btnRecalcularClick
    end
  end
  inherited dsTablaG: TDataSource
    OnDataChange = dsTablaGDataChange
  end
  object dlgAbrir: TOpenDialog
    Filter = 
      'Archivos CSV (*.csv;*.txt)|*.csv;*.txt|Excel (*.xlsx)|*.xlsx|Tod' +
      'os|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist]
    Left = 948
    Top = 224
  end
end
