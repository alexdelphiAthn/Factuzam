object frmTestSqlSrv: TfrmTestSqlSrv
  Left = 0
  Top = 0
  Caption = 'Factuzam - Test UniDAC SQL Server (prDirect / prMSOLEDB)'
  ClientHeight = 561
  ClientWidth = 684
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object gbConexion: TGroupBox
    Left = 0
    Top = 0
    Width = 684
    Height = 145
    Align = alTop
    Caption = ' Conexi'#243'n SQL Server '
    TabOrder = 0
    object lblServidor: TLabel
      Left = 16
      Top = 27
      Width = 48
      Height = 15
      Caption = 'Servidor:'
    end
    object lblPuerto: TLabel
      Left = 330
      Top = 27
      Width = 40
      Height = 15
      Caption = 'Puerto:'
    end
    object lblBase: TLabel
      Left = 16
      Top = 59
      Width = 78
      Height = 15
      Caption = 'Base de datos:'
    end
    object lblUsuario: TLabel
      Left = 16
      Top = 91
      Width = 46
      Height = 15
      Caption = 'Usuario:'
    end
    object lblClave: TLabel
      Left = 270
      Top = 91
      Width = 64
      Height = 15
      Caption = 'Contrase'#241'a:'
    end
    object edtServidor: TEdit
      Left = 100
      Top = 24
      Width = 210
      Height = 23
      TabOrder = 0
      Text = 'localhost'
    end
    object edtPuerto: TEdit
      Left = 386
      Top = 24
      Width = 70
      Height = 23
      TabOrder = 1
      Text = '1433'
    end
    object edtBase: TEdit
      Left = 100
      Top = 56
      Width = 356
      Height = 23
      TabOrder = 2
      Text = 'master'
    end
    object edtUsuario: TEdit
      Left = 100
      Top = 88
      Width = 150
      Height = 23
      TabOrder = 3
      Text = 'sa'
    end
    object edtClave: TEdit
      Left = 350
      Top = 88
      Width = 150
      Height = 23
      PasswordChar = '*'
      TabOrder = 4
    end
    object chkAutWindows: TCheckBox
      Left = 100
      Top = 116
      Width = 320
      Height = 17
      Caption = 'Autenticaci'#243'n Windows (Integrated Security)'
      TabOrder = 5
    end
  end
  object pnlBotones: TPanel
    Left = 0
    Top = 145
    Width = 684
    Height = 49
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object btnConectarDirect: TButton
      Left = 8
      Top = 9
      Width = 150
      Height = 30
      Caption = 'Conectar prDirect'
      TabOrder = 0
      OnClick = btnConectarDirectClick
    end
    object btnConectarNativo: TButton
      Left = 166
      Top = 9
      Width = 180
      Height = 30
      Caption = 'Conectar prMSOLEDB'
      TabOrder = 1
      OnClick = btnConectarNativoClick
    end
    object btnLanzarSQL: TButton
      Left = 400
      Top = 9
      Width = 120
      Height = 30
      Caption = 'Lanzar SQL'
      TabOrder = 2
      OnClick = btnLanzarSQLClick
    end
    object btnDesconectar: TButton
      Left = 548
      Top = 9
      Width = 120
      Height = 30
      Caption = 'Desconectar'
      TabOrder = 3
      OnClick = btnDesconectarClick
    end
  end
  object pnlTiempo: TPanel
    Left = 0
    Top = 194
    Width = 684
    Height = 57
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object lblTiempo: TLabel
      Left = 12
      Top = 8
      Width = 56
      Height = 25
      Caption = '-- ms'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblEstado: TLabel
      Left = 12
      Top = 36
      Width = 119
      Height = 15
      Caption = 'Estado: desconectado'
    end
  end
  object gbSQL: TGroupBox
    Left = 0
    Top = 251
    Width = 684
    Height = 110
    Align = alTop
    Caption = ' SQL a lanzar '
    TabOrder = 3
    object memoSQL: TMemo
      AlignWithMargins = True
      Left = 8
      Top = 23
      Width = 668
      Height = 79
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Align = alClient
      Lines.Strings = (
        'SELECT @@VERSION')
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object gbLog: TGroupBox
    Left = 0
    Top = 361
    Width = 684
    Height = 200
    Align = alClient
    Caption = ' Registro / cron'#243'metro '
    TabOrder = 4
    object memoLog: TMemo
      AlignWithMargins = True
      Left = 8
      Top = 23
      Width = 668
      Height = 169
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Align = alClient
      Color = clWhite
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
end
