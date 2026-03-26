inherited frmMtoModalGenerarSKUS: TfrmMtoModalGenerarSKUS
  Caption = 'Generar SKUS'
  ClientHeight = 485
  ClientWidth = 732
  StyleElements = [seFont, seClient, seBorder]
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 748
  ExplicitHeight = 524
  TextHeight = 19
  inherited pnlButton: TPanel
    Top = 426
    Width = 732
    StyleElements = [seFont, seClient, seBorder]
    ExplicitTop = 341
    ExplicitWidth = 524
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
  end
  inherited pnlBody: TPanel
    Width = 732
    Height = 426
    StyleElements = [seFont, seClient, seBorder]
    ExplicitWidth = 524
    ExplicitHeight = 341
    object pnlBodyCab: TPanel
      Left = 1
      Top = 1
      Width = 730
      Height = 120
      Align = alTop
      TabOrder = 0
      object cxGrid1: TcxGrid
        Left = 1
        Top = 1
        Width = 728
        Height = 118
        Align = alClient
        TabOrder = 0
        ExplicitLeft = 200
        ExplicitTop = 2
        ExplicitWidth = 250
        ExplicitHeight = 200
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
      ExplicitLeft = 304
      ExplicitTop = 240
      ExplicitWidth = 185
      ExplicitHeight = 41
      object cxSplitter1: TcxSplitter
        Left = 1
        Top = 1
        Width = 728
        Height = 8
        HotZoneClassName = 'TcxMediaPlayer9Style'
        AlignSplitter = salTop
        Control = pnlBodyCab
        ExplicitWidth = 246
      end
      object cxGrid2: TcxGrid
        Left = 1
        Top = 9
        Width = 728
        Height = 294
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 200
        ExplicitTop = 2
        ExplicitWidth = 250
        ExplicitHeight = 200
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
            DataBinding.FieldName = 'NOMBRE_AC'
            Width = 168
          end
          object tvDetalleASIGNADO: TcxGridDBColumn
            DataBinding.FieldName = 'ASIGNADO'
            PropertiesClassName = 'TcxCheckBoxProperties'
            Properties.Alignment = taRightJustify
            Properties.ValueChecked = '1'
            Properties.ValueUnchecked = '0'
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
      '    WHERE va.ID_VA = :var '
      '    ORDER BY va.ORDEN_VA')
    Active = True
    Left = 600
    Top = 64
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'var'
        Value = nil
      end>
  end
  object unqryDetalle: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      '    SELECT  '
      '      val.ID_ATRIBUTO_AC,  '
      '      val.ID_CONJUNTO_AC,  '
      '      val.NOMBRE_AC,  '
      
        '      CASE WHEN asign.ID_CONJUNTO_ACA IS NOT NULL THEN 1 ELSE 0 ' +
        'END AS ASIGNADO  '
      '    FROM fza_atributos_conjuntos val  '
      '    LEFT JOIN fza_articulos_conjuntos_asign asign  '
      '           ON asign.ID_CONJUNTO_ACA = val.ID_CONJUNTO_AC  '
      '          AND asign.CODIGO_ARTICULO_ACA = :Articulo  '
      '    WHERE val.ID_ATRIBUTO_AC IN (  '
      
        '            SELECT ID_ATRIBUTO_VA FROM fza_variaciones_atributos' +
        ' WHERE ID_VA = :Variacion  '
      '          )  '
      '    ORDER BY val.NOMBRE_AC;'
      '')
    MasterSource = dsMaestro
    MasterFields = 'ID_ATRIBUTO_VA'
    DetailFields = 'ID_ATRIBUTO_AC'
    Active = True
    Left = 680
    Top = 56
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'Articulo'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'Variacion'
        Value = nil
      end
      item
        DataType = ftWideString
        Name = 'ID_ATRIBUTO_VA'
        ParamType = ptInput
        Value = nil
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
