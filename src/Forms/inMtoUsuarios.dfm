inherited frmMtoUsuarios: TfrmMtoUsuarios
  Caption = 'Usuarios'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        ExplicitLeft = 4
        ExplicitTop = 30
        ExplicitWidth = 943
        ExplicitHeight = 484
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinUSUARIO_USUARIO: TcxGridDBColumn
              Caption = 'Nombre de Usuario'
              DataBinding.FieldName = 'USUARIO_USU'
              Width = 189
            end
            object cxGrdDBTabPrinDIMINUTIVO_USUARIO: TcxGridDBColumn
              Caption = 'Diminutivo Caja'
              DataBinding.FieldName = 'DIMINUTIVO_TICKET_USU'
              Width = 140
            end
            object cxGrdDBTabPrinGRUPO_USUARIO: TcxGridDBColumn
              Caption = 'Grupo'
              DataBinding.FieldName = 'GRUPO_USU'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.KeyFieldNames = 'GRUPO_USUGRP'
              Properties.ListColumns = <
                item
                  FieldName = 'GRUPO_USUGRP'
                end>
              Properties.ListOptions.ShowHeader = False
              Properties.ListSource = dmUsuarios.dsGrupos
              Width = 197
            end
            object cxgrdbclmnGrdDBTabPrinESGRUPOADMINISTRADOR_GRUPO: TcxGridDBColumn
              Caption = 'Es Administrador'
              DataBinding.FieldName = 'ESGRUPOADMINISTRADOR_USUGRP'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ReadOnly = True
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 167
            end
            object cxGrdDBTabPrinEMPRESADEF_USUARIO: TcxGridDBColumn
              Caption = 'Empresa por defecto en documentos'
              DataBinding.FieldName = 'EMPRESA_DEFECTO_USU'
              PropertiesClassName = 'TcxLookupComboBoxProperties'
              Properties.KeyFieldNames = 'CODIGO_EMP_EMP'
              Properties.ListColumns = <
                item
                  MinWidth = 60
                  FieldName = 'CODIGO_EMP_EMP'
                end
                item
                  FieldName = 'RAZON_SOCIAL_EMP'
                end>
              Properties.ListOptions.ColumnSorting = False
              Properties.ListSource = dmUsuarios.dsEmpresas
              Width = 334
            end
            object cxgrdbclmnGrdDBTabPrinRAZONSOCIAL_EMPRESA: TcxGridDBColumn
              Caption = 'Raz'#243'n Social Empresa'
              DataBinding.FieldName = 'RAZON_SOCIAL_EMP'
              Width = 218
            end
            object cxGrdDBTabPrinPASSWORD_USUARIO: TcxGridDBColumn
              Caption = 'Password Encriptado'
              DataBinding.FieldName = 'PASSWORD_USU'
              PropertiesClassName = 'TcxTextEditProperties'
              Properties.EchoMode = eemPassword
              Properties.PasswordChar = '*'
              Properties.ReadOnly = True
              Width = 193
            end
            object cxGrdDBTabPrinULTIMOLOGIN_USUARIO: TcxGridDBColumn
              Caption = #218'ltima Conexi'#243'n'
              DataBinding.FieldName = 'ULTIMO_LOGIN_USU'
              PropertiesClassName = 'TcxDateEditProperties'
              Properties.ReadOnly = True
              Width = 190
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
      inherited tsPerfil: TcxTabSheet
        inherited pnlPerfilTop: TPanel
          inherited edtPerfilBusq: TcxTextEdit
            ExplicitHeight = 27
          end
        end
      end
    end
    inherited pnlTopPage: TPanel
      inherited pnlTopGrid: TPanel
        inherited edtBusqGlobal: TcxTextEdit
          ExplicitHeight = 27
        end
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnSetPass: TcxButton
      Left = 4
      Top = 128
      Width = 130
      Height = 57
      Caption = 'Cambiar &Contrase'#241'a'
      TabOrder = 2
      WordWrap = True
      OnClick = btnSetPassClick
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmUsuarios.unqryTablaG
  end
end
