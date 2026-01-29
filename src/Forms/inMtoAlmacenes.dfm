inherited frmMtoAlmacenes: TfrmMtoAlmacenes
  Caption = 'Almacenes'
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
            object dbcGrdDBTabPrinCODIGO_ALMACEN_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Almac'#233'n'
              DataBinding.FieldName = 'CODIGO_ALMACEN_ALM'
              Width = 149
            end
            object dbcGrdDBTabPrinCODIGO_PADRE_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Padre'
              DataBinding.FieldName = 'CODIGO_PADRE_ALM'
              Width = 130
            end
            object dbcGrdDBTabPrinCODIGO_EMPRESA_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Empresa'
              DataBinding.FieldName = 'CODIGO_EMPRESA_ALM'
              Width = 147
            end
            object dbcGrdDBTabPrinNOMBRE_ALMACEN_ALM: TcxGridDBColumn
              Caption = 'Nombre Almac'#233'n'
              DataBinding.FieldName = 'NOMBRE_ALMACEN_ALM'
              Width = 250
            end
            object dbcGrdDBTabPrinESACTIVO_ALM: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_ALM'
              Width = 89
            end
            object dbcGrdDBTabPrinESFISICO_ALM: TcxGridDBColumn
              Caption = 'Es F'#237'sico'
              DataBinding.FieldName = 'ESFISICO_ALM'
              Width = 97
            end
            object dbcGrdDBTabPrinTIPO_USO_ALM: TcxGridDBColumn
              Caption = 'Tipo Uso'
              DataBinding.FieldName = 'TIPO_USO_ALM'
              Width = 100
            end
            object dbcGrdDBTabPrinDIRECCION_ALM: TcxGridDBColumn
              Caption = 'Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION_ALM'
              Width = 200
            end
            object dbcGrdDBTabPrinPOBLACION_ALM: TcxGridDBColumn
              Caption = 'Poblaci'#243'n'
              DataBinding.FieldName = 'POBLACION_ALM'
              Width = 150
            end
            object dbcGrdDBTabPrinCODIGO_POSTAL_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Postal'
              DataBinding.FieldName = 'CODIGO_POSTAL_ALM'
              Width = 154
            end
            object dbcGrdDBTabPrinTELEFONO_ALM: TcxGridDBColumn
              Caption = 'Tel'#233'fono'
              DataBinding.FieldName = 'TELEFONO_ALM'
              Width = 100
            end
            object dbcGrdDBTabPrinEMAIL_ALM: TcxGridDBColumn
              Caption = 'Email'
              DataBinding.FieldName = 'EMAIL_ALM'
              Width = 150
            end
            object dbcGrdDBTabPrinCODIGO_CLIENTE_ALM: TcxGridDBColumn
              Caption = 'C'#243'digo Cliente'
              DataBinding.FieldName = 'CODIGO_CLIENTE_ALM'
              Width = 156
            end
            object dbcGrdDBTabPrinALMACEN_DESTINO_ACTUAL_ALM: TcxGridDBColumn
              Caption = 'Almac'#233'n Destino'
              DataBinding.FieldName = 'ALMACEN_DESTINO_ACTUAL_ALM'
              Width = 155
            end
            object dbcGrdDBTabPrinALMACEN_ORIGEN_ACTUAL_ALM: TcxGridDBColumn
              Caption = 'Almac'#233'n Origen'
              DataBinding.FieldName = 'ALMACEN_ORIGEN_ACTUAL_ALM'
              Width = 141
            end
            object dbcGrdDBTabPrinORDEN_ALM: TcxGridDBColumn
              Caption = 'Orden'
              DataBinding.FieldName = 'ORDEN_ALM'
              HeaderAlignmentHorz = taRightJustify
              Width = 129
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
          Height = 250
          Align = alTop
          BevelOuter = bvNone
          TabOrder = 0
          object pnlBodyFicha: TPanel
            Left = 0
            Top = 0
            Width = 943
            Height = 250
            Align = alClient
            BevelOuter = bvNone
            TabOrder = 0
            object lblCodigo: TcxLabel
              Left = 16
              Top = 16
              Caption = 'C'#243'digo Almac'#233'n'
              TabOrder = 16
              Transparent = True
            end
            object txtCODIGO_ALMACEN_ALM: TcxDBTextEdit
              Left = 164
              Top = 13
              DataBinding.DataField = 'CODIGO_ALMACEN_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 0
              Width = 122
            end
            object lblCodigoEmpresa: TcxLabel
              Left = 17
              Top = 48
              Caption = 'C'#243'digo Empresa'
              TabOrder = 17
              Transparent = True
            end
            object txtCODIGO_EMPRESA_ALM: TcxDBTextEdit
              Left = 164
              Top = 45
              DataBinding.DataField = 'CODIGO_EMPRESA_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 1
              Width = 150
            end
            object lblNombre: TcxLabel
              Left = 11
              Top = 80
              Caption = 'Nombre Almac'#233'n'
              TabOrder = 18
              Transparent = True
            end
            object txtNOMBRE_ALMACEN_ALM: TcxDBTextEdit
              Left = 163
              Top = 76
              DataBinding.DataField = 'NOMBRE_ALMACEN_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 2
              Width = 313
            end
            object chkESACTIVO_ALM: TcxDBCheckBox
              Left = 300
              Top = 16
              Caption = 'Activo'
              DataBinding.DataField = 'ESACTIVO_ALM'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 3
              Transparent = True
            end
            object chkESFISICO_ALM: TcxDBCheckBox
              Left = 380
              Top = 16
              Caption = 'Es F'#237'sico'
              DataBinding.DataField = 'ESFISICO_ALM'
              DataBinding.DataSource = dsTablaG
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              TabOrder = 4
              Transparent = True
            end
            object lblCodigoPadre: TcxLabel
              Left = 42
              Top = 112
              Caption = 'C'#243'digo Padre'
              TabOrder = 19
              Transparent = True
            end
            object txtCODIGO_PADRE_ALM: TcxDBTextEdit
              Left = 163
              Top = 108
              DataBinding.DataField = 'CODIGO_PADRE_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 5
              Width = 150
            end
            object lblTipoUso: TcxLabel
              Left = 53
              Top = 144
              Caption = 'Tipo de Uso'
              TabOrder = 20
              Transparent = True
            end
            object txtTIPO_USO_ALM: TcxDBTextEdit
              Left = 163
              Top = 141
              DataBinding.DataField = 'TIPO_USO_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 6
              Width = 150
            end
            object lblDireccion: TcxLabel
              Left = 73
              Top = 176
              Caption = 'Direcci'#243'n'
              TabOrder = 21
              Transparent = True
            end
            object txtDIRECCION_ALM: TcxDBTextEdit
              Left = 163
              Top = 173
              DataBinding.DataField = 'DIRECCION_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 7
              Width = 373
            end
            object lblPoblacion: TcxLabel
              Left = 71
              Top = 208
              Caption = 'Poblaci'#243'n'
              TabOrder = 22
              Transparent = True
            end
            object txtPOBLACION_ALM: TcxDBTextEdit
              Left = 163
              Top = 205
              DataBinding.DataField = 'POBLACION_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 8
              Width = 223
            end
            object lblCodigoPostal: TcxLabel
              Left = 400
              Top = 208
              Caption = 'C'#243'digo Postal'
              TabOrder = 23
              Transparent = True
            end
            object txtCODIGO_POSTAL_ALM: TcxDBTextEdit
              Left = 527
              Top = 206
              DataBinding.DataField = 'CODIGO_POSTAL_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 9
              Width = 100
            end
            object lblTelefono: TcxLabel
              Left = 550
              Top = 16
              Caption = 'Tel'#233'fono'
              TabOrder = 24
              Transparent = True
            end
            object txtTELEFONO_ALM: TcxDBTextEdit
              Left = 706
              Top = 12
              DataBinding.DataField = 'TELEFONO_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 10
              Width = 164
            end
            object lblEmail: TcxLabel
              Left = 550
              Top = 48
              Caption = 'Email'
              TabOrder = 25
              Transparent = True
            end
            object txtEMAIL_ALM: TcxDBTextEdit
              Left = 620
              Top = 45
              DataBinding.DataField = 'EMAIL_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 11
              Width = 250
            end
            object lblCodigoCliente: TcxLabel
              Left = 550
              Top = 80
              Caption = 'C'#243'digo Cliente'
              TabOrder = 26
              Transparent = True
            end
            object txtCODIGO_CLIENTE_ALM: TcxDBTextEdit
              Left = 720
              Top = 76
              DataBinding.DataField = 'CODIGO_CLIENTE_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 12
              Width = 150
            end
            object lblAlmacenDestino: TcxLabel
              Left = 550
              Top = 112
              Caption = 'Almac'#233'n Destino'
              TabOrder = 27
              Transparent = True
            end
            object txtALMACEN_DESTINO_ACTUAL_ALM: TcxDBTextEdit
              Left = 720
              Top = 108
              DataBinding.DataField = 'ALMACEN_DESTINO_ACTUAL_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 13
              Width = 150
            end
            object lblAlmacenOrigen: TcxLabel
              Left = 550
              Top = 144
              Caption = 'Almac'#233'n Origen'
              TabOrder = 28
              Transparent = True
            end
            object txtALMACEN_ORIGEN_ACTUAL_ALM: TcxDBTextEdit
              Left = 720
              Top = 140
              DataBinding.DataField = 'ALMACEN_ORIGEN_ACTUAL_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 14
              Width = 150
            end
            object lblOrden: TcxLabel
              Left = 550
              Top = 176
              Caption = 'Orden'
              TabOrder = 29
              Transparent = True
            end
            object spnORDEN_ALM: TcxDBSpinEdit
              Left = 720
              Top = 173
              DataBinding.DataField = 'ORDEN_ALM'
              DataBinding.DataSource = dsTablaG
              TabOrder = 15
              Width = 100
            end
          end
        end
        object pnlButtonFicha: TPanel
          Left = 0
          Top = 258
          Width = 943
          Height = 226
          Align = alClient
          BevelOuter = bvNone
          TabOrder = 2
          object pcDetail: TcxPageControl
            Left = 0
            Top = 0
            Width = 943
            Height = 226
            Align = alClient
            TabOrder = 0
            Properties.ActivePage = tsCajas
            Properties.CustomButtons.Buttons = <>
            ClientRectBottom = 222
            ClientRectLeft = 4
            ClientRectRight = 939
            ClientRectTop = 30
            object tsCajas: TcxTabSheet
              Caption = '&1 Cajas de Venta'
              ImageIndex = 1
            end
            object tsAuditoria: TcxTabSheet
              Caption = 'Auditor'#237'a'
              ImageIndex = 0
              object pnl3: TPanel
                Left = 0
                Top = 0
                Width = 935
                Height = 192
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
                  Left = 136
                  Top = 13
                  DataBinding.DataField = 'USUARIOALTA'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 0
                  Width = 150
                end
                object lblInstanteAlta: TcxLabel
                  Left = 16
                  Top = 48
                  Caption = 'Instante Alta'
                  TabOrder = 5
                  Transparent = True
                end
                object txtINSTANTEALTA: TcxDBTextEdit
                  Left = 136
                  Top = 45
                  DataBinding.DataField = 'INSTANTEALTA'
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
                  DataBinding.DataField = 'USUARIOMODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 2
                  Width = 150
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
                  DataBinding.DataField = 'INSTANTEMODIF'
                  DataBinding.DataSource = dsTablaG
                  Properties.ReadOnly = True
                  TabOrder = 3
                  Width = 200
                end
              end
            end
          end
        end
        object splSplitterFicha: TcxSplitter
          Left = 0
          Top = 250
          Width = 943
          Height = 8
          HotZoneClassName = 'TcxMediaPlayer9Style'
          AlignSplitter = salTop
          Control = pnlButtonFicha
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
end
