inherited frmSelectorAtributoPaleta: TfrmSelectorAtributoPaleta
  BorderStyle = bsNone
  Caption = ''
  ClientHeight = 100
  ClientWidth = 120
  Position = poDesigned
  OnDeactivate = FormDeactivateSelector
  OnKeyDown = FormKeyDownSelector
  OnShow = FormShowSelector
  TextHeight = 17
  object lstValores: TListBox
    Left = 0
    Top = 0
    Width = 120
    Height = 100
    Align = alClient
    BorderStyle = bsSingle
    ItemHeight = 22
    Style = lbOwnerDrawFixed
    TabOrder = 0
    OnDrawItem = lstValoresDrawItem
    OnKeyDown = lstValoresKeyDown
    OnMouseDown = lstValoresMouseDown
  end
end
