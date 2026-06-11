inherited dmRemesasCompra: TdmRemesasCompra
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_remesas_compra'
      'ORDER BY FECHA_REMC DESC, SERIE_REMC, NUMERO_REMC')
    Left = 24
  end
end
