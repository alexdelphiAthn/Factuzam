inherited frmMtoAlbaranes: TfrmMtoAlbaranes
  Caption = 'Mantenimiento de Albaranes'
  ClientHeight = 765
  ClientWidth = 1085
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 1085
  ExplicitHeight = 765
  TextHeight = 19
  OnCreate = FormCreate
  inherited pButtonPage: TPanel
    Width = 945
    Height = 765
    StyleElements = [seFont, seClient, seBorder]
    inherited pcPantalla: TcxPageControl
      Width = 945
      Height = 725
      Properties.ActivePage = tsLista
      ClientRectBottom = 721
      ClientRectRight = 941
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          Width = 937
          Height = 691
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            object dbcGrdAlbNUMERO_ALB: TcxGridDBColumn
              Caption = 'N'#250'mero'
              DataBinding.FieldName = 'NUMERO_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_ALB: TcxGridDBColumn
              Caption = 'Serie'
              DataBinding.FieldName = 'SERIE_ALB'
              Width = 80
            end
            object dbcGrdAlbFECHA_ALB: TcxGridDBColumn
              Caption = 'Fecha'
              DataBinding.FieldName = 'FECHA_ALB'
              Width = 100
            end
            object dbcGrdAlbESTADO_ALB: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_ALB'
              Width = 110
            end
            object dbcGrdAlbCODIGO_EMP_ALB: TcxGridDBColumn
              Caption = 'Empresa'
              DataBinding.FieldName = 'CODIGO_EMP_ALB'
              Width = 100
            end
            object dbcGrdAlbRSEMP_ALB: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Empresa'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMPRESA_ALB'
              Width = 220
            end
            object dbcGrdAlbCODIGO_CLI_ALB: TcxGridDBColumn
              Caption = 'Cliente'
              DataBinding.FieldName = 'CODIGO_CLI_ALB'
              Width = 100
            end
            object dbcGrdAlbRSCLI_ALB: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Cliente'
              DataBinding.FieldName = 'RAZON_SOCIAL_CLIENTE_ALB'
              Width = 220
            end
            object dbcGrdAlbNUMERO_PED_ALB: TcxGridDBColumn
              Caption = 'Pedido'
              DataBinding.FieldName = 'NUMERO_PED_ALB'
              Width = 90
            end
            object dbcGrdAlbSERIE_PED_ALB: TcxGridDBColumn
              Caption = 'Serie Pedido'
              DataBinding.FieldName = 'SERIE_PED_ALB'
              Width = 90
            end
            object dbcGrdAlbTOTAL_LIQUIDO_ALB: TcxGridDBColumn
              Caption = 'Total'
              DataBinding.FieldName = 'TOTAL_LIQUIDO_ALB'
              Width = 110
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        object pcCab: TcxPageControl
          Left = 0
          Top = 0
          Width = 937
          Height = 220
          Align = alTop
          TabOrder = 0
          Properties.ActivePage = tsCabecera
          ClientRectBottom = 216
          ClientRectRight = 933
          ClientRectTop = 24
          object tsCabecera: TcxTabSheet
            Caption = 'Cabecera'
            object lblNroAlbaran: TcxLabel
              Left = 8
              Top = 12
              Caption = 'N'#250'mero'
            end
            object txtNUMERO_ALB: TcxDBTextEdit
              Left = 8
              Top = 32
              DataBinding.DataField = 'NUMERO_ALB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 0
              Width = 100
            end
            object lblSerieAlbaran: TcxLabel
              Left = 116
              Top = 12
              Caption = 'Serie'
            end
            object txtSERIE_ALB: TcxDBTextEdit
              Left = 116
              Top = 32
              DataBinding.DataField = 'SERIE_ALB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 1
              Width = 80
            end
            object lblFechaAlbaran: TcxLabel
              Left = 204
              Top = 12
              Caption = 'Fecha'
            end
            object dteFECHA_ALB: TcxDBDateEdit
              Left = 204
              Top = 32
              DataBinding.DataField = 'FECHA_ALB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 2
              Width = 110
            end
            object lblEstadoAlbaran: TcxLabel
              Left = 320
              Top = 12
              Caption = 'Estado'
            end
            object txtESTADO_ALB: TcxDBTextEdit
              Left = 320
              Top = 32
              DataBinding.DataField = 'ESTADO_ALB'
              DataBinding.DataSource = dsTablaG
              TabOrder = 3
              Width = 110
            end
            object lblPedidoOrigen: TcxLabel
              Left = 440
              Top = 12
              Caption = 'Pedido origen (N'#250'mero / Serie)'
            end
            object txtNUMERO_PED_ALB: TcxDBTextEdit
              Left = 440
              Top = 32
              DataBinding.DataField = 'NUMERO_PED_ALB'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 4
              Width = 90
            end
            object txtSERIE_PED_ALB: TcxDBTextEdit
              Left = 540
              Top = 32
              DataBinding.DataField = 'SERIE_PED_ALB'
              DataBinding.DataSource = dsTablaG
              Properties.ReadOnly = True
              TabOrder = 5
              Width = 80
            end
            object lblCodigoEmpresa: TcxLabel
              Left = 8
              Top = 76
              Caption = 'Empresa Emisora'
            end
            object btnCODIGO_EMP_ALB: TcxDBButtonEdit
              Left = 8
              Top = 96
              DataBinding.DataField = 'CODIGO_EMP_ALB'
              DataBinding.DataSource = dsTablaG
              Properties.Buttons = <
                item
                  Default = True
                  Kind = bkEllipsis
                end>
              TabOrder = 6
              Width = 130
            end
            object cxdblblRAZON_SOCIAL_EMPRESA_ALB: TcxDBLabel
              Left = 144
              Top = 96
              DataBinding.DataField = 'RAZON_SOCIAL_EMPRESA_ALB'
              DataBinding.DataSource = dsTablaG
              Style.Font.Style = [fsBold]
              Width = 380
            end
            object lblCodigoCliente: TcxLabel
              Left = 8
              Top = 132
              Caption = 'Cliente'
            end
            object btnCODIGO_CLI_ALB: TcxDBButtonEdit
              Left = 8
              Top = 152
              DataBinding.DataField = 'CODIGO_CLI_ALB'
              DataBinding.DataSource = dsTablaG
              Properties.Buttons = <
                item
                  Default = True
                  Kind = bkEllipsis
                end>
              TabOrder = 7
              Width = 130
            end
            object cxdblblRAZON_SOCIAL_CLIENTE_ALB: TcxDBLabel
              Left = 144
              Top = 152
              DataBinding.DataField = 'RAZON_SOCIAL_CLIENTE_ALB'
              DataBinding.DataSource = dsTablaG
              Style.Font.Style = [fsBold]
              Width = 380
            end
          end
        end
        object pcAlbaran: TcxPageControl
          Left = 0
          Top = 220
          Width = 937
          Height = 410
          Align = alClient
          TabOrder = 1
          Properties.ActivePage = tsLineasAlbaran
          ClientRectBottom = 406
          ClientRectRight = 933
          ClientRectTop = 24
          object tsLineasAlbaran: TcxTabSheet
            Caption = 'L'#237'neas Albar'#225'n'
            object cxgrdLineasAlbaran: TcxGrid
              Left = 0
              Top = 0
              Width = 933
              Height = 382
              Align = alClient
              TabOrder = 0
              object tvLineasAlbaran: TcxGridDBTableView
                Navigator.Buttons.CustomButtons = <>
                DataController.Summary.DefaultGroupSummaryItems = <>
                DataController.Summary.FooterSummaryItems = <>
                DataController.Summary.SummaryGroups = <>
                object cxgrdcLineaAlb: TcxGridDBColumn
                  Caption = 'L'#237'nea'
                  DataBinding.FieldName = 'LINEA_ALBLIN'
                  Width = 60
                end
                object cxgrdcArtAlb: TcxGridDBColumn
                  Caption = 'C'#243'digo Art'#237'culo'
                  DataBinding.FieldName = 'CODIGO_ART_ALBLIN'
                  Width = 130
                end
                object cxgrdcDescrAlb: TcxGridDBColumn
                  Caption = 'Descripci'#243'n'
                  DataBinding.FieldName = 'DESCRIPCION_ARTICULO_ALBLIN'
                  Width = 280
                end
                object cxgrdcCantAlb: TcxGridDBColumn
                  Caption = 'Cantidad'
                  DataBinding.FieldName = 'CANTIDAD_ALBLIN'
                  Width = 90
                end
                object cxgrdcPSivaAlb: TcxGridDBColumn
                  Caption = 'PVP S/IVA'
                  DataBinding.FieldName = 'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN'
                  Width = 100
                end
                object cxgrdcPCivaAlb: TcxGridDBColumn
                  Caption = 'PVP C/IVA'
                  DataBinding.FieldName = 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN'
                  Width = 100
                end
                object cxgrdcTotalAlb: TcxGridDBColumn
                  Caption = 'Total'
                  DataBinding.FieldName = 'TOTAL_ALBLIN'
                  Width = 110
                end
                object cxgrdcPedAlb: TcxGridDBColumn
                  Caption = 'L'#237'nea Pedido'
                  DataBinding.FieldName = 'LINEA_PED_ALBLIN'
                  Width = 90
                end
              end
              object cxgrdlvlLineasAlbaran: TcxGridLevel
                GridView = tvLineasAlbaran
              end
            end
          end
        end
        object pnlBottomTotales: TPanel
          Left = 0
          Top = 630
          Width = 937
          Height = 40
          Align = alBottom
          Caption = ''
          TabOrder = 2
          object lblTotalBases: TcxLabel
            Left = 380
            Top = 8
            Caption = 'Bases'
          end
          object curTOTAL_BASES_ALB: TcxDBCurrencyEdit
            Left = 425
            Top = 8
            DataBinding.DataField = 'TOTAL_BASES_ALB'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 0
            Width = 100
          end
          object lblTotalImpuestos: TcxLabel
            Left = 540
            Top = 8
            Caption = 'IVA'
          end
          object curTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit
            Left = 570
            Top = 8
            DataBinding.DataField = 'TOTAL_IMPUESTOS_ALB'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            TabOrder = 1
            Width = 100
          end
          object lblTotalLiquido: TcxLabel
            Left = 690
            Top = 8
            Caption = 'TOTAL'
            Style.Font.Style = [fsBold]
          end
          object curTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit
            Left = 740
            Top = 8
            DataBinding.DataField = 'TOTAL_LIQUIDO_ALB'
            DataBinding.DataSource = dsTablaG
            Properties.ReadOnly = True
            Style.Font.Style = [fsBold]
            TabOrder = 2
            Width = 130
          end
          object btnImprimir: TcxButton
            Left = 8
            Top = 6
            Width = 100
            Height = 28
            Caption = 'Imprimir'
            OnClick = btnImprimirClick
            TabOrder = 3
          end
          object btnFacturar: TcxButton
            Left = 116
            Top = 6
            Width = 130
            Height = 28
            Caption = 'Facturar'
            OnClick = btnFacturarClick
            TabOrder = 4
          end
        end
      end
    end
  end
end
