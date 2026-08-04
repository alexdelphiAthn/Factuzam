{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalInformesGuias                                       }
{    Tipo:       Formulario (Modal) - hijo de inMtoModalGuiasBase              }
{ Version:       2.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Hijo de TfrmModalGuiasBase para guias de informes FastReport.             }
{    Los campos master se cargan de los TfrxDBDataset del report.              }
{    Formato: UserName.FieldName para identificar dataset y campo.            }
{******************************************************************************}
unit inMtoModalInformesGuias;

interface

uses
  System.SysUtils, System.Classes, Data.DB,
  frxClass, frxDBSet,
  inMtoModalGuiasBase;

type
  TfrmModalInformesGuias = class(TfrmModalGuiasBase)
  protected
    procedure CargarCamposMaster; override;
    function ObtenerClaveInforme: string; override;
    function ObtenerTitulo: string; override;
    function ObtenerInfoCaption: string; override;
    function ObtenerDatasetMaster: string; override;
    function ObtenerFormatoSugerido: string; override;
    function ObtenerCampoMasterSeleccionado: string; override;
  public
    sInforme: string;
    sFormatoSugerido: string;
    FReport: TfrxReport;
  end;

implementation

{$R *.dfm}

procedure TfrmModalInformesGuias.CargarCamposMaster;
var
  i, j: Integer;
  oFrx: TfrxDBDataset;
  oDS: TDataSet;
  sUserName: string;
begin
  lbCamposMaster.Items.Clear;
  if FReport = nil then
  begin
    lbCamposMaster.Items.Add('(Report no disponible)');
  end
  else
  begin
    for i := 0 to FReport.Datasets.Count - 1 do
    begin
      if FReport.Datasets[i].DataSet is TfrxDBDataset then
      begin
        oFrx := TfrxDBDataset(FReport.Datasets[i].DataSet);
        sUserName := oFrx.UserName;
        if sUserName = '' then
          sUserName := '(sin nombre)';
        oDS := oFrx.DataSet;
        if (oDS = nil) or (not oDS.Active) or (oDS.FieldCount = 0) then
          lbCamposMaster.Items.Add(sUserName + '  (sin campos)')
        else
          for j := 0 to oDS.FieldCount - 1 do
            lbCamposMaster.Items.Add(
              sUserName + '.' + oDS.Fields[j].FieldName);
      end;
    end;
  end;
end;

function TfrmModalInformesGuias.ObtenerClaveInforme: string;
begin
  Result := sInforme;
end;

function TfrmModalInformesGuias.ObtenerTitulo: string;
begin
  Result := 'Guías del informe';
end;

function TfrmModalInformesGuias.ObtenerInfoCaption: string;
begin
  if sFormatoSugerido = '' then
    Result := Format('Informe: %s   ·   Formato: (global)', [sInforme])
  else
    Result := Format('Informe: %s   ·   Formato: %s',
      [sInforme, sFormatoSugerido]);
end;

function TfrmModalInformesGuias.ObtenerDatasetMaster: string;
var
  sItem: string;
  iDot: Integer;
begin
  // Extraer el UserName del dataset (parte antes del punto)
  Result := '';
  if lbCamposMaster.ItemIndex >= 0 then
  begin
    sItem := lbCamposMaster.Items[lbCamposMaster.ItemIndex];
    iDot := Pos('.', sItem);
    if iDot > 0 then
      Result := Copy(sItem, 1, iDot - 1);
  end;
end;

function TfrmModalInformesGuias.ObtenerFormatoSugerido: string;
begin
  Result := sFormatoSugerido;
end;

function TfrmModalInformesGuias.ObtenerCampoMasterSeleccionado: string;
var
  sItem: string;
  iDot: Integer;
begin
  // Extraer el nombre del campo (parte despues del punto)
  Result := '';
  if lbCamposMaster.ItemIndex >= 0 then
  begin
    sItem := lbCamposMaster.Items[lbCamposMaster.ItemIndex];
    iDot := Pos('.', sItem);
    if iDot > 0 then
      Result := Copy(sItem, iDot + 1, MaxInt)
    else
      Result := sItem;
  end;
end;

end.
