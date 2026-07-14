object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'CertApiWeb - Generador de credenciales API'
  ClientHeight = 640
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object lblTitulo: TLabel
    Left = 24
    Top = 20
    Width = 393
    Height = 25
    Caption = 'Generador autorizado de credenciales API'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblAviso: TLabel
    Left = 24
    Top = 52
    Width = 679
    Height = 34
    AutoSize = False
    Caption =
      'La clave privada está protegida por el usuario de Windows. La clave ' +
      'pública debe registrarse una sola vez en config.php.'
    WordWrap = True
  end
  object lblIdClave: TLabel
    Left = 24
    Top = 101
    Width = 127
    Height = 17
    Caption = 'Identificador de clave'
  end
  object lblClavePublica: TLabel
    Left = 232
    Top = 101
    Width = 75
    Height = 17
    Caption = 'Clave pública'
  end
  object lblUrl: TLabel
    Left = 24
    Top = 205
    Width = 104
    Height = 17
    Caption = 'URL del servicio'
  end
  object lblReferencia: TLabel
    Left = 24
    Top = 269
    Width = 124
    Height = 17
    Caption = 'Nombre de referencia'
  end
  object lblAmbitos: TLabel
    Left = 24
    Top = 333
    Width = 167
    Height = 17
    Caption = 'Ámbitos, uno por línea'
  end
  object lblResultado: TLabel
    Left = 384
    Top = 333
    Width = 59
    Height = 17
    Caption = 'Resultado'
  end
  object edtIdClave: TEdit
    Left = 24
    Top = 124
    Width = 192
    Height = 25
    ReadOnly = True
    TabOrder = 0
  end
  object mClavePublica: TMemo
    Left = 232
    Top = 124
    Width = 386
    Height = 57
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
  end
  object btnCopiarClavePublica: TButton
    Left = 632
    Top = 124
    Width = 104
    Height = 33
    Caption = 'Copiar pública'
    TabOrder = 2
    OnClick = btnCopiarClavePublicaClick
  end
  object edtUrl: TEdit
    Left = 24
    Top = 228
    Width = 712
    Height = 25
    TabOrder = 3
  end
  object edtReferencia: TEdit
    Left = 24
    Top = 292
    Width = 712
    Height = 25
    MaxLength = 100
    TabOrder = 4
  end
  object mAmbitos: TMemo
    Left = 24
    Top = 356
    Width = 336
    Height = 181
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object mResultado: TMemo
    Left = 384
    Top = 356
    Width = 352
    Height = 181
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object btnCrearApi: TButton
    Left = 24
    Top = 568
    Width = 168
    Height = 41
    Caption = 'Crear credencial API'
    Default = True
    TabOrder = 7
    OnClick = btnCrearApiClick
  end
  object btnCopiarToken: TButton
    Left = 568
    Top = 568
    Width = 168
    Height = 41
    Caption = 'Copiar último token'
    Enabled = False
    TabOrder = 8
    OnClick = btnCopiarTokenClick
  end
end
