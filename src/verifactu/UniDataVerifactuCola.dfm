inherited dmVerifactuCola: TdmVerifactuCola
  inherited unqryTablaG: TUniQuery
    SQLRecCount.Strings = (
      'SELECT COUNT(*) FROM fza_verifactu_cola')
    Connection = dmConn.conUni
    SQL.Strings = (
      'SELECT *'
      'FROM fza_verifactu_cola'
      'ORDER BY ID_VFCOLA DESC'
      '')
    Active = True
    Left = 24
  end
end
