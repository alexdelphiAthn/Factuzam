inherited dmEfectosCompra: TdmEfectosCompra
  PixelsPerInch = 120
  inherited unqryTablaG: TUniQuery
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM vi_efectos_compra'
      'ORDER BY FECHA_VENCIMIENTO_EFEC, SERIE_FACC_EFEC, NUMERO_FACC_EFEC, NUMERO_EFEC')
    Left = 24
  end
end
