inherited frmMtoEmpleados: TfrmMtoEmpleados
  Caption = 'Empleados'
  TextHeight = 19
  inherited pButtonPage: TPanel
    inherited pcPantalla: TcxPageControl
      Properties.ActivePage = tsLista
      inherited tsLista: TcxTabSheet
        inherited cxGrdPrincipal: TcxGrid
          inherited cxGrdDBTabPrin: TcxGridDBTableView
            OptionsData.Editing = True
            object cxGrdDBTabPrinCODIGO_EMPL: TcxGridDBColumn
              Caption = 'C'#243'digo Empleado'
              DataBinding.FieldName = 'CODIGO_EMPL'
              Width = 130
            end
            object cxGrdDBTabPrinNOMBRE_EMPL: TcxGridDBColumn
              Caption = 'Nombre'
              DataBinding.FieldName = 'NOMBRE_EMPL'
              Width = 230
            end
            object cxGrdDBTabPrinDIRECCION_EMPL: TcxGridDBColumn
              Caption = 'Direcci'#243'n'
              DataBinding.FieldName = 'DIRECCION_EMPL'
              Width = 260
            end
            object cxGrdDBTabPrinTELEFONO_EMPL: TcxGridDBColumn
              Caption = 'Tel'#233'fono'
              DataBinding.FieldName = 'TELEFONO_EMPL'
              Width = 120
            end
            object cxGrdDBTabPrinDIMINUTIVO_TICKET_EMPL: TcxGridDBColumn
              Caption = 'Diminutivo Caja'
              DataBinding.FieldName = 'DIMINUTIVO_TICKET_EMPL'
              Width = 130
            end
            object cxGrdDBTabPrinESACTIVO_EMPL: TcxGridDBColumn
              Caption = 'Activo'
              DataBinding.FieldName = 'ESACTIVO_EMPL'
              PropertiesClassName = 'TcxCheckBoxProperties'
              Properties.ValueChecked = 'S'
              Properties.ValueUnchecked = 'N'
              Width = 70
            end
          end
        end
      end
      inherited tsFicha: TcxTabSheet
        TabVisible = False
      end
    end
  end
  inherited dsTablaG: TDataSource
    DataSet = dmEmpleados.unqryTablaG
  end
end
