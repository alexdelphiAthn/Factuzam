inherited dmEmpleados: TdmEmpleados
  Height = 187
  Width = 399
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_empleados'

        '  (CODIGO_EMPL, NOMBRE_EMPL, DIRECCION_EMPL, TELEFONO_EMPL, DIMINU' +
        'TIVO_TICKET_EMPL, ESACTIVO_EMPL, INSTANTE_MODIF, INSTANTE_ALTA, US' +
        'UARIO_ALTA, USUARIO_MODIF)'
      'VALUES'

        '  (:CODIGO_EMPL, :NOMBRE_EMPL, :DIRECCION_EMPL, :TELEFONO_EMPL, :D' +
        'IMINUTIVO_TICKET_EMPL, :ESACTIVO_EMPL, :INSTANTE_MODIF, :INSTANTE_' +
        'ALTA, :USUARIO_ALTA, :USUARIO_MODIF)')
    SQLDelete.Strings = (
      'DELETE FROM fza_empleados'
      'WHERE'
      '  CODIGO_EMPL = :Old_CODIGO_EMPL')
    SQLUpdate.Strings = (
      'UPDATE fza_empleados'
      'SET'

        '  CODIGO_EMPL = :CODIGO_EMPL, NOMBRE_EMPL = :NOMBRE_EMPL, DIRECCIO' +
        'N_EMPL = :DIRECCION_EMPL, TELEFONO_EMPL = :TELEFONO_EMPL, DIMINUTI' +
        'VO_TICKET_EMPL = :DIMINUTIVO_TICKET_EMPL, ESACTIVO_EMPL = :ESACTIV' +
        'O_EMPL, INSTANTE_MODIF = :INSTANTE_MODIF, INSTANTE_ALTA = :INSTANT' +
        'E_ALTA, USUARIO_ALTA = :USUARIO_ALTA, USUARIO_MODIF = :USUARIO_MOD' +
        'IF'
      'WHERE'
      '  CODIGO_EMPL = :Old_CODIGO_EMPL')
    SQLLock.Strings = (

        'SELECT CODIGO_EMPL, NOMBRE_EMPL, DIRECCION_EMPL, TELEFONO_EMPL, DI' +
        'MINUTIVO_TICKET_EMPL, ESACTIVO_EMPL, INSTANTE_MODIF, INSTANTE_ALTA' +
        ', USUARIO_ALTA, USUARIO_MODIF FROM fza_empleados'
      'WHERE'
      '  CODIGO_EMPL = :Old_CODIGO_EMPL'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      'SELECT * FROM vi_empleados'
      'WHERE'
      '  CODIGO_EMPL = :CODIGO_EMPL')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_empleados')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_empleados'
      '')
    AfterInsert = unqryTablaGAfterInsert
    Left = 24
  end
end
