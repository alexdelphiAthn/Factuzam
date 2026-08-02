inherited frmMtoErroresEnvios: TfrmMtoErroresEnvios
  Caption = 'Envío de errores'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Appending = False
            OptionsData.Deleting = False
            OptionsData.Editing = False
            OptionsData.Inserting = False
            object colId: TcxGridDBColumn
              Caption = 'Id'
              DataBinding.FieldName = 'ID_ERENV'
              Width = 65
            end
            object colReferencia: TcxGridDBColumn
              Caption = 'Referencia'
              DataBinding.FieldName = 'REFERENCIA_ERENV'
              Width = 210
            end
            object colUsuario: TcxGridDBColumn
              Caption = 'Usuario'
              DataBinding.FieldName = 'USUARIO_ALTA'
              Width = 120
            end
            object colInstanteError: TcxGridDBColumn
              Caption = 'Fecha y hora'
              DataBinding.FieldName = 'INSTANTE_ERROR_ERENV'
              Width = 155
            end
            object colEstado: TcxGridDBColumn
              Caption = 'Estado'
              DataBinding.FieldName = 'ESTADO_ERENV'
              Width = 130
            end
            object colCodigoHttp: TcxGridDBColumn
              Caption = 'HTTP'
              DataBinding.FieldName = 'CODIGO_HTTP_ERENV'
              Width = 65
            end
            object colClaseError: TcxGridDBColumn
              Caption = 'Clase'
              DataBinding.FieldName = 'CLASE_ERROR_ERENV'
              Width = 130
            end
            object colMensajeError: TcxGridDBColumn
              Caption = 'Error'
              DataBinding.FieldName = 'MENSAJE_ERROR_ERENV'
              Width = 330
            end
            object colComentarioTecnico: TcxGridDBColumn
              Caption = 'Comentario técnico'
              DataBinding.FieldName = 'COMENTARIO_TECNICO_ERENV'
              Width = 340
            end
            object colInstanteConsulta: TcxGridDBColumn
              Caption = 'Última consulta'
              DataBinding.FieldName = 'INSTANTE_CONSULTA_ERENV'
              Width = 155
            end
            object colEstadoScript: TcxGridDBColumn
              Caption = 'Script'
              DataBinding.FieldName = 'ESTADO_SCRIPT_ERENV'
              Width = 105
            end
            object colEstadoEjecutable: TcxGridDBColumn
              Caption = 'Actualización'
              DataBinding.FieldName = 'ESTADO_EJECUTABLE_ERENV'
              Width = 115
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
    end
  end
  inherited pButtonRightBar: TPanel
    object btnActualizarEstado: TcxButton
      Left = 1
      Top = 120
      Width = 138
      Height = 34
      Caption = 'Actualizar estado'
      TabOrder = 2
      OnClick = btnActualizarEstadoClick
    end
    object btnEnviarComentario: TcxButton
      Left = 1
      Top = 158
      Width = 138
      Height = 34
      Caption = 'Enviar comentario'
      TabOrder = 3
      OnClick = btnEnviarComentarioClick
    end
    object btnAbrirSeguimiento: TcxButton
      Left = 1
      Top = 196
      Width = 138
      Height = 34
      Caption = 'Abrir seguimiento'
      TabOrder = 4
      OnClick = btnAbrirSeguimientoClick
    end
    object btnEjecutarScript: TcxButton
      Left = 1
      Top = 234
      Width = 138
      Height = 34
      Caption = 'Ejecutar script'
      TabOrder = 5
      OnClick = btnEjecutarScriptClick
    end
    object btnInstalarActualizacion: TcxButton
      Left = 1
      Top = 272
      Width = 138
      Height = 42
      Caption = 'Instalar actualización'
      TabOrder = 6
      WordWrap = True
      OnClick = btnInstalarActualizacionClick
    end
  end
end
