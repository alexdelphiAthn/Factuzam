{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataConn;

interface

uses
  SysUtils, Classes, DB, ADODB, DBAccess, Uni, inLibUser, vcl.Controls,
  UniProvider, MySQLUniProvider, DASQLMonitor, UniSQLMonitor;

type
  TdmConn = class(TDataModule)
    conUni: TUniConnection;
    mysqlnprvdr1: TMySQLUniProvider;
    UniSQLMonitor1: TUniSQLMonitor;
    procedure connBeforeConnect(Sender: TObject);
    procedure UniSQLMonitor1SQL(Sender: TObject; Text: string;
      Flag: TDATraceFlag);
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ActualizarUserTimeModif(DataSet:TDataSet);
  end;

var
  dmConn: TdmConn;

implementation

uses inLibDir,
     inLibtb,
     inLibWin,
     inLibLog,
     inMtoPrincipal2,
     inLibGlobalVar;

{$R *.dfm}

procedure TdmConn.connBeforeConnect(Sender: TObject);
var
  sDatabase,
  sHostName,
  sPasswordEn,
  sPort,
  sUser: string;
begin
  sDatabase := leCadINIDir('ConnData', 'Database','factuzam', GetUserFolder);
  sHostName :=  leCadINIDir('ConnData', 'HostName','127.0.0.1', GetUserFolder);
  //Password por defecto Zamora2023
  sPasswordEn := DecriptAES(leCadINIDir('ConnData',
                            'PasswordEn',
                            '2qJFaDfegP/9y6RDno1FRg==',
                            GetUserFolder));
  sPort :=  leCadINIDir('ConnData', 'Puerto','3310', GetUserFolder);
  sUser :=  leCadINIDir('ConnData', 'User', 'root', GetUserFolder);
  ConstruirConexion(conUni, sUser, sPasswordEn, sHostName, sPort, sDatabase);
end;

procedure TdmConn.DataModuleCreate(Sender: TObject);
begin
  UniSQLMonitor1.Active := False;
  //oMemoSQL.Visible := False;
  {$IFDEF DEBUG}
    UniSQLMonitor1.Active := True;
   // oMemoSQL.Visible := True;
  {$ENDIF }
  //ofrmMto2.pcPrincipal.Align := alClient;
end;

procedure TdmConn.UniSQLMonitor1SQL(Sender: TObject; Text: string;
  Flag: TDATraceFlag);
begin
  {$IFDEF DEBUG}
    oMemoSQL.Lines.Add(Text);
    inLibLog.Log.LogSQL(Text);
  {$ENDIF }
end;

procedure TdmConn.ActualizarUserTimeModif(DataSet:TDataSet);
begin
  if (DataSet.FindField('USUARIOMODIF') <> nil) then
    DataSet.FieldbyName('USUARIOMODIF').AsString:= oUser;
  if DataSet.State = dsInsert then
  begin
    if (DataSet.FindField('INSTANTEALTA') <> nil) then
      DataSet.FieldbyName('INSTANTEALTA').AsDateTime := Now;
    if (DataSet.FindField('USUARIOALTA') <> nil) then
      DataSet.FieldbyName('USUARIOALTA').AsString := oUser;
    if (DataSet.FindField('INSTANTEMODIF') <> nil) then
      DataSet.FieldbyName('INSTANTEMODIF').AsDateTime := Now;
  end;
end;

end.
