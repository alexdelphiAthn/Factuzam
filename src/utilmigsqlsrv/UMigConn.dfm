object dmMig: TdmMig
  Height = 240
  Width = 420
  object conSrv: TUniConnection
    ProviderName = 'SQL Server'
    Port = 1433
    SpecificOptions.Strings = (
      'SQL Server.Authentication=auWindows'
      'SQL Server.Provider=prDirect')
    LoginPrompt = False
    Left = 80
    Top = 40
  end
  object conDst: TUniConnection
    ProviderName = 'MySQL'
    Port = 3306
    SpecificOptions.Strings = (
      'MySQL.UseUnicode=True'
      'MySQL.Charset=utf8mb4')
    LoginPrompt = False
    Left = 80
    Top = 120
  end
  object prvSqlServer: TSQLServerUniProvider
    Left = 240
    Top = 40
  end
  object prvMySQL: TMySQLUniProvider
    Left = 240
    Top = 120
  end
end
