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
    ExplicitLeft = 0
    ExplicitTop = 0
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
            DataBinding.FieldName = 'ID_ATB_VA'
            Visible = False
          end
          object tvMaestroID_VA: TcxGridDBColumn
            DataBinding.FieldName = 'ID_VAR_VA'
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
          object tvMaestroORDEN_ACA: TcxGridDBColumn
            Caption = 'Orden'
            DataBinding.FieldName = 'ORDEN_ACA'
            HeaderAlignmentHorz = taRightJustify
            Options.Editing = False
            Width = 130
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
        Height = 10
        HotZoneClassName = 'TcxMediaPlayer9Style'
        AlignSplitter = salTop
        Control = pnlBodyCab
        ExplicitWidth = 726
      end
      object cxGrid2: TcxGrid
        Left = 1
        Top = 11
        Width = 728
        Height = 292
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 726
        ExplicitHeight = 284
        object tvDetalle: TcxGridDBTableView
          OnCellDblClick = tvDetalleCellDblClick
          DataController.DataSource = dsDetalle
          OptionsView.GroupByBox = False
          object tvDetalleID_ATRIBUTO_AC: TcxGridDBColumn
            DataBinding.FieldName = 'ID_VA_AC'
            Visible = False
          end
          object tvDetalleID_CONJUNTO_AC: TcxGridDBColumn
            DataBinding.FieldName = 'ID_AC'
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
            DataBinding.FieldName = 'ID_ATB_VA'
            Visible = False
          end
          object tvDetalleORDEN_AV: TcxGridDBColumn
            Caption = 'Orden (doble click cambiar orden)'
            DataBinding.FieldName = 'ORDEN_AV'
            HeaderAlignmentHorz = taRightJustify
            Options.Editing = False
            Width = 299
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
      'SELECT aca.CODIGO_ART_ACA, aca.ID_VA_ACA AS ID_ATB_VA,'
      '       va.ID_VAR_VA,'
      '       COALESCE(va.NOMBRE_VA, aca.ID_VA_ACA) AS NOMBRE_ATRIBUTO,'
      '       va.ORDEN_VA,'
      '       aca.ORDEN_ACA'
      '  FROM fza_articulos_conjuntos_asign aca'
      '  JOIN fza_variaciones_atributos va'
      '    ON va.ID_ATB_VA = aca.ID_VA_ACA'
      '   AND va.ID_VAR_VA = :var'
      ' WHERE aca.CODIGO_ART_ACA = :art'
      
        ' ORDER BY COALESCE(NULLIF(aca.ORDEN_ACA, 0), va.ORDEN_VA), va.OR' +
        'DEN_VA')
    Active = True
    Left = 600
    Top = 64
    ParamData = <
      item
        DataType = ftWideString
        Name = 'var'
        ParamType = ptInput
        Value = ''
      end
      item
        DataType = ftWideString
        Name = 'art'
        ParamType = ptInput
        Value = ''
      end>
  end
  object unqryDetalle: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT  '
      '             atr.ID_ATB_VA,  '
      '             val.ID_AV AS ID_AC,  '
      '             val.AV AS NOMBRE_AC,  '
      '             val.ORDEN_AV,  '
      '             0 AS ASIGNADO  '
      '        FROM fza_variaciones_atributos atr  '
      '        JOIN fza_articulos_conjuntos_asign asign  '
      '          ON asign.ID_VA_ACA = atr.ID_ATB_VA  '
      '         AND asign.CODIGO_ART_ACA = '#39'DEMO-CAMISA'#39'  '
      '        JOIN fza_atributos_conjuntos_det det  '
      '          ON det.ID_AC_ACD = asign.ID_AC_ACA  '
      '        JOIN fza_atributos_valores val  '
      '          ON val.ID_AV = det.ID_AV_ACD  '
      '       '
      '')
    MasterSource = dsMaestro
    MasterFields = 'ID_ATB_VA'
    DetailFields = 'ID_ATB_VA'
    Active = True
    Left = 680
    Top = 56
    ParamData = <
      item
        DataType = ftWideString
        Name = 'ID_ATB_VA'
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
