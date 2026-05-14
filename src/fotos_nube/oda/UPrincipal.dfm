object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Gestor de Fotos'
  ClientHeight = 640
  ClientWidth = 880
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  TextHeight = 15
  object pcMain: TPageControl
    Left = 0
    Top = 0
    Width = 880
    Height = 640
    ActivePage = tsSubir
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 878
    ExplicitHeight = 632
    object tsSubir: TTabSheet
      Caption = 'Subir foto'
      object edUrl: TLabeledEdit
        Left = 16
        Top = 32
        Width = 840
        Height = 23
        EditLabel.Width = 21
        EditLabel.Height = 15
        EditLabel.Caption = 'URL'
        TabOrder = 0
        Text = 'https://localhost/upload_foto.php'
      end
      object edKey: TLabeledEdit
        Left = 16
        Top = 80
        Width = 840
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'API Key'
        TabOrder = 1
        Text = 'k7Hq9mZ2pXvR4nL8'
      end
      object edCarpetaCliente: TLabeledEdit
        Left = 16
        Top = 128
        Width = 414
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 2
        Text = 'cliente_demo'
      end
      object edNombre: TLabeledEdit
        Left = 444
        Top = 128
        Width = 412
        Height = 23
        EditLabel.Width = 44
        EditLabel.Height = 15
        EditLabel.Caption = 'Nombre'
        TabOrder = 3
        Text = 'producto_001'
      end
      object edArchivo: TLabeledEdit
        Left = 16
        Top = 176
        Width = 752
        Height = 23
        EditLabel.Width = 41
        EditLabel.Height = 15
        EditLabel.Caption = 'Archivo'
        TabOrder = 4
        Text = ''
      end
      object btnSel: TButton
        Left = 778
        Top = 176
        Width = 78
        Height = 23
        Caption = 'Examinar...'
        TabOrder = 5
        OnClick = btnSelClick
      end
      object btnSubir: TButton
        Left = 16
        Top = 216
        Width = 840
        Height = 32
        Caption = 'Subir foto'
        TabOrder = 6
        OnClick = btnSubirClick
      end
      object mLogs: TMemo
        Left = 16
        Top = 264
        Width = 840
        Height = 329
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 7
        WordWrap = False
      end
    end
    object tsVer: TTabSheet
      Caption = 'Ver foto'
      ImageIndex = 1
      object lblResolucion: TLabel
        Left = 384
        Top = 128
        Width = 58
        Height = 15
        Caption = 'Resoluci'#243'n'
      end
      object imgFoto: TImage
        Left = 16
        Top = 184
        Width = 560
        Height = 409
        Center = True
        Proportional = True
        Stretch = True
      end
      object edUrlVer: TLabeledEdit
        Left = 16
        Top = 32
        Width = 840
        Height = 23
        EditLabel.Width = 21
        EditLabel.Height = 15
        EditLabel.Caption = 'URL'
        TabOrder = 0
        Text = 'https://localhost/ver_foto.php'
      end
      object edKeyVer: TLabeledEdit
        Left = 16
        Top = 80
        Width = 840
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'API Key'
        TabOrder = 1
        Text = 'k7Hq9mZ2pXvR4nL8'
      end
      object edCarpetaClienteVer: TLabeledEdit
        Left = 16
        Top = 144
        Width = 184
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 2
        Text = 'cliente_demo'
      end
      object edNombreVer: TLabeledEdit
        Left = 216
        Top = 144
        Width = 152
        Height = 23
        EditLabel.Width = 44
        EditLabel.Height = 15
        EditLabel.Caption = 'Nombre'
        TabOrder = 3
        Text = 'producto_001'
      end
      object cbResolucion: TComboBox
        Left = 384
        Top = 144
        Width = 121
        Height = 23
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 4
        Text = '150'
        Items.Strings = (
          '150'
          '300'
          'real')
      end
      object btnVer: TButton
        Left = 528
        Top = 144
        Width = 328
        Height = 24
        Caption = 'Ver foto'
        TabOrder = 5
        OnClick = btnVerClick
      end
      object mLogsVer: TMemo
        Left = 592
        Top = 184
        Width = 264
        Height = 409
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 6
        WordWrap = False
      end
    end
    object tsBatch: TTabSheet
      Caption = 'Subida masiva'
      ImageIndex = 2
      object lblConcurrencia: TLabel
        Left = 600
        Top = 248
        Width = 110
        Height = 15
        Caption = 'Concurrencia (hilos):'
      end
      object lblBatchStatus: TLabel
        Left = 16
        Top = 320
        Width = 64
        Height = 15
        Caption = 'Esperando...'
      end
      object edUrlBatch: TLabeledEdit
        Left = 16
        Top = 32
        Width = 416
        Height = 23
        EditLabel.Width = 88
        EditLabel.Height = 15
        EditLabel.Caption = 'URL upload_foto'
        TabOrder = 0
        Text = 'https://localhost/upload_foto.php'
      end
      object edUrlListBatch: TLabeledEdit
        Left = 448
        Top = 32
        Width = 408
        Height = 23
        EditLabel.Width = 81
        EditLabel.Height = 15
        EditLabel.Caption = 'URL listar_fotos'
        TabOrder = 1
        Text = 'https://localhost/listar_fotos.php'
      end
      object edKeyBatch: TLabeledEdit
        Left = 16
        Top = 80
        Width = 416
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'API Key'
        TabOrder = 2
        Text = 'k7Hq9mZ2pXvR4nL8'
      end
      object edCarpetaClienteBatch: TLabeledEdit
        Left = 448
        Top = 80
        Width = 200
        Height = 23
        EditLabel.Width = 79
        EditLabel.Height = 15
        EditLabel.Caption = 'Carpeta cliente'
        TabOrder = 3
        Text = 'cliente_demo'
      end
      object edPrefijoLocal: TLabeledEdit
        Left = 664
        Top = 80
        Width = 192
        Height = 23
        EditLabel.Width = 108
        EditLabel.Height = 15
        EditLabel.Caption = 'Prefijo local de fotos'
        TabOrder = 4
        Text = 'C:\FOTOS\'
      end
      object edSqlServer: TLabeledEdit
        Left = 16
        Top = 144
        Width = 280
        Height = 23
        EditLabel.Width = 114
        EditLabel.Height = 15
        EditLabel.Caption = 'SQL Server (host\inst)'
        TabOrder = 5
        Text = '.\SQLEXPRESS'
      end
      object edSqlDatabase: TLabeledEdit
        Left = 312
        Top = 144
        Width = 200
        Height = 23
        EditLabel.Width = 48
        EditLabel.Height = 15
        EditLabel.Caption = 'Database'
        TabOrder = 6
        Text = 'Factuzam'
      end
      object edSqlUser: TLabeledEdit
        Left = 528
        Top = 144
        Width = 152
        Height = 23
        EditLabel.Width = 40
        EditLabel.Height = 15
        EditLabel.Caption = 'Usuario'
        TabOrder = 7
        Text = 'sa'
      end
      object edSqlPassword: TLabeledEdit
        Left = 696
        Top = 144
        Width = 160
        Height = 23
        EditLabel.Width = 60
        EditLabel.Height = 15
        EditLabel.Caption = 'Contrase'#241'a'
        PasswordChar = '*'
        TabOrder = 8
        Text = ''
      end
      object chkSqlWindowsAuth: TCheckBox
        Left = 16
        Top = 184
        Width = 240
        Height = 17
        Caption = 'Usar autenticaci'#243'n Windows'
        TabOrder = 9
      end
      object cbConcurrencia: TComboBox
        Left = 736
        Top = 244
        Width = 120
        Height = 23
        Style = csDropDownList
        TabOrder = 10
      end
      object btnLanzar: TButton
        Left = 16
        Top = 240
        Width = 280
        Height = 32
        Caption = 'Lanzar subida masiva'
        TabOrder = 11
        OnClick = btnLanzarClick
      end
      object btnCancelar: TButton
        Left = 312
        Top = 240
        Width = 152
        Height = 32
        Caption = 'Cancelar'
        TabOrder = 12
        OnClick = btnCancelarClick
      end
      object pbBatch: TProgressBar
        Left = 16
        Top = 288
        Width = 840
        Height = 24
        TabOrder = 13
      end
      object mLogsBatch: TMemo
        Left = 16
        Top = 344
        Width = 840
        Height = 249
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Consolas'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 14
        WordWrap = False
      end
    end
  end
end
