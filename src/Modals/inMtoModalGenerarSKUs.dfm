inherited frmMtoModalGenerarSKUS: TfrmMtoModalGenerarSKUS
  Caption = 'Generar SKUS'
  ClientHeight = 485
  ClientWidth = 732
  StyleElements = [seFont, seClient, seBorder]
  ExplicitWidth = 748
  ExplicitHeight = 524
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 426
    Width = 732
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 418
    ExplicitWidth = 730
    inherited btnCancelar: TcxButton
      Left = 50
      Top = 6
      OnClick = btnCancelarClick
      ExplicitLeft = 50
      ExplicitTop = 6
    end
    inherited btnAceptar: TcxButton
      Left = 533
      Top = 6
      ExplicitLeft = 533
      ExplicitTop = 6
    end
    object btnAddValue: TcxButton
      Left = 290
      Top = 6
      Width = 177
      Height = 40
      Cancel = True
      Caption = '&A'#241'adir Valor (F3)'
      TabOrder = 2
      OnClick = btnAddValueClick
    end
  end
  inherited pnlBody: TPanel
    Width = 732
    Height = 426
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 730
    ExplicitHeight = 418
    object pnlBodyCab: TPanel
      Left = 1
      Top = 1
      Width = 730
      Height = 120
      Align = alTop
      TabOrder = 0
      ExplicitWidth = 728
      object cxGrid1: TcxGrid
        Left = 1
        Top = 1
        Width = 728
        Height = 118
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 726
        object tvMaestro: TcxGridDBTableView
          DataController.DataSource = dsMaestro
          OptionsView.GroupByBox = False
          object tvMaestroID_ATRIBUTO_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ID_ATRIBUTO_VA'
            Visible = False
          end
          object tvMaestroID_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ID_VA'
            Visible = False
          end
          object tvMaestroNOMBRE_ATRIBUTO: TcxGridDBColumn
            Caption = 'Variaci'#243'n'
            DataBinding.FieldName = 'NOMBRE_ATRIBUTO'
            Width = 183
          end
          object tvMaestroORDEN_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ORDEN_VA'
            Visible = False
          end
        end
        object cxGrid1Level1: TcxGridLevel
          GridView = tvMaestro
        end
      end
    end
    object pnlBodyDetalle: TPanel
      Left = 1
      Top = 121
      Width = 730
      Height = 304
      Align = alClient
      TabOrder = 1
      ExplicitWidth = 728
      ExplicitHeight = 296
      object cxSplitter1: TcxSplitter
        Left = 1
        Top = 1
        Width = 728
        Height = 8
        HotZoneClassName = 'TcxMediaPlayer9Style'
        AlignSplitter = salTop
        Control = pnlBodyCab
        ExplicitWidth = 726
      end
      object cxGrid2: TcxGrid
        Left = 1
        Top = 9
        Width = 728
        Height = 294
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 726
        ExplicitHeight = 286
        object tvDetalle: TcxGridDBTableView
          DataController.DataSource = dsDetalle
          OptionsView.GroupByBox = False
          object tvDetalleID_ATRIBUTO_AC: TcxGridDBColumn
            DataBinding.FieldName = 'ID_ATRIBUTO_AC'
            Visible = False
          end
          object tvDetalleID_CONJUNTO_AC: TcxGridDBColumn
            DataBinding.FieldName = 'ID_CONJUNTO_AC'
            Visible = False
            Width = 167
          end
          object tvDetalleNOMBRE_AC: TcxGridDBColumn
            Caption = 'Nombre Atr'
            DataBinding.FieldName = 'NOMBRE_AC'
            Width = 168
          end
          object tvDetalleASIGNADO: TcxGridDBColumn
            Caption = 'Asignar'
            DataBinding.FieldName = 'ASIGNADO'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Properties.Alignment = taRightJustify
            Properties.ValueChecked = '1'
            Properties.ValueUnchecked = '0'
          end
          object tvDetalleID_ATRIBUTO_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ID_ATRIBUTO_VA'
            Visible = False
          end
          object tvDetalleORDEN_AV: TcxGridDBColumn
            Caption = 'Orden'
            DataBinding.FieldName = 'ORDEN_AV'
            HeaderAlignmentHorz = taRightJustify
          end
        end
        object cxGridLevel1: TcxGridLevel
          GridView = tvDetalle
        end
      end
    end
  end
  object unqryMaestro: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT va.ID_ATRIBUTO_VA,  va.ID_VA,'
      
        '       COALESCE(va.NOMBRE_VA, va.ID_ATRIBUTO_VA) AS NOMBRE_ATRIB' +
        'UTO, '
      '       va.ORDEN_VA '
      '    FROM fza_variaciones_atributos va '
      '    ORDER BY va.ORDEN_VA')
    Active = True
    Left = 600
    Top = 64
  end
  object unqryDetalle: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT  '
      '             atr.ID_ATRIBUTO_VA,  '
      '             val.ID_VALOR_AV AS ID_CONJUNTO_AC,  '
      '             val.VALOR_AV AS NOMBRE_AC,  '
      '             val.ORDEN_AV,  '
      '             0 AS ASIGNADO  '
      '        FROM fza_variaciones_atributos atr  '
      '        JOIN fza_articulos_conjuntos_asign asign  '
      '          ON asign.ID_ATRIBUTO_ACA = atr.ID_ATRIBUTO_VA  '
      '         AND asign.CODIGO_ARTICULO_ACA = '#39'DEMO-CAMISA'#39'  '
      '        JOIN fza_atributos_conjuntos_det det  '
      '          ON det.ID_CONJUNTO_ACD = asign.ID_CONJUNTO_ACA  '
      '        JOIN fza_atributos_valores val  '
      '          ON val.ID_VALOR_AV = det.ID_VALOR_ACD  '
      '       '
      '')
    MasterSource = dsMaestro
    MasterFields = 'ID_ATRIBUTO_VA'
    DetailFields = 'ID_ATRIBUTO_VA'
    Active = True
    Left = 680
    Top = 56
    ParamData = <
      item
        DataType = ftWideString
        Name = 'ID_ATRIBUTO_VA'
        ParamType = ptInput
        Value = 'CO'
      end>
  end
  object dsMaestro: TDataSource
    DataSet = unqryMaestro
    Left = 592
    Top = 144
  end
  object dsDetalle: TDataSource
    DataSet = unqryDetalle
    Left = 688
    Top = 144
  end
end
