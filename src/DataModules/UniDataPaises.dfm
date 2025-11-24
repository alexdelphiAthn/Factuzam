inherited dmPaises: TdmPaises
  inherited unqryTablaG: TUniQuery
    SQLInsert.Strings = (
      'INSERT INTO fza_paises'
      
        '  (COD_PAIS, COD_PAIS_ALPHA3, NOMBRE_SPA_PAIS, NOMBRE_ENG_PAIS, ' +
        'ORDEN_PAIS)'
      'VALUES'
      
        '  (:COD_PAIS, :COD_PAIS_ALPHA3, :NOMBRE_SPA_PAIS, :NOMBRE_ENG_PA' +
        'IS, :ORDEN_PAIS)')
    SQLDelete.Strings = (
      'DELETE FROM fza_paises'
      'WHERE'
      '  COD_PAIS = :Old_COD_PAIS')
    SQLUpdate.Strings = (
      'UPDATE fza_paises'
      'SET'
      
        '  COD_PAIS = :COD_PAIS, COD_PAIS_ALPHA3 = :COD_PAIS_ALPHA3, NOMB' +
        'RE_SPA_PAIS = :NOMBRE_SPA_PAIS, NOMBRE_ENG_PAIS = :NOMBRE_ENG_PA' +
        'IS, ORDEN_PAIS = :ORDEN_PAIS'
      'WHERE'
      '  COD_PAIS = :Old_COD_PAIS')
    SQLLock.Strings = (
      
        'SELECT COD_PAIS, COD_PAIS_ALPHA3, NOMBRE_SPA_PAIS, NOMBRE_ENG_PA' +
        'IS, ORDEN_PAIS FROM fza_paises'
      'WHERE'
      '  COD_PAIS = :Old_COD_PAIS'
      'FOR UPDATE')
    SQLRefresh.Strings = (
      
        'SELECT COD_PAIS, COD_PAIS_ALPHA3, NOMBRE_SPA_PAIS, NOMBRE_ENG_PA' +
        'IS, ORDEN_PAIS FROM fza_paises'
      'WHERE'
      '  COD_PAIS = :COD_PAIS')
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_paises')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *  '
      'FROM fza_paises'
      '')
    Active = True
    Left = 16
  end
end
