object dmConn: TdmConn
  OnCreate = DataModuleCreate
  Height = 239
  Width = 405
  object conUni: TUniConnection
    ProviderName = 'MySQL'
    Port = 3306
    Database = 'factuzam'
    SpecificOptions.Strings = (
      'MySQL.UseUnicode=True')
    Options.DefaultSortType = stCaseInsensitive
    DefaultTransaction.DefaultCloseAction = taCommit
    PoolingOptions.Validate = True
    Username = 'root'
    Server = '127.0.0.1'
    LoginPrompt = False
    BeforeConnect = connBeforeConnect
    Left = 216
    Top = 120
    EncryptedPassword = 'A5FF9EFF92FF90FF8DFF9EFFCDFFCFFFCDFFCCFF'
  end
  object mysqlnprvdr1: TMySQLUniProvider
    Left = 152
    Top = 120
  end
  object UniSQLMonitor1: TUniSQLMonitor
    Active = False
    Options = [moDialog, moSQLMonitor, moDBMonitor, moCustom, moHandled]
    DBMonitorOptions.Host = '0'
    DBMonitorOptions.Port = 0
    DBMonitorOptions.ReconnectTimeout = 0
    DBMonitorOptions.SendTimeout = 0
    TraceFlags = [tfQPrepare, tfQExecute, tfQFetch, tfError, tfStmt, tfConnect, tfTransact, tfBlob, tfService, tfMisc, tfParams, tfObjDestroy, tfPool]
    OnSQL = UniSQLMonitor1SQL
    Left = 296
    Top = 119
  end
end
