unit UniDataGenFilter;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni;

type
  TdmGenFilter = class(TdmBase)
    unqryEmpresas: TUniQuery;
    dsEmpresas: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

//var
//  dmGenFilter: TdmGenFilter;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibGlobalVar;

{$R *.dfm}

procedure TdmGenFilter.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryEmpresas.Connection := oConn;

  unqryEmpresas.Open;
end;

end.
