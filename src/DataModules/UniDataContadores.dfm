inherited dmContadores: TdmContadores
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO `fza_contadores`'
      
        '  (`TIPODOC_CONTADOR`, `EMPRESA_CONTADOR`, `SERIE_CONTADOR`, `CO' +
        'NTADOR_CONTADOR`, `NUMDIGIT_CONTADOR`, `ACTIVO_CONTADOR`, `DEFAU' +
        'LT_CONTADOR`, `INSTANTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`, `U' +
        'SUARIOMODIF`)'
      'VALUES'
      
        '  (:`TIPODOC_CONTADOR`, :`EMPRESA_CONTADOR`, :`SERIE_CONTADOR`, ' +
        ':`CONTADOR_CONTADOR`, :`NUMDIGIT_CONTADOR`, :`ACTIVO_CONTADOR`, ' +
        ':`DEFAULT_CONTADOR`, :`INSTANTEMODIF`, :`INSTANTEALTA`, :`USUARI' +
        'OALTA`, :`USUARIOMODIF`)')
    SQLDelete.Strings = (
      'DELETE FROM `fza_contadores`'
      'WHERE'
      
        '  `TIPODOC_CONTADOR` = :`Old_TIPODOC_CONTADOR` AND `EMPRESA_CONT' +
        'ADOR` = :`Old_EMPRESA_CONTADOR` AND `SERIE_CONTADOR` = :`Old_SER' +
        'IE_CONTADOR`')
    SQLUpdate.Strings = (
      'UPDATE `fza_contadores`'
      'SET'
      
        '  `TIPODOC_CONTADOR` = :`TIPODOC_CONTADOR`, `EMPRESA_CONTADOR` =' +
        ' :`EMPRESA_CONTADOR`, `SERIE_CONTADOR` = :`SERIE_CONTADOR`, `CON' +
        'TADOR_CONTADOR` = :`CONTADOR_CONTADOR`, `NUMDIGIT_CONTADOR` = :`' +
        'NUMDIGIT_CONTADOR`, `ACTIVO_CONTADOR` = :`ACTIVO_CONTADOR`, `DEF' +
        'AULT_CONTADOR` = :`DEFAULT_CONTADOR`, `INSTANTEMODIF` = :`INSTAN' +
        'TEMODIF`, `INSTANTEALTA` = :`INSTANTEALTA`, `USUARIOALTA` = :`US' +
        'UARIOALTA`, `USUARIOMODIF` = :`USUARIOMODIF`'
      'WHERE'
      
        '  `TIPODOC_CONTADOR` = :`Old_TIPODOC_CONTADOR` AND `EMPRESA_CONT' +
        'ADOR` = :`Old_EMPRESA_CONTADOR` AND `SERIE_CONTADOR` = :`Old_SER' +
        'IE_CONTADOR`')
    SQLLock.Strings = (
      
        'SELECT `TIPODOC_CONTADOR`, `EMPRESA_CONTADOR`, `SERIE_CONTADOR`,' +
        ' `CONTADOR_CONTADOR`, `NUMDIGIT_CONTADOR`, `ACTIVO_CONTADOR`, `D' +
        'EFAULT_CONTADOR`, `INSTANTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`' +
        ', `USUARIOMODIF` FROM `fza_contadores`'
      'WHERE'
      
        '  `TIPODOC_CONTADOR` = :`Old_TIPODOC_CONTADOR` AND `EMPRESA_CONT' +
        'ADOR` = :`Old_EMPRESA_CONTADOR` AND `SERIE_CONTADOR` = :`Old_SER' +
        'IE_CONTADOR`'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT `TIPODOC_CONTADOR`, `EMPRESA_CONTADOR`, `SERIE_CONTADOR`,' +
        ' `CONTADOR_CONTADOR`, `NUMDIGIT_CONTADOR`, `ACTIVO_CONTADOR`, `D' +
        'EFAULT_CONTADOR`, `INSTANTEMODIF`, `INSTANTEALTA`, `USUARIOALTA`' +
        ', `USUARIOMODIF` FROM `fza_contadores`'
      'WHERE'
      
        '  `TIPODOC_CONTADOR` = :`TIPODOC_CONTADOR` AND `EMPRESA_CONTADOR' +
        '` = :`EMPRESA_CONTADOR` AND `SERIE_CONTADOR` = :`SERIE_CONTADOR`')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_contadores')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM vi_contadores'
      '')
    Active = True
    Left = 24
  end
end
