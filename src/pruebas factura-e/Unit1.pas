unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.StdCtrls, Vcl.ExtCtrls, DBAccess, MemDS,
  XML.XMLDoc, XML.XMLIntf, UFactura, Uni, UniProvider, MySQLUniProvider;

type
  TFormMain = class(TForm)
    MySQLUniProvider1: TMySQLUniProvider;
    UniConnection1: TUniConnection;
    UniQuery1: TUniQuery;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    UniQuery2: TUniQuery;
    DBGrid2: TDBGrid;
    MemoXML: TMemo;
    ButtonGenerate: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

end.
