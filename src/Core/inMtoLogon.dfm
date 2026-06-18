object frmLogon: TfrmLogon
  Left = 0
  Top = 0
  BorderIcons = []
  BorderStyle = bsSingle
  Caption = 'Login FactuZam'
  ClientHeight = 430
  ClientWidth = 704
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Lucida Sans'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  TextHeight = 21
  object pnlMain: TPanel
    Left = 0
    Top = 0
    Width = 704
    Height = 430
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 706
    object pnlLogin: TPanel
      Left = 14
      Top = 24
      Width = 329
      Height = 156
      TabOrder = 0
      object lblUsuario: TcxLabel
        Left = 7
        Top = 0
        AutoSize = False
        Caption = 'Usuario'
        TabOrder = 4
        Height = 21
        Width = 312
        Transparent = True
      end
      object lblContrasena: TcxLabel
        Left = 7
        Top = 55
        AutoSize = False
        Caption = 'Contrase'#241'a'
        TabOrder = 5
        Height = 21
        Width = 335
        Transparent = True
      end
      object edtUser: TcxTextEdit
        Left = 7
        Top = 24
        TabOrder = 0
        Width = 312
      end
      object edtPass: TcxTextEdit
        Left = 7
        Top = 79
        Properties.EchoMode = eemPassword
        Properties.PasswordChar = '*'
        TabOrder = 1
        Width = 312
      end
      object chkRememberUser: TcxCheckBox
        Left = 0
        Top = 114
        Caption = 'Recordar Usuario'
        TabOrder = 2
      end
      object chkRememberPassword: TcxCheckBox
        Left = 156
        Top = 114
        Caption = 'Recordar Contrase'#241'a'
        TabOrder = 3
      end
    end
    object pnlButtons: TPanel
      Left = 14
      Top = 258
      Width = 329
      Height = 58
      TabOrder = 1
      object btnAceptar: TButton
        Left = 182
        Top = 11
        Width = 142
        Height = 30
        Caption = '&Aceptar (F12)'
        TabOrder = 0
        OnClick = btnAceptarClick
      end
      object btnSalir: TButton
        Left = 3
        Top = 11
        Width = 141
        Height = 30
        Caption = '&Salir (Esc)'
        TabOrder = 1
        OnClick = btnSalirClick
      end
    end
    object chkAuto: TcxCheckBox
      Left = 15
      Top = 186
      Caption = 'Arranque sin login'
      TabOrder = 2
    end
    object btnConf: TcxButton
      Left = 120
      Top = 218
      Width = 223
      Height = 31
      Caption = 'Configurar &Base de Datos ->'
      TabOrder = 3
      OnClick = btnConfClick
    end
  end
  object pnlBBDD: TPanel
    Left = 360
    Top = 0
    Width = 360
    Height = 360
    TabOrder = 1
    Visible = False
    object lblBBDDConfig: TcxLabel
      Left = 1
      Top = 1
      Align = alTop
      AutoSize = False
      Caption = 'Configuraci'#243'n BBDD'
      TabOrder = 10
      Height = 24
      Width = 358
      Transparent = True
    end
    object lblHostBBDD: TcxLabel
      Left = 24
      Top = 30
      AutoSize = False
      Caption = 'Host:'
      TabOrder = 11
      Height = 21
      Width = 312
      Transparent = True
    end
    object lblPortHost: TcxLabel
      Left = 264
      Top = 30
      AutoSize = False
      Caption = 'Puerto:'
      TabOrder = 12
      Height = 21
      Width = 72
      Transparent = True
    end
    object lblNomBBDD: TcxLabel
      Left = 24
      Top = 85
      AutoSize = False
      Caption = 'Nombre BD:'
      TabOrder = 13
      Height = 21
      Width = 312
      Transparent = True
    end
    object lblUserBBDD: TcxLabel
      Left = 24
      Top = 140
      AutoSize = False
      Caption = 'Usuario:'
      TabOrder = 14
      Height = 21
      Width = 312
      Transparent = True
    end
    object edtHostName: TcxTextEdit
      Left = 24
      Top = 54
      TabOrder = 0
      Width = 234
    end
    object edtPortBD: TcxTextEdit
      Left = 264
      Top = 54
      TabOrder = 1
      Width = 72
    end
    object edtNomBD: TcxTextEdit
      Left = 24
      Top = 109
      TabOrder = 2
      Width = 312
    end
    object edtUserBD: TcxTextEdit
      Left = 24
      Top = 164
      TabOrder = 3
      Width = 312
    end
    object edtPassBD: TcxTextEdit
      Left = 24
      Top = 219
      Properties.EchoMode = eemPassword
      Properties.PasswordChar = '*'
      TabOrder = 4
      Width = 278
    end
    object btnChangePassRoot: TcxButton
      Left = 306
      Top = 219
      Width = 30
      Height = 30
      Caption = '...'
      TabOrder = 5
      OnClick = btnChangePassRootClick
    end
    object btnTest: TcxButton
      Left = 24
      Top = 258
      Width = 144
      Height = 30
      Caption = 'Proba&r Conexi'#243'n'
      TabOrder = 6
      OnClick = btnTestClick
    end
    object btnSubirScript: TcxButton
      Left = 174
      Top = 258
      Width = 162
      Height = 30
      Caption = '&Subir script'
      TabOrder = 7
      OnClick = btnSubirScriptClick
    end
    object btnCopiaSeguridad: TcxButton
      Left = 24
      Top = 294
      Width = 144
      Height = 30
      Caption = '&Copia seguridad'
      TabOrder = 8
      OnClick = btnCopiaSeguridadClick
    end
    object btnRecover: TcxButton
      Left = 174
      Top = 294
      Width = 162
      Height = 30
      Caption = '&Restaurar Copia'
      TabOrder = 9
      OnClick = btnRecoverClick
    end
  end
  object MySQLUniProvider1: TMySQLUniProvider
    Left = 40
    Top = 312
  end
  object ucConexion: TUniConnection
    ProviderName = 'MySQL'
    Port = 3307
    Database = 'factuzam'
    SpecificOptions.Strings = (
      'MySQL.UseUnicode=True')
    Username = 'root'
    Server = '127.0.0.1'
    LoginPrompt = False
    Left = 72
    Top = 312
  end
  object tbUsers: TUniTable
    TableName = 'fza_usuarios'
    Connection = ucConexion
    Left = 136
    Top = 312
  end
  object UniSQLMonitor1: TUniSQLMonitor
    Left = 168
    Top = 312
  end
  object JvEnterAsTab1: TJvEnterAsTab
    Left = 274
    Top = 313
  end
  object saveDialog: TFileSaveDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 160
    Top = 376
  end
  object openDialog: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 240
    Top = 368
  end
end
