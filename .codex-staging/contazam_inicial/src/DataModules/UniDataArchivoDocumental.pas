{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArchivoDocumental                                     }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Archivo multiempresa de documentos PDF almacenados dentro de MariaDB.    }
{******************************************************************************}
unit UniDataArchivoDocumental;

interface

uses
  System.Classes, Data.DB, Uni, inLibContadoresIntf;

type
  TdmArchivoDocumental = class(TDataModule)
  private
    FConexion: TUniConnection;
    FEmpresa: string;
    FEjercicio: Integer;
    FDocumentos: TUniQuery;
    FContadores: IContadorDocumentos;
    procedure ComprobarPdf(const ARuta: string);
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string;
      AEjercicio: Integer); reintroduce;
    destructor Destroy; override;
    procedure Abrir;
    procedure Actualizar;
    procedure ImportarPdf(
      const ARuta: string;
      const AReferencia: string;
      const ADescripcion: string);
    procedure GuardarCopiaActual(const ARutaDestino: string);
    function NombreArchivoActual: string;
    property Documentos: TUniQuery read FDocumentos;
  end;

implementation

uses
  System.SysUtils, System.Hash, System.IOUtils,
  UniDataContadoresRepositorio;

constructor TdmArchivoDocumental.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  AEjercicio: Integer);
begin
  if AConexion = nil then
  begin
    raise EArgumentNilException.Create('AConexion');
  end;
  inherited CreateNew(AOwner);
  FConexion := AConexion;
  FEmpresa := AEmpresa;
  FEjercicio := AEjercicio;
  FContadores := CrearRepositorioContadores(FConexion);
  FDocumentos := TUniQuery.Create(Self);
  FDocumentos.Connection := FConexion;
  FDocumentos.ReadOnly := True;
  FDocumentos.SQL.Text :=
    'SELECT ID_DOC, CODIGO_EMP_DOC, EJERCICIO_DOC, REFERENCIA_DOC, ' +
    '       TIPO_DOC, FECHA_DOC, DESCRIPCION_DOC, ' +
    '       NOMBRE_ARCHIVO_DOC, MIME_DOC, TAMANO_DOC, SHA256_DOC, ' +
    '       ORIGEN_DOC, INSTANTE_ALTA, USUARIO_ALTA ' +
    'FROM cza_documentos ' +
    'WHERE CODIGO_EMP_DOC = :EMPRESA AND EJERCICIO_DOC = :EJERCICIO ' +
    'ORDER BY FECHA_DOC DESC, REFERENCIA_DOC';
end;

procedure TdmArchivoDocumental.Abrir;
begin
  FDocumentos.ParamByName('EMPRESA').AsString := FEmpresa;
  FDocumentos.ParamByName('EJERCICIO').AsInteger := FEjercicio;
  FDocumentos.Open;
end;

procedure TdmArchivoDocumental.Actualizar;
var
  iIdDocumento: Int64;
begin
  iIdDocumento := 0;
  if FDocumentos.Active and (not FDocumentos.IsEmpty) then
  begin
    iIdDocumento := FDocumentos.FieldByName('ID_DOC').AsLargeInt;
  end;
  FDocumentos.Close;
  Abrir;
  if iIdDocumento > 0 then
  begin
    FDocumentos.Locate('ID_DOC', iIdDocumento, []);
  end;
end;

procedure TdmArchivoDocumental.ComprobarPdf(const ARuta: string);
var
  oFlujo: TFileStream;
  aCabecera: array[0..4] of AnsiChar;
begin
  if not TFile.Exists(ARuta) then
  begin
    raise EFileNotFoundException.CreateFmt(
      'No existe el archivo %s.',
      [ARuta]);
  end;
  if not SameText(ExtractFileExt(ARuta), '.pdf') then
  begin
    raise EConvertError.Create('Solo se admiten documentos PDF.');
  end;
  oFlujo := TFileStream.Create(ARuta, fmOpenRead or fmShareDenyWrite);
  try
    if (oFlujo.Read(aCabecera, SizeOf(aCabecera)) <
        SizeOf(aCabecera)) or
       (string(aCabecera) <> '%PDF-') then
    begin
      raise EConvertError.Create(
        'El archivo seleccionado no contiene una cabecera PDF válida.');
    end;
  finally
    FreeAndNil(oFlujo);
  end;
end;

destructor TdmArchivoDocumental.Destroy;
begin
  FContadores := nil;
  inherited;
end;

procedure TdmArchivoDocumental.GuardarCopiaActual(
  const ARutaDestino: string);
var
  oConsulta: TUniQuery;
begin
  if FDocumentos.IsEmpty then
  begin
    raise EInvalidOpException.Create('No hay un documento seleccionado.');
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CONTENIDO_PDF_DOC FROM cza_documentos WHERE ID_DOC = :ID';
    oConsulta.ParamByName('ID').AsLargeInt :=
      FDocumentos.FieldByName('ID_DOC').AsLargeInt;
    oConsulta.Open;
    TBlobField(oConsulta.FieldByName('CONTENIDO_PDF_DOC')).SaveToFile(
      ARutaDestino);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmArchivoDocumental.ImportarPdf(
  const ARuta: string;
  const AReferencia: string;
  const ADescripcion: string);
var
  oConsulta: TUniQuery;
  oFlujo: TFileStream;
  iIdDocumento: Int64;
begin
  ComprobarPdf(ARuta);
  if Trim(AReferencia) = '' then
  begin
    raise EArgumentException.Create(
      'La referencia contable del documento es obligatoria.');
  end;
  FConexion.StartTransaction;
  oConsulta := TUniQuery.Create(nil);
  oFlujo := TFileStream.Create(ARuta, fmOpenRead or fmShareDenyWrite);
  try
    try
      iIdDocumento := FContadores.SiguienteNumero(
        'GLOBAL',
        0,
        'ID_DOCUMENTO',
        '-');
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'INSERT INTO cza_documentos (' +
        'ID_DOC, CODIGO_EMP_DOC, EJERCICIO_DOC, REFERENCIA_DOC, ' +
        'TIPO_DOC, FECHA_DOC, DESCRIPCION_DOC, NOMBRE_ARCHIVO_DOC, ' +
        'MIME_DOC, TAMANO_DOC, SHA256_DOC, CONTENIDO_PDF_DOC, ' +
        'ORIGEN_DOC, INSTANTE_ALTA, USUARIO_ALTA) VALUES (' +
        ':ID, :EMPRESA, :EJERCICIO, :REFERENCIA, ''OTRO'', CURDATE(), ' +
        ':DESCRIPCION, :NOMBRE, ''application/pdf'', :TAMANO, ' +
        ':SHA256, :CONTENIDO, ''MANUAL'', NOW(), :USUARIO)';
      oConsulta.ParamByName('ID').AsLargeInt := iIdDocumento;
      oConsulta.ParamByName('EMPRESA').AsString := FEmpresa;
      oConsulta.ParamByName('EJERCICIO').AsInteger := FEjercicio;
      oConsulta.ParamByName('REFERENCIA').AsString := Trim(AReferencia);
      oConsulta.ParamByName('DESCRIPCION').AsString := Trim(ADescripcion);
      oConsulta.ParamByName('NOMBRE').AsString := ExtractFileName(ARuta);
      oConsulta.ParamByName('TAMANO').AsLargeInt := oFlujo.Size;
      oConsulta.ParamByName('SHA256').AsString :=
        UpperCase(THashSHA2.GetHashStringFromFile(ARuta));
      oConsulta.ParamByName('CONTENIDO').DataType := ftBlob;
      oConsulta.ParamByName('CONTENIDO').LoadFromStream(oFlujo, ftBlob);
      oConsulta.ParamByName('USUARIO').AsString :=
        GetEnvironmentVariable('USERNAME');
      oConsulta.ExecSQL;
      FConexion.Commit;
    except
      if FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oFlujo);
    FreeAndNil(oConsulta);
  end;
  Actualizar;
  FDocumentos.Locate('ID_DOC', iIdDocumento, []);
end;

function TdmArchivoDocumental.NombreArchivoActual: string;
begin
  Result := '';
  if FDocumentos.Active and (not FDocumentos.IsEmpty) then
  begin
    Result := FDocumentos.FieldByName('NOMBRE_ARCHIVO_DOC').AsString;
  end;
end;

end.
