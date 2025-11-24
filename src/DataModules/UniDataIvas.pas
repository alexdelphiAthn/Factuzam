{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataIvas;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
   inLibUser, UniDataConn, vcl.dialogs;

type
  TdmIvas = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    unqryZonasIVA: TUniQuery;
    dsZonas: TDataSource;
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
  private
    function ExisteGrupoZonaIVA(sCodigoGrupo:String):Boolean;
    { Private declarations }
  public
    procedure GetCodigoAutoIva;
  end;

//var
//  dmIvas: TdmIvas;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses inLibtb, inLibGlobalVar;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmIvas.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FindField('CODIGO_IVA').AsString := '0';
    FindField('GRUPO_ZONA_IVA').AsString := '0';
    FindField('PORCENEXENTO_IVA').AsString := '0';
    FindField('PORCENEXENTO_RE_IVA').AsString := '0';
    FindField('PORCENNORMAL_IVA').AsString := '0';
    FindField('PORCENNORMAL_RE_IVA').AsString := '0';
    FindField('PORCENREDUCIDO_IVA').AsString := '0';
    FindField('PORCENREDUCIDO_RE_IVA').AsString := '0';
    FindField('PORCENSUPERREDUCIDO_IVA').AsString := '0';
    FindField('PORCENSUPERREDUCIDO_RE_IVA').AsString := '0';
    FindField('FECHA_DESDE_IVA').AsDateTime := Now;
  end;
end;

procedure TdmIvas.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sCodigo :String;
  bError  : Boolean;
  unqrySol: TUniQuery;
begin
  inherited;
  bError := False;
  with unqryTablaG do
  begin
    sCodigo := Trim(FindField('CODIGO_IVA').AsString);
    if ((sCodigo = '') or
        (SimbolosProhibidos(sCodigo))) then
    begin
      ShowMessageFmt('%s no es un valor de registro válido ' +
                                                  'para el campo Código de IVA',
                                                                     [sCodigo]);
      bError := True;
    end;
    if ((FindField('GRUPO_ZONA_IVA').AsString = '0') or
        (not ExisteGrupoZonaIVA(FindField('GRUPO_ZONA_IVA').AsString))) then
    begin
      ShowMessageFmt('%s no es un valor válido o no existe para grupo de IVAS',
                                        [FindField('GRUPO_ZONA_IVA').AsString]);
      bError := True;
    end;
    if (not(bError)) then
    begin
      with unqryTablaG do
      begin
        if (not(bError)) then
        begin
          unqrySol := TUniQuery.Create(nil);
          unqrySol.Connection := oConn;
          unqrySol.SQL.Text := 'SELECT * ' +
                               '  FROM vi_ivas ' +
                               ' WHERE GRUPO_ZONA_IVA = :GRUPO_ZONA_IVA';
          unqrySol.ParamByName('GRUPO_ZONA_IVA').AsString :=
                                           FindField('GRUPO_ZONA_IVA').AsString;
          unqrySol.Open;
        end;
        if ((not(bError)) and
             not(ExistePeriodoUnico(unqrySol,
                                    FindField('FECHA_DESDE_IVA'),
                                    FindField('FECHA_HASTA_IVA')))) then
        begin
          raise ERangeError.CreateFmt('Error de Rango en las fechas. ' +
                                 'Error en la fecha.' + 'O se han establecido'+
                                 ' dos periodos activos en el mismo periodo' +
                                 ' para la zona %s',
                                  [FindField('DESCRIPCION_ZONA_IVA').AsString]);
          bError := True;
        end;
      end;
      if (assigned(unqrySol)) then
      begin
        unqrySol.Close;
        FreeAndNil(unqrySol);
      end;
    end;
  end;
  if bError then
    Abort
  else
    GetCodigoAutoIva;
end;

procedure TdmIvas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;;
  unqryZonasIVA.Connection := oConn;
  unqryZonasIVA.Open;
end;

function TdmIvas.ExisteGrupoZonaIVA(sCodigoGrupo: String): Boolean;
var
  unqrySol: TUniQuery;
begin
  unqrySol := TUniQuery.Create(nil);
  unqrySol.Connection := oConn;
  unqrySol.SQL.Text := 'SELECT * ' +
                       '  FROM fza_ivas_grupos ' +
                       ' WHERE GRUPO_ZONA_IVA = :GRUPO_ZONA_IVA';
  unqrySol.ParamByName('GRUPO_ZONA_IVA').AsString := sCodigoGrupo;
  unqrySol.Open;
  if unqrySol.RecordCount = 0 then
    Result := False
  else
    Result := True;
  FreeAndNil(unqrySol);
end;

procedure TdmIvas.GetCodigoAutoIva;
begin
  if unqryTablaG.FindField('CODIGO_IVA').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'IV';
      ExecProc;
      unqryTablaG.FindField('CODIGO_IVA').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

initialization
  ForceReferenceToClass(TdmIvas);
end.
