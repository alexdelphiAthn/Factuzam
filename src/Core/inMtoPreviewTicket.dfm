inherited frmMtoPreviewTicket: TfrmMtoPreviewTicket
  BorderIcons = []
  Caption = 'Previsualizaci'#243'n Excel'
  ClientHeight = 581
  ClientWidth = 528
  StyleElements = [seFont, seClient]
  OnShow = FormShow
  ExplicitLeft = 3
  ExplicitTop = 3
  ExplicitWidth = 546
  ExplicitHeight = 628
  TextHeight = 19
  object Panel1: TPanel [0]
    Left = 0
    Top = 0
    Width = 528
    Height = 41
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 970
    object btnGuardar: TcxButton
      Left = 6
      Top = 3
      Width = 193
      Height = 34
      Caption = 'Guardar Excel'
      TabOrder = 0
      OnClick = btnGuardarClick
    end
    object btnCerrar: TcxButton
      Left = 238
      Top = 3
      Width = 193
      Height = 34
      Caption = 'Cerrar (ESC)'
      TabOrder = 1
      OnClick = btnCerrarClick
    end
  end
  inherited Localizer1: TcxLocalizer
    Active = False
  end
  object DialogoGuardar: TdxSaveFileDialog
    DefaultExt = 'xlsx'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Guardar Excel'
    Left = 72
    Top = 56
  end
  object ActionList1: TActionList
    Left = 480
    Top = 288
    object actSalir: TAction
      Caption = 'Salir'
      ShortCut = 27
      OnExecute = actSalirExecute
    end
  end
end
