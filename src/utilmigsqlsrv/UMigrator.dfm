object FormMigrator: TFormMigrator
  Left = 0
  Top = 0
  Caption = 'Factuzam Migrator SQL Server'
  ClientHeight = 930
  ClientWidth = 1024
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1024
    Height = 200
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    TabOrder = 0
    object PanelOrigen: TGroupBox
      Left = 8
      Top = 8
      Width = 500
      Height = 184
      Caption = ' Origen: SQL Server '
      TabOrder = 0
      object lblSrcHost: TLabel
        Left = 16
        Top = 28
        Width = 116
        Height = 17
        Caption = 'Host / Servidor:'
      end
      object lblSrcPort: TLabel
        Left = 16
        Top = 58
        Width = 51
        Height = 17
        Caption = 'Puerto:'
      end
      object lblSrcBase: TLabel
        Left = 16
        Top = 88
        Width = 105
        Height = 17
        Caption = 'Base de datos:'
      end
      object lblSrcUser: TLabel
        Left = 16
        Top = 118
        Width = 60
        Height = 17
        Caption = 'Usuario:'
      end
      object lblSrcPwd: TLabel
        Left = 16
        Top = 148
        Width = 84
        Height = 17
        Caption = 'Contrase'#241'a:'
      end
      object edSrcHost: TEdit
        Left = 130
        Top = 25
        Width = 340
        Height = 25
        TabOrder = 0
      end
      object edSrcPort: TEdit
        Left = 130
        Top = 55
        Width = 80
        Height = 25
        TabOrder = 1
        Text = '1433'
      end
      object edSrcBase: TEdit
        Left = 130
        Top = 85
        Width = 200
        Height = 25
        TabOrder = 2
      end
      object edSrcUser: TEdit
        Left = 130
        Top = 115
        Width = 200
        Height = 25
        TabOrder = 3
        Text = 'sa'
      end
      object edSrcPwd: TEdit
        Left = 130
        Top = 145
        Width = 200
        Height = 25
        PasswordChar = '*'
        TabOrder = 4
      end
      object btnProbarSrc: TButton
        Left = 350
        Top = 144
        Width = 140
        Height = 25
        Caption = 'Probar conexi'#243'n'
        TabOrder = 5
        OnClick = btnProbarSrcClick
      end
      object chkSrcWinAuth: TCheckBox
        Left = 350
        Top = 118
        Width = 140
        Height = 17
        Caption = 'Auth. Windows'
        TabOrder = 6
        OnClick = chkSrcWinAuthClick
      end
    end
    object PanelDestino: TGroupBox
      Left = 514
      Top = 8
      Width = 500
      Height = 184
      Caption = ' Destino: MariaDB Factuzam '
      TabOrder = 1
      object lblDstHost: TLabel
        Left = 16
        Top = 28
        Width = 116
        Height = 17
        Caption = 'Host / Servidor:'
      end
      object lblDstPort: TLabel
        Left = 16
        Top = 58
        Width = 51
        Height = 17
        Caption = 'Puerto:'
      end
      object lblDstBase: TLabel
        Left = 16
        Top = 88
        Width = 105
        Height = 17
        Caption = 'Base de datos:'
      end
      object lblDstUser: TLabel
        Left = 16
        Top = 118
        Width = 60
        Height = 17
        Caption = 'Usuario:'
      end
      object lblDstPwd: TLabel
        Left = 16
        Top = 148
        Width = 84
        Height = 17
        Caption = 'Contrase'#241'a:'
      end
      object edDstHost: TEdit
        Left = 130
        Top = 25
        Width = 340
        Height = 25
        TabOrder = 0
        Text = '127.0.0.1'
      end
      object edDstPort: TEdit
        Left = 130
        Top = 55
        Width = 80
        Height = 25
        TabOrder = 1
        Text = '3306'
      end
      object edDstBase: TEdit
        Left = 130
        Top = 85
        Width = 200
        Height = 25
        TabOrder = 2
        Text = 'factuzam'
      end
      object edDstUser: TEdit
        Left = 130
        Top = 115
        Width = 200
        Height = 25
        TabOrder = 3
        Text = 'root'
      end
      object edDstPwd: TEdit
        Left = 130
        Top = 145
        Width = 200
        Height = 25
        PasswordChar = '*'
        TabOrder = 4
      end
      object btnProbarDst: TButton
        Left = 350
        Top = 144
        Width = 147
        Height = 25
        Caption = 'Probar conexi'#243'n'
        TabOrder = 5
        OnClick = btnProbarDstClick
      end
    end
  end
  object PanelSetup: TPanel
    Left = 0
    Top = 200
    Width = 1024
    Height = 90
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Top = 4
    Padding.Right = 8
    Padding.Bottom = 4
    TabOrder = 1
    object GroupSetup: TGroupBox
      Left = 8
      Top = 4
      Width = 1008
      Height = 82
      Align = alClient
      Caption = ' Preparar BBDD destino '
      TabOrder = 0
      object btnDumpEsqueleto: TButton
        Left = 16
        Top = 18
        Width = 280
        Height = 25
        Caption = 'Extraer esqueleto de BBDD viva'#8230
        TabOrder = 0
        OnClick = btnDumpEsqueletoClick
      end
      object btnCrearBBDD: TButton
        Left = 310
        Top = 18
        Width = 317
        Height = 25
        Caption = 'Crear BBDD destino (utf8mb4_spanish_ci)'
        TabOrder = 1
        OnClick = btnCrearBBDDClick
      end
      object btnCargarEsquema: TButton
        Left = 646
        Top = 17
        Width = 240
        Height = 25
        Caption = 'Cargar esqueleto en destino'#8230
        TabOrder = 2
        OnClick = btnCargarEsquemaClick
      end
      object btnLimpiarDemo: TButton
        Left = 16
        Top = 48
        Width = 200
        Height = 25
        Caption = 'Limpiar datos demo'
        TabOrder = 3
        OnClick = btnLimpiarDemoClick
      end
      object btnResetearMig: TButton
        Left = 220
        Top = 48
        Width = 362
        Height = 25
        Caption = 'Reset migracion (USUARIO_ALTA=MIGRADOR)'
        TabOrder = 4
        OnClick = btnResetearMigClick
      end
      object btnBorrarBBDD: TButton
        Left = 598
        Top = 48
        Width = 288
        Height = 25
        Caption = 'Borrar BBDD destino (DROP)...'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -15
        Font.Name = 'Lucida Sans'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
        OnClick = btnBorrarBBDDClick
      end
    end
  end
  object PanelCentro: TPanel
    Left = 0
    Top = 290
    Width = 1024
    Height = 250
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 8
    Padding.Right = 8
    Padding.Bottom = 8
    TabOrder = 2
    object lblUsuario: TLabel
      Left = 16
      Top = 14
      Width = 164
      Height = 17
      Caption = 'Usuario para auditor'#237'a:'
    end
    object lblNivelFam: TLabel
      Left = 380
      Top = 14
      Width = 142
      Height = 17
      Caption = 'Nivel familias hoja:'
    end
<<<<<<< HEAD
    object lblDigitosArt: TLabel
      Left = 580
      Top = 14
      Width = 152
      Height = 17
      Caption = 'D'#237'gitos contador art.:'
    end
=======
>>>>>>> 882d8675f7cf4513994d8ab6ddea39a2fcc16eff
    object lblHilos: TLabel
      Left = 780
      Top = 14
      Width = 114
      Height = 17
      Caption = 'Hilos paralelos:'
    end
    object edUsuario: TEdit
      Left = 160
      Top = 11
      Width = 200
      Height = 25
      TabOrder = 0
      Text = 'MIGRADOR'
    end
    object edNivelFam: TEdit
      Left = 520
      Top = 11
      Width = 40
      Height = 25
      TabOrder = 1
      Text = '4'
    end
<<<<<<< HEAD
    object edDigitosArt: TEdit
      Left = 720
      Top = 11
      Width = 40
      Height = 25
      TabOrder = 2
      Text = '4'
    end
=======
>>>>>>> 882d8675f7cf4513994d8ab6ddea39a2fcc16eff
    object edHilos: TEdit
      Left = 890
      Top = 11
      Width = 40
      Height = 25
      TabOrder = 3
      Text = '4'
    end
    object GroupListado: TGroupBox
      Left = 8
      Top = 42
      Width = 1008
      Height = 200
      Caption = ' Migraciones disponibles (orden de ejecuci'#243'n) '
      TabOrder = 4
      object listMigs: TCheckListBox
        Left = 16
        Top = 24
        Width = 800
        Height = 165
        ItemHeight = 17
        TabOrder = 0
      end
      object btnMarcarTodas: TButton
        Left = 830
        Top = 24
        Width = 160
        Height = 25
        Caption = 'Marcar todas'
        TabOrder = 1
        OnClick = btnMarcarTodasClick
      end
      object btnDesmarcarTodas: TButton
        Left = 830
        Top = 55
        Width = 160
        Height = 25
        Caption = 'Desmarcar todas'
        TabOrder = 2
        OnClick = btnDesmarcarTodasClick
      end
      object btnEjecutar: TButton
        Left = 830
        Top = 130
        Width = 175
        Height = 35
        Caption = 'Ejecutar migraciones'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Lucida Sans'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        OnClick = btnEjecutarClick
      end
    end
  end
  object PageInferior: TPageControl
    Left = 0
    Top = 540
    Width = 1024
    Height = 371
    ActivePage = TabProgreso
    Align = alClient
    TabOrder = 3
    object TabProgreso: TTabSheet
      Caption = 'Progreso (dominios activos)'
      object MemoProgreso: TMemo
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1010
        Height = 333
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object TabLog: TTabSheet
      Caption = 'Log acumulado'
      ImageIndex = 1
      object MemoLog: TMemo
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1010
        Height = 333
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object TabErrores: TTabSheet
      Caption = 'Errores y avisos (! del log)'
      ImageIndex = 2
      object MemoErrores: TMemo
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 1010
        Height = 333
        Align = alClient
        Color = clGhostWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 911
    Width = 1024
    Height = 19
    Panels = <
      item
        Width = 800
      end>
  end
end
