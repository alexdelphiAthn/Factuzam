inherited frmMtoArticulos: TfrmMtoArticulos
  Left = 5
  Top = 4
  Caption = 'Articulos'
  ClientHeight = 652
  ClientWidth = 996
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 996
  ExplicitHeight = 652
  TextHeight = 19
  inherited pButtonPage: TPanel
    Width = 856
    Height = 652
    TabOrder = 0
    ExplicitWidth = 856
    ExplicitHeight = 713
    inherited pcPantalla: TcxPageControl
      Width = 856
      Height = 612
      TabOrder = 1
      Properties.ActivePage = tsFicha
      ExplicitWidth = 856
      ExplicitHeight = 673
      ClientRectBottom = 608
      ClientRectRight = 852
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 848
        ExplicitHeight = 639
        inherited cxGrdPrincipal: TcxGrid
          Width = 848
          Height = 578
          ExplicitWidth = 848
          ExplicitHeight = 639
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object cxgrdbclmnGrdDBTabPrinCODIGO_ARTICULO: TcxGridDBColumn
              Caption = 'C'#243'digo Art'#237'culo'
              DataBinding.FieldName = 'CODIGO_ARTICULO'
              Width = 150
            end
            object cxgrdbclmnGrdDBTabPrinACTIVO_ARTICULO: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ACTIVO_ARTICULO'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 76
            end
            object cxgrdbclmnGrdDBTabPrinDESCRIPCION_ARTICULO: TcxGridDBColumn
              Caption = 'Descripci'#243'n'
              DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
              Width = 205
            end
            object cxgrdbclmnGrdDBTabPrinCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn
              Caption = 'C'#243'digo Familia'
              DataBinding.FieldName = 'CODIGO_FAMILIA_ARTICULO'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 149
            end
            object cxgrdbclmnGrdDBTabPrinDESCRIPCION_FAMILIA: TcxGridDBColumn
              Caption = 'Descripci'#243'n Familia'
              DataBinding.FieldName = 'DESCRIPCION_FAMILIA'
              Width = 470
            end
            object cxgrdbclmnGrdDBTabPrinTIPOIVA_ARTICULO: TcxGridDBColumn
              Caption = 'Tipo IVA'
              DataBinding.FieldName = 'NOMBRE_TIPO_IVA'
              PropertiesClassName = 'TcxTextEditProperties'
              Width = 130
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 848
        ExplicitHeight = 639
        object pnlTopFicha: TPanel
          Left = 0
          Top = 0
          Width = 848
          Height = 174
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 848
            Height = 174
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object txtCODIGO_ARTICULO: TcxDBTextEdit
              Left = 100
              Top = 13
              DataBinding.DataField = 'CODIGO_ARTICULO'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = False
              TabOrder = 0
              Width = 121
            end
            object lblCodigo: TcxLabel
              Left = 25
              Top = 14
              Caption = 'C'#243'digo'
              TabOrder = 1
              Transparent = True
            end
            object lblNombre: TcxLabel
              Left = 18
              Top = 55
              Caption = 'Nombre'
              TabOrder = 4
              Transparent = True
            end
            object txtDESCRIPCION_ARTICULO: TcxDBTextEdit
              Left = 100
              Top = 54
              DataBinding.DataField = 'DESCRIPCION_ARTICULO'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 322
            end
            object chkActivo: TcxDBCheckBox
              Left = 230
              Top = 16
              Caption = 'Activo'
              DataBinding.DataField = 'ACTIVO_ARTICULO'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 2
              Transparent = True
            end
            object cbbFamilia: TcxDBLookupComboBox
              Left = 100
              Top = 95
              DataBinding.DataField = 'CODIGO_FAMILIA_ARTICULO'
              DataBinding.DataSource = dsTablaG
              Properties.KeyFieldNames = 'CODIGO_FAMILIA'
              Properties.ListColumns = <
                item
                  Fixed = True
                  SortOrder = soAscending
                  Width = 100
                  FieldName = 'CODIGO_FAMILIA'
                end
                item
                  Fixed = True
                  FieldName = 'NOMBRE_FAMILIA'
                end>
              Properties.ListOptions.ShowHeader = False
              TabOrder = 5
              Width = 322
            end
            object lblFamilia: TcxLabel
              Left = 24
              Top = 96
              Margins.Left = 4
              Margins.Top = 4
              Margins.Right = 4
              Margins.Bottom = 4
              Caption = 'Familia'
              Properties.Alignment.Horz = taRightJustify
              TabOrder = 6
              Transparent = True
              AnchorX = 90
            end
            object cxDBLabel1: TcxDBLabel
              Left = 250
              Top = 128
              DataBinding.DataField = 'DESCRIPCION_FAMILIA'
              DataBinding.DataSource = dsTablaG
              TabOrder = 7
              Transparent = True
              Height = 21
              Width = 586
            end
            object cxDBLabel2: TcxDBLabel
              Left = 100
              Top = 128
              DataBinding.DataField = 'NOMBRE_FAMILIA'
              DataBinding.DataSource = dsTablaG
              TabOrder = 8
              Transparent = True
              Height = 21
              Width = 133
            end
          end
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 182
          Width = 848
          Height = 396
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          ExplicitHeight = 457
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 848
            Height = 396
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = cxTabSheet2
            Properties.CustomButtons.Buttons = <>
            ExplicitHeight = 457
            ClientRectBottom = 392
            ClientRectLeft = 4
            ClientRectRight = 844
            ClientRectTop = 30
            object tsVariaciones: TcxTabSheet
              Caption = '&0_Variaciones'
              ImageIndex = 4
              TabVisible = False
              ExplicitHeight = 423
              object pnlUpVariaciones: TPanel
                Left = 0
                Top = 0
                Width = 840
                Height = 73
                Align = alTop
                TabOrder = 0
                object lbl11: TcxLabel
                  Left = 6
                  Top = 26
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Variaciones'
                  Properties.Alignment.Horz = taRightJustify
                  TabOrder = 1
                  Transparent = True
                  AnchorX = 107
                end
                object cbbVARIACIONES_ARTICULOS: TcxDBLookupComboBox
                  Left = 123
                  Top = 22
                  DataBinding.DataField = 'CODIGO_FAMILIA_ARTICULO'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO_VARIACION'
                  Properties.ListColumns = <
                    item
                      FieldName = 'CODIGO_VARIACION'
                    end
                    item
                      FieldName = 'NOMBRE_VARIACION'
                    end>
                  Properties.ListOptions.ShowHeader = False
                  TabOrder = 0
                  Width = 322
                end
              end
              object pnlBodyVariaciones: TPanel
                Left = 0
                Top = 73
                Width = 840
                Height = 289
                Align = alClient
                TabOrder = 1
                ExplicitHeight = 350
                object pnlRightVariacion: TPanel
                  Left = 631
                  Top = 1
                  Width = 208
                  Height = 287
                  Align = alRight
                  TabOrder = 1
                  ExplicitHeight = 348
                end
                object pnlBodyVariacion: TPanel
                  Left = 1
                  Top = 1
                  Width = 630
                  Height = 287
                  Align = alClient
                  TabOrder = 0
                  ExplicitHeight = 348
                  object cxGrid1: TcxGrid
                    Left = 1
                    Top = 1
                    Width = 628
                    Height = 285
                    Margins.Left = 4
                    Margins.Top = 4
                    Margins.Right = 4
                    Margins.Bottom = 4
                    Align = alClient
                    TabOrder = 0
                    ExplicitHeight = 346
                    object tvVariaciones: TcxGridDBTableView
                      OnDblClick = cxGrdDBTabPrinDblClick
                      Navigator.Buttons.ConfirmDelete = True
                      Navigator.Buttons.First.Hint = 'Va al primer Registro'
                      Navigator.Buttons.First.Visible = False
                      Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                      Navigator.Buttons.PriorPage.Visible = False
                      Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                      Navigator.Buttons.Prior.Visible = False
                      Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                      Navigator.Buttons.Next.Visible = False
                      Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                      Navigator.Buttons.NextPage.Visible = False
                      Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                      Navigator.Buttons.Last.Visible = False
                      Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                      Navigator.Buttons.Insert.Visible = True
                      Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                      Navigator.Buttons.Delete.Visible = True
                      Navigator.Buttons.Edit.Enabled = False
                      Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                      Navigator.Buttons.Edit.Visible = False
                      Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                      Navigator.Buttons.Post.Visible = True
                      Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                      Navigator.Buttons.Cancel.Visible = True
                      Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                      Navigator.Buttons.SaveBookmark.Enabled = False
                      Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                      Navigator.Buttons.SaveBookmark.Visible = False
                      Navigator.Buttons.GotoBookmark.Enabled = False
                      Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                      Navigator.Buttons.GotoBookmark.Visible = False
                      Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                      Navigator.Visible = True
                      DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                      OptionsBehavior.AlwaysShowEditor = True
                      OptionsBehavior.GoToNextCellOnEnter = True
                      OptionsBehavior.IncSearch = True
                      OptionsCustomize.ColumnHiding = True
                      OptionsData.Inserting = False
                      OptionsView.GroupByBox = False
                      OptionsView.Indicator = True
                      object dbcVariacionesCODIGO_VARIACION: TcxGridDBColumn
                        DataBinding.FieldName = 'CODIGO_VARIACION'
                        Width = 176
                      end
                      object dbcVariacionesCODIGO_ARTICULO: TcxGridDBColumn
                        Caption = 'C'#243'digo Art'#237'culo'
                        DataBinding.FieldName = 'CODIGO_ARTICULO'
                        Visible = False
                      end
                      object dbcVariacionesNOMBRE_COLUMNA: TcxGridDBColumn
                        Caption = 'Nombre Columna'
                        DataBinding.FieldName = 'NOMBRE_COLUMNA'
                        Width = 104
                      end
                      object dbcVariacionesCODIGO_UNICO: TcxGridDBColumn
                        Caption = 'C'#243'digo '#218'nico'
                        DataBinding.FieldName = 'CODIGO_UNICO'
                        Width = 139
                      end
                      object dbcVariacionesVALOR_VARIACION: TcxGridDBColumn
                        Caption = 'Valor'
                        DataBinding.FieldName = 'VALOR_VARIACION'
                        Width = 162
                      end
                      object dbcVariacionesNOMBRE_VARIACION: TcxGridDBColumn
                        DataBinding.FieldName = 'NOMBRE_VARIACION'
                        Width = 180
                      end
                      object dbcVariacionesACTIVO_VARIACION: TcxGridDBColumn
                        DataBinding.FieldName = 'ACTIVO_VARIACION'
                      end
                      object dbcVariacionesORDEN_VARIACION: TcxGridDBColumn
                        DataBinding.FieldName = 'ORDEN_VARIACION'
                      end
                    end
                    object lv1: TcxGridLevel
                      GridView = tvVariaciones
                    end
                  end
                end
              end
            end
            object cxTabSheet1: TcxTabSheet
              Caption = '&1_General'
              ImageIndex = 4
              ExplicitHeight = 423
              object rgTipoIVA: TcxDBRadioGroup
                Left = 408
                Top = 19
                Caption = 'Tipo de IVA'
                DataBinding.DataField = 'TIPOIVA_ARTICULO'
                DataBinding.DataSource = dsTablaG
                Properties.Items = <
                  item
                    Caption = 'Normal'
                    Value = 'N'
                  end
                  item
                    Caption = 'Reducido'
                    Value = 'R'
                  end
                  item
                    Caption = 'S'#250'per Reducido'
                    Value = 'SR'
                  end
                  item
                    Caption = 'Exento'
                    Value = 'E'
                  end>
                TabOrder = 0
                Height = 122
                Width = 185
              end
              object cxGroupBox1: TcxGroupBox
                Left = 23
                Top = 147
                Caption = 'Variaciones'
                TabOrder = 1
                Height = 142
                Width = 379
                object cxDBCheckBox1: TcxDBCheckBox
                  Left = 24
                  Top = 24
                  Caption = 'Tiene Variaciones/SKU m'#250'ltiple'
                  DataBinding.DataField = 'ESVARIACION_ARTICULO'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 0
                end
                object cxLabel1: TcxLabel
                  Left = 20
                  Top = 53
                  Caption = 'Tipo de Variaci'#243'n'
                  TabOrder = 1
                  Transparent = True
                end
                object cxDBLookupComboBox1: TcxDBLookupComboBox
                  Left = 92
                  Top = 78
                  DataBinding.DataField = 'TIPO_VARIACION_ARTICULO'
                  DataBinding.DataSource = dsTablaG
                  Properties.KeyFieldNames = 'CODIGO_FAMILIA'
                  Properties.ListColumns = <
                    item
                      FieldName = 'NOMBRE_VAR'
                    end>
                  Properties.ListOptions.ShowHeader = False
                  Properties.ListSource = dmArticulos.dsVariaciones
                  TabOrder = 2
                  Width = 276
                end
                object cxDBCheckBox2: TcxDBCheckBox
                  Left = 20
                  Top = 111
                  Caption = 'Trazabilidad/Serializaci'#243'n por unidad'
                  DataBinding.DataField = 'ESTRAZABLE_ARTICULO'
                  DataBinding.DataSource = dsTablaG
                  Properties.ValueChecked = 'S'
                  Properties.ValueUnchecked = 'N'
                  Style.TransparentBorder = False
                  TabOrder = 3
                end
              end
              object cxGroupBox2: TcxGroupBox
                Left = 23
                Top = 19
                Caption = 'Tipolog'#237'a'
                TabOrder = 2
                Height = 122
                Width = 379
                object lblNombre1: TcxLabel
                  Left = 24
                  Top = 77
                  Caption = 'Tipo de Cantidad'
                  TabOrder = 0
                  Transparent = True
                end
                object cxdbtxtdtTIPO_CANTIDAD_ARTICULO: TcxDBTextEdit
                  Left = 178
                  Top = 73
                  DataBinding.DataField = 'TIPO_CANTIDAD_ARTICULO'
                  DataBinding.DataSource = dsTablaG
                  TabOrder = 1
                  Width = 130
                end
                object cxLabel2: TcxLabel
                  Left = 28
                  Top = 37
                  Caption = 'Tipo de Art'#237'culo'
                  TabOrder = 2
                  Transparent = True
                end
                object cxDBComboBox1: TcxDBComboBox
                  Left = 176
                  Top = 33
                  DataBinding.DataField = 'TIPO_ARTICULO'
                  DataBinding.DataSource = dsTablaG
                  Properties.Items.Strings = (
                    'ESTANDAR'
                    'SERVICIO')
                  TabOrder = 3
                  Width = 167
                end
              end
            end
            object cxTabSheet2: TcxTabSheet
              Caption = '&2_SKU'
              ImageIndex = 5
              ExplicitHeight = 423
              object cxGrid2: TcxGrid
                Left = 0
                Top = 129
                Width = 719
                Height = 233
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                ExplicitTop = 0
                ExplicitWidth = 727
                ExplicitHeight = 423
                object cxGridDBTableView1: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsVariacionesArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#.##'
                      Kind = skSum
                    end
                    item
                      Format = '##,##.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxGridDBTableView1CODIGO_UNIDAD_SKU: TcxGridDBColumn
                    Caption = 'C'#243'digo SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_SKU'
                    Width = 167
                  end
                  object cxGridDBTableView1CODIGO_ARTICULO_SKU: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ARTICULO_SKU'
                    Visible = False
                  end
                  object cxGridDBTableView1ESACTIVO_SKU: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_SKU'
                    Width = 80
                  end
                  object cxGridDBTableView1INSTANTEMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEMODIF'
                    Visible = False
                  end
                  object cxGridDBTableView1INSTANTEALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEALTA'
                    Visible = False
                  end
                  object cxGridDBTableView1USUARIOALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOALTA'
                    Visible = False
                  end
                  object cxGridDBTableView1USUARIOMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOMODIF'
                    Visible = False
                  end
                end
                object cxGridLevel1: TcxGridLevel
                  GridView = cxGridDBTableView1
                end
              end
              object Panel1: TPanel
                Left = 719
                Top = 129
                Width = 121
                Height = 233
                Align = alRight
                TabOrder = 1
                ExplicitTop = 0
                ExplicitHeight = 423
                object cxButton1: TcxButton
                  Left = 5
                  Top = 61
                  Width = 116
                  Height = 34
                  Caption = '&Ir a Proveedor'
                  TabOrder = 1
                  OnClick = btnIraProveedorClick
                end
                object cxButton2: TcxButton
                  Left = 5
                  Top = 101
                  Width = 116
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 2
                  OnClick = btnExportarProveedorClick
                end
                object cxButton3: TcxButton
                  Left = 5
                  Top = 21
                  Width = 116
                  Height = 34
                  Caption = '&A'#241'adir'
                  TabOrder = 0
                  OnClick = btnAddProveedorClick
                end
              end
              object cxGrid3: TcxGrid
                Left = 0
                Top = 0
                Width = 840
                Height = 129
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alTop
                TabOrder = 2
                object cxGridDBTableView2: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsVariacionesArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#.##'
                      Kind = skSum
                    end
                    item
                      Format = '##,##.00 '#8364
                      Kind = skSum
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxGridDBColumn1: TcxGridDBColumn
                    Caption = 'C'#243'digo SKU'
                    DataBinding.FieldName = 'CODIGO_UNIDAD_SKU'
                    Width = 167
                  end
                  object cxGridDBColumn2: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ARTICULO_SKU'
                    Visible = False
                  end
                  object cxGridDBColumn3: TcxGridDBColumn
                    Caption = 'Activo'
                    DataBinding.FieldName = 'ESACTIVO_SKU'
                    Width = 80
                  end
                  object cxGridDBColumn4: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEMODIF'
                    Visible = False
                  end
                  object cxGridDBColumn5: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEALTA'
                    Visible = False
                  end
                  object cxGridDBColumn6: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOALTA'
                    Visible = False
                  end
                  object cxGridDBColumn7: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOMODIF'
                    Visible = False
                  end
                end
                object cxGridLevel2: TcxGridLevel
                  GridView = cxGridDBTableView2
                end
              end
            end
            object tsTarifas: TcxTabSheet
              Caption = '&3_Tarifas'
              ImageIndex = 1
              ExplicitHeight = 423
              object cxgrdTarifas: TcxGrid
                Left = 0
                Top = 0
                Width = 724
                Height = 362
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                ExplicitHeight = 423
                object tvTarifas: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxgrdbclmnTarifasCODIGO_TARIFA: TcxGridDBColumn
                    Caption = 'C'#243'digo Tarifa'
                    DataBinding.FieldName = 'CODIGO_TARIFA'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 129
                  end
                  object cxgrdbclmnTarifasNOMBRE_TARIFA: TcxGridDBColumn
                    Caption = 'Nombre Tarifa'
                    DataBinding.FieldName = 'NOMBRE_TARIFA'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 145
                  end
                  object dbcTarifasESIMP_INCL_TARIFA: TcxGridDBColumn
                    Caption = 'Imp. Incl.'
                    DataBinding.FieldName = 'ESIMP_INCL_TARIFA'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 86
                  end
                  object cxgrdbclmnTarifasCODIGO_ARTICULO_TARIFA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ARTICULO_TARIFA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnTarifasDESCRIPCION_ARTICULO: TcxGridDBColumn
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnTarifasTIPO_CANTIDAD_ARTICULO: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object dbcTarifasPRECIOSALIDA: TcxGridDBColumn
                    Caption = 'Precio Salida'
                    DataBinding.FieldName = 'PRECIOSALIDA_TARIFA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.OnEditValueChanged = dbcTarifasPRECIOSALIDAPropertiesEditValueChanged
                    Width = 113
                  end
                  object dbcTarifasPORCEN_DTO_TARIFA: TcxGridDBColumn
                    Caption = '% Descuento'
                    DataBinding.FieldName = 'PORCEN_DTO_TARIFA'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.DisplayFormat = '#.## %'
                    Properties.EditFormat = '#,## %'
                    Properties.OnEditValueChanged = dbcTarifasPORCEN_DTO_TARIFAPropertiesEditValueChanged
                    Width = 124
                  end
                  object dbcTarifasPRECIO_DTO_TARIFA: TcxGridDBColumn
                    Caption = 'Cantidad Descuento'
                    DataBinding.FieldName = 'PRECIO_DTO_TARIFA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.OnEditValueChanged = dbcTarifasPRECIO_DTO_TARIFAPropertiesEditValueChanged
                    Width = 174
                  end
                  object dbcTarifasPRECIOFINAL: TcxGridDBColumn
                    Caption = 'Precio Final'
                    DataBinding.FieldName = 'PRECIOFINAL_TARIFA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.OnEditValueChanged = dbcTarifasPRECIOFINALPropertiesEditValueChanged
                    Width = 129
                  end
                  object cxgrdbclmnTarifasTIPO_IVA_ARTICULO: TcxGridDBColumn
                    DataBinding.FieldName = 'TIPO_IVA_ARTICULO'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnTarifasACTIVO_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa Activa'
                    DataBinding.FieldName = 'ACTIVO_TARIFA'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 110
                  end
                  object cxgrdbclmnTarifasFECHA_DESDE_TARIFA: TcxGridDBColumn
                    Caption = 'Fecha Desde'
                    DataBinding.FieldName = 'FECHA_DESDE_TARIFA'
                    Width = 112
                  end
                  object cxgrdbclmnTarifasFECHA_HASTA_TARIFA: TcxGridDBColumn
                    Caption = 'Fecha Hasta'
                    DataBinding.FieldName = 'FECHA_HASTA_TARIFA'
                    Width = 107
                  end
                  object dbcTarifasESDEFAULT_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa x Defecto'
                    DataBinding.FieldName = 'ESDEFAULT_TARIFA'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 142
                  end
                  object cxgrdbclmnTarifasCODIGO_PROVEEDOR: TcxGridDBColumn
                    Caption = 'C'#243'digo Proveedor'
                    DataBinding.FieldName = 'CODIGO_PROVEEDOR'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 156
                  end
                  object cxgrdbclmnTarifasRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn
                    DataBinding.FieldName = 'RAZONSOCIAL_PROVEEDOR'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 231
                  end
                  object cxgrdbclmnTarifasPRECIO_ULT_COMPRA: TcxGridDBColumn
                    Caption = 'Precio '#218'lt Compra'
                    DataBinding.FieldName = 'PRECIO_ULT_COMPRA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Properties.ReadOnly = True
                    Width = 156
                  end
                  object cxgrdbclmnTarifasFECHA_VALIDEZ: TcxGridDBColumn
                    Caption = 'Fecha Validez'
                    DataBinding.FieldName = 'FECHA_VALIDEZ'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Properties.ReadOnly = True
                    Width = 121
                  end
                  object cxgrdbclmnTarifasCODIGO_FAMILIA_ARTICULO: TcxGridDBColumn
                    Caption = 'Familia'
                    DataBinding.FieldName = 'CODIGO_FAMILIA_ARTICULO'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                  end
                  object cxgrdbclmnTarifasDESCRIPCION_FAMILIA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Familia'
                    DataBinding.FieldName = 'DESCRIPCION_FAMILIA'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 301
                  end
                  object cxgrdbclmnTarifasINSTANTEALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEALTA'
                    Visible = False
                  end
                  object cxgrdbclmnTarifasINSTANTEMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEMODIF'
                    Visible = False
                  end
                  object cxgrdbclmnTarifasUSUARIOALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOALTA'
                    Visible = False
                  end
                  object cxgrdbclmnTarifasUSUARIOMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOMODIF'
                    Visible = False
                  end
                  object dbcTarifasCODIGO_UNICO_TARIFA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_UNICO_TARIFA'
                    Visible = False
                  end
                end
                object cxgrdlvlTarifas: TcxGridLevel
                  GridView = tvTarifas
                end
              end
              object pnlFacturaOpts2: TPanel
                Left = 724
                Top = 0
                Width = 116
                Height = 362
                Align = alRight
                BevelOuter = bvNone
                TabOrder = 1
                ExplicitHeight = 423
                object btnIraTarifa: TcxButton
                  Left = 6
                  Top = 16
                  Width = 105
                  Height = 34
                  Caption = 'Ir a &Tarifa'
                  TabOrder = 0
                  OnClick = btnIraTarifaClick
                end
                object btnCrearTarifa: TcxButton
                  Left = 7
                  Top = 56
                  Width = 104
                  Height = 34
                  Caption = 'C&rear Tarifa'
                  TabOrder = 1
                  OnClick = btnCrearTarifaClick
                end
                object btnExportarTarifa: TcxButton
                  Left = 6
                  Top = 96
                  Width = 105
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 2
                  OnClick = btnExportarTarifaClick
                end
              end
            end
            object tsProveedores: TcxTabSheet
              Caption = '&4_Proveedores'
              ImageIndex = 2
              ExplicitHeight = 423
              object cxgrdProveedores: TcxGrid
                Left = 0
                Top = 0
                Width = 719
                Height = 362
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                ExplicitHeight = 423
                object tvProveedores: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.DataSource = dmArticulos.dsProveedoresArticulos
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Inserting = False
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxgrdbclmnProveedoresESPROVEEDORPRINCIPAL: TcxGridDBColumn
                    Caption = 'Principal'
                    DataBinding.FieldName = 'ESPROVEEDORPRINCIPAL'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 89
                  end
                  object cxgrdbclmnProveedoresCODIGO_PROVEEDOR: TcxGridDBColumn
                    Caption = 'C'#243'digo Proveedor'
                    DataBinding.FieldName = 'CODIGO_PROVEEDOR'
                    PropertiesClassName = 'TcxButtonEditProperties'
                    Properties.Buttons = <
                      item
                        Default = True
                        Kind = bkEllipsis
                      end>
                    Properties.OnButtonClick = cxgrdbclmnProveedoresCODIGO_PROVEEDORPropertiesButtonClick
                    Width = 189
                  end
                  object tvProveedoresColumn1: TcxGridDBColumn
                    Caption = 'Modelo Proveedor'
                    DataBinding.FieldName = 'REF_PROVEEDOR_ARTICULO_PROVEEDOR'
                    Width = 196
                  end
                  object cxgrdbclmnProveedoresRAZONSOCIAL_PROVEEDOR: TcxGridDBColumn
                    Caption = 'Raz'#243'n Social Proveedor'
                    DataBinding.FieldName = 'RAZONSOCIAL_PROVEEDOR'
                    PropertiesClassName = 'TcxTextEditProperties'
                    Properties.ReadOnly = True
                    Width = 221
                  end
                  object cxgrdbclmnProveedoresCODIGO_ARTICULO: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ARTICULO'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresPRECIO_ULT_COMPRA: TcxGridDBColumn
                    Caption = 'Precio '#218'ltima Compra'
                    DataBinding.FieldName = 'PRECIO_ULT_COMPRA'
                    Width = 194
                  end
                  object cxgrdbclmnProveedoresFECHA_VALIDEZ: TcxGridDBColumn
                    Caption = 'Fecha '#250'ltimo Precio'
                    DataBinding.FieldName = 'FECHA_VALIDEZ'
                    Width = 174
                  end
                  object cxgrdbclmnProveedoresINSTANTEMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEMODIF'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresINSTANTEALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'INSTANTEALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresUSUARIOALTA: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOALTA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnProveedoresUSUARIOMODIF: TcxGridDBColumn
                    DataBinding.FieldName = 'USUARIOMODIF'
                    Visible = False
                    VisibleForCustomization = False
                  end
                end
                object cxgrdlvlProveedores: TcxGridLevel
                  GridView = tvProveedores
                end
              end
              object pnlFacturaOpts1: TPanel
                Left = 719
                Top = 0
                Width = 121
                Height = 362
                Align = alRight
                TabOrder = 1
                ExplicitHeight = 423
                object btnIraProveedor: TcxButton
                  Left = 5
                  Top = 61
                  Width = 116
                  Height = 34
                  Caption = '&Ir a Proveedor'
                  TabOrder = 1
                  OnClick = btnIraProveedorClick
                end
                object btnExportarProveedor: TcxButton
                  Left = 5
                  Top = 101
                  Width = 116
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 2
                  OnClick = btnExportarProveedorClick
                end
                object btnAddProveedor: TcxButton
                  Left = 5
                  Top = 21
                  Width = 116
                  Height = 34
                  Caption = '&A'#241'adir'
                  TabOrder = 0
                  OnClick = btnAddProveedorClick
                end
              end
            end
            object tsLineasFactura: TcxTabSheet
              Caption = '&6_Lineas de Venta - '
              ImageIndex = 3
              ExplicitHeight = 423
              object cxgrdLinFac: TcxGrid
                Left = 0
                Top = 0
                Width = 727
                Height = 362
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Align = alClient
                TabOrder = 0
                ExplicitHeight = 423
                object tvLinFac: TcxGridDBTableView
                  OnDblClick = cxGrdDBTabPrinDblClick
                  Navigator.Buttons.ConfirmDelete = True
                  Navigator.Buttons.First.Hint = 'Va al primer Registro'
                  Navigator.Buttons.First.Visible = False
                  Navigator.Buttons.PriorPage.Hint = 'Va a la p'#225'gina anterior'
                  Navigator.Buttons.PriorPage.Visible = False
                  Navigator.Buttons.Prior.Hint = 'Va al Registro Anterior'
                  Navigator.Buttons.Prior.Visible = False
                  Navigator.Buttons.Next.Hint = 'Va al siguiente Registro'
                  Navigator.Buttons.Next.Visible = False
                  Navigator.Buttons.NextPage.Hint = 'Va a la p'#225'gina siguiente'
                  Navigator.Buttons.NextPage.Visible = False
                  Navigator.Buttons.Last.Hint = 'Va al '#250'ltimo registro'
                  Navigator.Buttons.Last.Visible = False
                  Navigator.Buttons.Insert.Hint = 'Inserta un nuevo Registro'
                  Navigator.Buttons.Insert.Visible = True
                  Navigator.Buttons.Delete.Hint = 'Borra el registro Activo'
                  Navigator.Buttons.Delete.Visible = True
                  Navigator.Buttons.Edit.Enabled = False
                  Navigator.Buttons.Edit.Hint = 'Edita registro Actual'
                  Navigator.Buttons.Edit.Visible = False
                  Navigator.Buttons.Post.Hint = 'Guarda Datos introducidos'
                  Navigator.Buttons.Post.Visible = True
                  Navigator.Buttons.Cancel.Hint = 'Cancela la edici'#243'n actual'
                  Navigator.Buttons.Cancel.Visible = True
                  Navigator.Buttons.Refresh.Hint = 'Refresca Datos Activos'
                  Navigator.Buttons.SaveBookmark.Enabled = False
                  Navigator.Buttons.SaveBookmark.Hint = 'Marca Registro Actual'
                  Navigator.Buttons.SaveBookmark.Visible = False
                  Navigator.Buttons.GotoBookmark.Enabled = False
                  Navigator.Buttons.GotoBookmark.Hint = 'Va al registro Marcado'
                  Navigator.Buttons.GotoBookmark.Visible = False
                  Navigator.Buttons.Filter.Hint = 'Filtro personalizado'
                  Navigator.Visible = True
                  DataController.Options = [dcoCaseInsensitive, dcoAssignGroupingValues, dcoAssignMasterDetailKeys, dcoSaveExpanding]
                  DataController.Summary.FooterSummaryItems = <
                    item
                      Format = '#.##'
                      Kind = skSum
                      Column = cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA
                    end
                    item
                      Format = '##,##.00 '#8364
                      Kind = skSum
                      Column = cxgrdbclmnLinFacTOTAL_FACTURA_LINEA
                    end>
                  OptionsBehavior.AlwaysShowEditor = True
                  OptionsBehavior.GoToNextCellOnEnter = True
                  OptionsBehavior.IncSearch = True
                  OptionsCustomize.ColumnHiding = True
                  OptionsData.CancelOnExit = False
                  OptionsData.Deleting = False
                  OptionsData.DeletingConfirmation = False
                  OptionsData.Editing = False
                  OptionsData.Inserting = False
                  OptionsView.Footer = True
                  OptionsView.GroupByBox = False
                  OptionsView.Indicator = True
                  object cxgrdbclmnLinFacNRO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nro Factura'
                    DataBinding.FieldName = 'NRO_FACTURA_LINEA'
                    Width = 119
                  end
                  object cxgrdbclmnLinFacSERIE_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Serie Factura'
                    DataBinding.FieldName = 'SERIE_FACTURA_LINEA'
                    Width = 141
                  end
                  object cxgrdbclmnLinFacLINEA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Nro Linea'
                    DataBinding.FieldName = 'LINEA_FACTURA_LINEA'
                    Width = 109
                  end
                  object cxgrdbclmnLinFacTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tipo Cantidad'
                    DataBinding.FieldName = 'TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA'
                    Width = 134
                  end
                  object cxgrdbclmnLinFacCANTIDAD_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Cantidad'
                    DataBinding.FieldName = 'CANTIDAD_FACTURA_LINEA'
                    Width = 82
                  end
                  object cxgrdbclmnLinFacDESCRIPCION_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Descripci'#243'n Linea'
                    DataBinding.FieldName = 'DESCRIPCION_ARTICULO_FACTURA_LINEA'
                    Width = 155
                  end
                  object cxgrdbclmnLinFacNOMBRE_TARIFA: TcxGridDBColumn
                    Caption = 'Tarifa Aplicada'
                    DataBinding.FieldName = 'NOMBRE_TARIFA'
                    Width = 143
                  end
                  object cxgrdbclmnLinFacESIMP_INCL_TARIFA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Imp. Incl.'
                    DataBinding.FieldName = 'ESIMP_INCL_TARIFA_FACTURA_LINEA'
                    PropertiesClassName = 'TcxCheckBoxProperties'
                    Properties.ValueChecked = 'S'
                    Properties.ValueUnchecked = 'N'
                    Width = 137
                  end
                  object cxgrdbclmnLinFacPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio sin IVA'
                    DataBinding.FieldName = 'PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 131
                  end
                  object cxgrdbclmnLinFacTIPOIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Tipo IVA'
                    DataBinding.FieldName = 'TIPOIVA_ARTICULO_FACTURA_LINEA'
                    Width = 108
                  end
                  object cxgrdbclmnLinFacPORCEN_IVA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = '% IVA'
                    DataBinding.FieldName = 'PORCEN_IVA_FACTURA_LINEA'
                    PropertiesClassName = 'TcxSpinEditProperties'
                    Properties.DisplayFormat = '0.00 %'
                    Properties.EditFormat = '0.00 %'
                    Properties.MaxValue = 100.000000000000000000
                    Properties.ValueType = vtFloat
                    Width = 80
                  end
                  object cxgrdbclmnLinFacPRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Precio Con IVA'
                    DataBinding.FieldName = 'PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 152
                  end
                  object cxgrdbclmnLinFacCODIGO_ARTICULO_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_ARTICULO_FACTURA_LINEA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacCODIGO_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'CODIGO_FAMILIA_FACTURA_LINEA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacNOMBRE_FAMILIA_FACTURA_LINEA: TcxGridDBColumn
                    DataBinding.FieldName = 'NOMBRE_FAMILIA_FACTURA_LINEA'
                    Visible = False
                    VisibleForCustomization = False
                  end
                  object cxgrdbclmnLinFacTOTAL_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Total Linea'
                    DataBinding.FieldName = 'TOTAL_FACTURA_LINEA'
                    PropertiesClassName = 'TcxCurrencyEditProperties'
                    Width = 118
                  end
                  object cxgrdbclmnLinFacFECHA_ENTREGA_FACTURA_LINEA: TcxGridDBColumn
                    Caption = 'Fecha Entrega'
                    DataBinding.FieldName = 'FECHA_ENTREGA_FACTURA_LINEA'
                    PropertiesClassName = 'TcxDateEditProperties'
                    Width = 136
                  end
                end
                object cxgrdlvlLinFac: TcxGridLevel
                  GridView = tvLinFac
                end
              end
              object pnlFacturaOpts: TPanel
                Left = 727
                Top = 0
                Width = 113
                Height = 362
                Align = alRight
                TabOrder = 1
                ExplicitHeight = 423
                object btnIraFactura: TcxButton
                  Left = 6
                  Top = 16
                  Width = 104
                  Height = 34
                  Caption = 'Ir a F&actura'
                  TabOrder = 0
                  OnClick = btnIraFacturaClick
                end
                object btnIraEmpresa: TcxButton
                  Left = 7
                  Top = 56
                  Width = 104
                  Height = 34
                  Caption = 'Ir a &Empresa'
                  TabOrder = 1
                  OnClick = btnIraEmpresaClick
                end
                object btnExportarLineas: TcxButton
                  Left = 6
                  Top = 138
                  Width = 104
                  Height = 34
                  Caption = '&Exp Excel'
                  TabOrder = 3
                end
                object btnIraCliente: TcxButton
                  Left = 7
                  Top = 96
                  Width = 104
                  Height = 34
                  Caption = 'Ir a C&liente'
                  TabOrder = 2
                  OnClick = btnIraClienteClick
                end
              end
            end
            object tsOtros: TcxTabSheet
              Caption = '&5_Otros'
              ImageIndex = 3
              ExplicitHeight = 423
              object pnl3: TPanel
                Left = 0
                Top = 283
                Width = 840
                Height = 79
                Align = alBottom
                TabOrder = 3
                ExplicitTop = 344
                object cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit
                  Left = 17
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIOALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Width = 136
                end
                object lblUsuarioAlta: TcxLabel
                  Left = 17
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Usuario Alta'
                  TabOrder = 0
                  Transparent = True
                end
                object lblInstanteAlta: TcxLabel
                  Left = 163
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Alta'
                  TabOrder = 1
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA: TcxDBTextEdit
                  Left = 163
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 192
                end
                object cxdbtxtdtINSTANTEALTA: TcxDBTextEdit
                  Left = 511
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'INSTANTEMODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 7
                  Width = 198
                end
                object lblInstanteModif: TcxLabel
                  Left = 514
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Instante Modificaci'#243'n'
                  TabOrder = 5
                  Transparent = True
                end
                object cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit
                  Left = 359
                  Top = 37
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  DataBinding.DataField = 'USUARIOALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 4
                  Width = 136
                end
                object lblUsuarioModif: TcxLabel
                  Left = 359
                  Top = 9
                  Margins.Left = 4
                  Margins.Top = 4
                  Margins.Right = 4
                  Margins.Bottom = 4
                  Caption = 'Us '#218'lt. Modif.'
                  TabOrder = 6
                  Transparent = True
                end
              end
              object chkACTIVO_ARTICULO: TcxDBCheckBox
                Left = 48
                Top = 24
                Caption = 'Es Activo fijo --Es Maquinaria o Aperos-- (S'#243'lo REAGP)'
                DataBinding.DataField = 'ESACTIVO_FIJO_ARTICULO'
                DataBinding.DataSource = dsTablaG
                Properties.ValueChecked = 'S'
                Properties.ValueUnchecked = 'N'
                TabOrder = 0
                Transparent = True
              end
              object lblTextoLegal11: TcxLabel
                Left = 376
                Top = 110
                Margins.Left = 4
                Margins.Top = 4
                Margins.Right = 4
                Margins.Bottom = 4
                Caption = 'Orden en Listados'
                TabOrder = 2
                Transparent = True
              end
              object cxdbspndtORDEN_CLIENTE: TcxDBSpinEdit
                Left = 537
                Top = 106
                DataBinding.DataField = 'ORDEN_ARTICULO'
                DataBinding.DataSource = dsTablaG
                TabOrder = 1
                Width = 106
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 174
          Width = 848
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
        end
      end
      inherited tsPerfil: TcxTabSheet
        ExplicitWidth = 848
        ExplicitHeight = 639
        inherited pnlPerfilTop: TPanel
          Width = 848
          ExplicitWidth = 848
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
        inherited pnlPerfilDetail: TPanel
          Width = 848
          Height = 521
          ExplicitWidth = 848
          ExplicitHeight = 582
          inherited cxgrdPerfil: TcxGrid
            Width = 848
            Height = 521
            ExplicitWidth = 848
            ExplicitHeight = 582
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      Width = 856
      TabOrder = 0
      ExplicitWidth = 856
      inherited pnlTopGrid: TPanel
        Width = 856
        ExplicitWidth = 856
        inherited edtBusqGlobal: TcxTextEdit
          TabOrder = 1
          ExplicitHeight = 27
        end
        inherited nvNavegador: TcxDBNavigator
          Width = 324
          ExplicitWidth = 324
        end
        inherited rbBBDD: TcxRadioButton
          Top = 3
          Font.Name = 'Calibri'
          Font.Quality = fqClearTypeNatural
          TabOrder = 0
          ExplicitTop = 3
        end
        inherited rbGrid: TcxRadioButton
          Font.Name = 'Calibri'
        end
        inherited btnBusq: TcxButton
          TabOrder = 4
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    Left = 856
    Height = 652
    TabOrder = 1
    ExplicitLeft = 856
    ExplicitHeight = 713
    inherited pButtonGen: TPanel
      Top = 454
      TabOrder = 2
      ExplicitTop = 515
    end
    inherited pButtonBDStat: TPanel
      inherited pnStateDataSet: TPanel
        TabOrder = 1
      end
      inherited pnlDataSetName: TPanel
        TabOrder = 0
      end
    end
    object btnNuevoArticulo: TcxButton
      Left = 1
      Top = 157
      Width = 138
      Height = 25
      Caption = '&Nuevo Art'#237'culo'
      TabOrder = 1
      OnClick = btnNuevoArticuloClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Left = 680
    Top = 424
  end
  object ActionListArticulos: TActionList [4]
    Left = 680
    Top = 288
    object actFacturas: TAction
      Caption = 'actFacturas'
      ShortCut = 16454
      OnExecute = actFacturasExecute
    end
    object actEmpresas: TAction
      ShortCut = 16453
      OnExecute = actEmpresasExecute
    end
    object actClientes: TAction
      Caption = 'actClientes'
      ShortCut = 16459
      OnExecute = actClientesExecute
    end
    object actProveedores: TAction
      Caption = 'actProveedores'
      ShortCut = 16464
      OnExecute = actProveedoresExecute
    end
    object actTarifas: TAction
      Caption = 'actTarifas'
      ShortCut = 16468
      OnExecute = actTarifasExecute
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmArticulos.unqryTablaG
    Left = 676
    Top = 351
  end
  inherited saveDialog: TdxSaveFileDialog
    Left = 688
    Top = 504
  end
end
