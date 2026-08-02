{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGridColumnChooser                                        }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Enriquecimiento de queries de grid con LEFT JOIN de guias runtime         }
{    (fza_informes_guias con prefijo GRID:) y dialogo de seleccion de          }
{    columnas nuevas.                                                          }
{******************************************************************************}
unit inLibGridColumnChooser;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Forms, Data.DB, DBAccess, Uni, inLibInformesGuiasCache,
  inLibLogIntf;

type
  TGridGuiaResult = record
    Exito: Boolean;
    CamposNuevos: TStringList;
    CamposTabla: TStringList;
    ColumnasVisibles: TStringList;
    SqlOriginal: string;
  end;

// Enriquece la query del grid con LEFT JOIN de las guias definidas
// en fza_informes_guias (con prefijo GRID:) para el formulario dado.
function EnriquecerQueryConGuias(
  const ACache: IInformesGuiasCache;
  const AFormName: string;
  AQuery: TUniQuery;
  const ARegistroLog: IRegistroLog): TGridGuiaResult;

// Muestra un dialogo para elegir que columnas nuevas incorporar al grid.
function ElegirColumnasNuevas(AOwner: TForm;
                              ACamposNuevos: TStringList): TStringList;

implementation

uses
  Vcl.CheckLst, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Dialogs,
  inLibMsgComun;

// ============================================================================
// Enriquecimiento de query con LEFT JOIN
// ============================================================================

function SplitFields(const aStr: string): TArray<string>;
var
  sl: TStringList;
  k: Integer;
begin
  sl := TStringList.Create;
  try
    sl.StrictDelimiter := True;
    sl.Delimiter := ';';
    sl.DelimitedText := aStr;
    SetLength(Result, sl.Count);
    for k := 0 to sl.Count - 1 do
      Result[k] := Trim(sl[k]);
  finally
    FreeAndNil(sl);
  end;
end;

function EnriquecerQueryConGuias(
  const ACache: IInformesGuiasCache;
  const AFormName: string;
  AQuery: TUniQuery;
  const ARegistroLog: IRegistroLog): TGridGuiaResult;
var
  arrGuias: TArray<TInformeGuiaItem>;
  iGuia, k, nPares, iSuf: Integer;
  sTabla, sMaster, sDetail: string;
  sSqlActual, sSelectExt, sCol, sAlias, sOn: string;
  arrMaster, arrDetail: TArray<string>;
  setCamposMaster: TStringList;
  qryColsExt, qryTmp: TUniQuery;
begin
  Result.Exito := False;
  Result.CamposNuevos := TStringList.Create;
  Result.CamposTabla := TStringList.Create;
  Result.ColumnasVisibles := TStringList.Create;
  Result.ColumnasVisibles.CaseSensitive := False;
  Result.SqlOriginal := AQuery.SQL.Text;
  if not Assigned(ACache) or (not ACache.Cargada) then
    Exit;
  // Buscamos con prefijo GRID:
  arrGuias := ACache.Obtener('GRID:' + AFormName, '');
  if Length(arrGuias) = 0 then
    Exit;
  qryColsExt := TUniQuery.Create(nil);
  try
    qryColsExt.Connection := AQuery.Connection;
    qryColsExt.SQL.Text :=
      'select COLUMN_NAME from information_schema.COLUMNS ' +
      ' where TABLE_SCHEMA = database() and TABLE_NAME = :TAB ' +
      ' order by ORDINAL_POSITION';
    for iGuia := 0 to High(arrGuias) do
    begin
      sTabla  := arrGuias[iGuia].Tabla;
      sMaster := arrGuias[iGuia].MasterFields;
      sDetail := arrGuias[iGuia].DetailFields;
      if (sTabla = '') or (sMaster = '') or (sDetail = '') then
        Continue;
      try
        sSqlActual := TrimRight(AQuery.SQL.Text);
        while (sSqlActual <> '') and
              (sSqlActual[Length(sSqlActual)] = ';') do
        begin
          SetLength(sSqlActual, Length(sSqlActual) - 1);
          sSqlActual := TrimRight(sSqlActual);
        end;
        if sSqlActual = '' then
          Continue;
        // Inferir campos actuales del master
        setCamposMaster := TStringList.Create;
        setCamposMaster.CaseSensitive := False;
        setCamposMaster.Sorted := True;
        setCamposMaster.Duplicates := dupIgnore;
        try
          qryTmp := TUniQuery.Create(nil);
          try
            qryTmp.Connection := AQuery.Connection;
            qryTmp.SQL.Text :=
              'select * from (' + sSqlActual + ') X_GUIAS where 1=0';
            for k := 0 to qryTmp.Params.Count - 1 do
            begin
              var pSrc := AQuery.Params.FindParam(qryTmp.Params[k].Name);
              if pSrc <> nil then
                qryTmp.Params[k].Value := pSrc.Value
              else
                qryTmp.Params[k].Clear;
            end;
            qryTmp.Open;
            for k := 0 to qryTmp.FieldCount - 1 do
              setCamposMaster.Add(qryTmp.Fields[k].FieldName);
            qryTmp.Close;
          finally
            FreeAndNil(qryTmp);
          end;
          // Columnas de la tabla externa, resolver alias por colision
          sSelectExt := '';
          qryColsExt.Close;
          qryColsExt.ParamByName('TAB').AsString := sTabla;
          qryColsExt.Open;
          while not qryColsExt.Eof do
          begin
            sCol := qryColsExt.FieldByName('COLUMN_NAME').AsString;
            sAlias := sCol;
            if setCamposMaster.IndexOf(sAlias) >= 0 then
            begin
              iSuf := 1;
              while setCamposMaster.IndexOf(sCol + IntToStr(iSuf)) >= 0 do
                Inc(iSuf);
              sAlias := sCol + IntToStr(iSuf);
            end;
            setCamposMaster.Add(sAlias);
            Result.CamposNuevos.Add(sAlias);
            Result.CamposTabla.Add(sAlias + '=' + sTabla);
            if sSelectExt <> '' then
              sSelectExt := sSelectExt + ', ';
            sSelectExt := sSelectExt +
              'EXT_GUIA.' + sCol + ' AS ' + sAlias;
            qryColsExt.Next;
          end;
          qryColsExt.Close;
          // ON clause
          arrMaster := SplitFields(sMaster);
          arrDetail := SplitFields(sDetail);
          nPares := Length(arrMaster);
          if Length(arrDetail) < nPares then
            nPares := Length(arrDetail);
          sOn := '';
          for k := 0 to nPares - 1 do
          begin
            if (Trim(arrMaster[k]) = '') or (Trim(arrDetail[k]) = '') then
              Continue;
            if sOn <> '' then
              sOn := sOn + ' AND ';
            sOn := sOn + 'EXT_GUIA.' + arrDetail[k] +
                   ' = M_GUIA.' + arrMaster[k];
          end;
          if (sOn = '') or (sSelectExt = '') then
            Continue;
          // SQL enriquecido
          AQuery.Close;
          AQuery.SQL.Text :=
            'SELECT M_GUIA.*, ' + sSelectExt + ' ' +
            'FROM (' + sSqlActual + ') M_GUIA ' +
            'LEFT JOIN ' + sTabla + ' EXT_GUIA ON ' + sOn;
          Result.Exito := True;
          // Cargar columnas visibles guardadas en la guía
          if arrGuias[iGuia].ColumnasVisibles <> '' then
          begin
            var arrVis := SplitFields(arrGuias[iGuia].ColumnasVisibles);
            for k := 0 to High(arrVis) do
              if (arrVis[k] <> '') and
                 (Result.ColumnasVisibles.IndexOf(arrVis[k]) < 0) then
                Result.ColumnasVisibles.Add(arrVis[k]);
          end;
        finally
          FreeAndNil(setCamposMaster);
        end;
      except
        on E: Exception do
          if Assigned(ARegistroLog) then
            ARegistroLog.RegistrarError(Format(
              'Guia grid (%s -> %s) fallo: %s',
              [AFormName, sTabla, E.Message]));
      end;
    end;
  finally
    FreeAndNil(qryColsExt);
  end;
end;

// ============================================================================
// Dialogo de seleccion de columnas nuevas
// ============================================================================

function ElegirColumnasNuevas(AOwner: TForm;
                              ACamposNuevos: TStringList): TStringList;
var
  frm: TForm;
  clb: TCheckListBox;
  pnl: TPanel;
  btnOK, btnCancel: TButton;
  i: Integer;
begin
  Result := TStringList.Create;
  if (ACamposNuevos = nil) or (ACamposNuevos.Count = 0) then
    Exit;
  frm := TForm.Create(AOwner);
  try
    frm.Caption := STituloSeleccionarColumnas;
    frm.Width := 420;
    frm.Height := 460;
    frm.Position := poMainFormCenter;
    frm.BorderStyle := bsDialog;
    pnl := TPanel.Create(frm);
    pnl.Parent := frm;
    pnl.Align := alBottom;
    pnl.Height := 45;
    pnl.BevelOuter := bvNone;
    clb := TCheckListBox.Create(frm);
    clb.Parent := frm;
    clb.Align := alClient;
    clb.Font.Name := 'Consolas';
    clb.Font.Size := 10;
    for i := 0 to ACamposNuevos.Count - 1 do
      clb.Items.Add(ACamposNuevos[i]);
    btnOK := TButton.Create(pnl);
    btnOK.Parent := pnl;
    btnOK.Caption := SCaptionAceptar;
    btnOK.ModalResult := mrOk;
    btnOK.Left := 160;
    btnOK.Top := 8;
    btnOK.Width := 120;
    btnOK.Height := 30;
    btnCancel := TButton.Create(pnl);
    btnCancel.Parent := pnl;
    btnCancel.Caption := SCaptionCancelar;
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := 290;
    btnCancel.Top := 8;
    btnCancel.Width := 120;
    btnCancel.Height := 30;
    if frm.ShowModal = mrOk then
    begin
      for i := 0 to clb.Count - 1 do
        if clb.Checked[i] then
          Result.Add(clb.Items[i]);
    end;
  finally
    FreeAndNil(frm);
  end;
end;

end.
