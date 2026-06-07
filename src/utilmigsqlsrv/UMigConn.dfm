object dmMig: TdmMig
  Height = 300
  Width = 525
  PixelsPerInch = 120
  object conSrv: TUniConnection
    ProviderName = 'SQL Server'
    Port = 1433
    SpecificOptions.Strings = (
      'SQL Server.Provider=prMSOLEDB'
      'SQL Server.Authentication=auWindows')
    LoginPrompt = False
    Left = 100
    Top = 50
  end
  object conDst: TUniConnection
    ProviderName = 'MySQL'
    Port = 3306
    SpecificOptions.Strings = (
      'MySQL.UseUnicode=True')
    LoginPrompt = False
    Left = 100
    Top = 150
  end
  object prvSqlServer: TSQLServerUniProvider
    Left = 300
    Top = 50
  end
  object prvMySQL: TMySQLUniProvider
    Left = 300
    Top = 150
  end
end
