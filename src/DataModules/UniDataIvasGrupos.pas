{*******************************************************}
{                                                       }
{       FactuZam                                        }
{                                                       }
{       Copyright (C) 2023 fzam.6dvdy@slmail.me    }
{                                                       }
{*******************************************************}

unit UniDataIvasGrupos;

interface

uses
  System.SysUtils, System.Classes, UniDataGen, Data.DB, MemDS, DBAccess, Uni,
   inLibUser, UniDataConn, inLibtb;

type
  TdmIvasGrupos = class(TdmBase)
    unstrdprcContador: TUniStoredProc;
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure DataModuleCreate(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
  private
    { Private declarations }
  public
    procedure GetCodigoAutoIvaGrupo;
  end;

//var
//  dmIvasGrupos: TdmIvasGrupos;

implementation

uses
  inLibGlobalVar;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TdmIvasGrupos.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  inherited;
  with unqryTablaG do
  begin
    FindField('GRUPO_ZONA_IVA').AsString := '0';
    FindField('ESIRPF_IMP_INCL_ZONA_IVA').AsString := 'N';
    FindField('ESIVAAGRICOLA_ZONA_IVA').AsString := 'N';
    FindField('ESAPLICA_RE_ZONA_IVA').AsString := 'S';
    FindField('ESDEFAULT_ZONA_IVA').AsString := 'N';
    FindField('PALABRA_REPORTS_ZONA_IVA').AsString := 'IVA';
  end;
end;

procedure TdmIvasGrupos.unqryTablaGBeforePost(DataSet: TDataSet);
var
 sCodigo,
 sDescripcion:String;
 bError : Boolean;
 unqrySol : TUniQuery;
begin
  inherited;
  bError := False;
  with unqryTablaG do
  begin
    sCodigo := Trim(FindField('GRUPO_ZONA_IVA').AsString);
    sDescripcion := Trim(FindField('DESCRIPCION_ZONA_IVA').AsString);
    if ((sDescripcion = '') or (SimbolosProhibidos(sDescripcion))) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                   'para el campo Descripción de Grupos de IVA',
                                                                [sDescripcion]);
      bError := True;
    end;
    if ((sCodigo = '') or
        (SimbolosProhibidos(sCodigo))
       ) then
    begin
      raise ERangeError.CreateFmt('%s no es un valor de registro válido ' +
                                        'para el campo Código de Grupos de IVA',
                                                                     [sCodigo]);
      bError := True;
    end;
    if (bError = False) then
    begin
      if (FindField('ESDEFAULT_ZONA_IVA').AsString = 'S') then
      begin
        unqrySol := TUniQuery.Create(nil);
        unqrySol.Connection := oConn;
        unqrySol.SQL.Text := 'SELECT ESDEFAULT_ZONA_IVA ' +
                             '  FROM vi_ivas_grupos ' +
                             ' WHERE ESDEFAULT_ZONA_IVA = ' + QuotedStr('S');
        if (DataSet.State = dsEdit) then
        begin
          unqrySol.SQL.Text := unqrySol.SQL.Text +
                               ' AND GRUPO_ZONA_IVA <> ' + sCodigo;
        end;
        unqrySol.Open;
        if (unqrySol.RecordCount > 0) then
        begin
          raise EDataBaseError.Create('No es posible marcar dos grupos de IVA'+
                                      ' como Grupo de IVA por Defecto');
          bError := True;
        end;
        unqrySol.Close;
        FreeAndNil(unqrySol);
      end;
    end;
    if bError then
      Abort
    else
      GetCodigoAutoIvaGrupo;
  end;
end;

procedure TdmIvasGrupos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unstrdprcContador.Connection := oConn;
end;

procedure TdmIvasGrupos.GetCodigoAutoIvaGrupo;
begin
  if unqryTablaG.FindField('GRUPO_ZONA_IVA').AsString = '0' then
  begin
    with unstrdprcContador do
    begin
      Params.Clear;
      Params.CreateParam(ftString, 'ptipodoc', ptInput);
      Params.CreateParam(ftInteger, 'pcont', ptOutput);
      Params.CreateParam(ftInteger, 'pUSUARIO_MODIF', ptInput);
      ParamByName('pUSUARIO_MODIF').AsString := oUser;
      ParamByName('ptipodoc').AsString :=  'IG';
      ExecProc;
      unqryTablaG.FindField('GRUPO_ZONA_IVA').AsString :=
                                                  ParamByName('pcont').AsString;
    end;
  end;
end;

initialization
  ForceReferenceToClass(TdmIvasGrupos);
end.
