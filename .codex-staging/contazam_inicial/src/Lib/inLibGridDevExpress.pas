{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridDevExpress                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       09/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Construcción y configuración común de grids Developer Express.            }
{******************************************************************************}
unit inLibGridDevExpress;

interface

uses
  System.Classes, Data.DB, Vcl.Controls, cxGrid, cxGridDBTableView,
  cxGridLevel;

function CrearGridContazam(
  AOwner: TComponent;
  AParent: TWinControl;
  ADataSource: TDataSource;
  AEditable: Boolean;
  out AVista: TcxGridDBTableView;
  out ANivel: TcxGridLevel): TcxGrid;

procedure AjustarColumnasContazam(AVista: TcxGridDBTableView);
procedure AjustarGridsContazam(AComponente: TComponent);

implementation

uses
  System.SysUtils, System.Math, Vcl.Graphics, cxCustomData, cxFilter,
  cxFindPanel, cxGridCustomTableView;

const
  AnchoMaximoColumna = 520;
  MargenColumna = 14;

type
  TControlAcceso = class(TControl);

procedure AjustarColumnasContazam(AVista: TcxGridDBTableView);
var
  iColumna: Integer;
  iCaracteres: Integer;
  iAncho: Integer;
  oColumna: TcxGridDBColumn;
  oLienzo: TControlCanvas;
  oDataSet: TDataSet;
begin
  if AVista <> nil then
  begin
    oDataSet := AVista.DataController.DataSet;
    if (oDataSet <> nil) and oDataSet.Active and
      (AVista.Control <> nil) and
      AVista.Control.HandleAllocated then
    begin
      AVista.BeginUpdate;
      oLienzo := TControlCanvas.Create;
      try
        oLienzo.Control := AVista.Control;
        oLienzo.Font.Assign(TControlAcceso(AVista.Control).Font);
        AVista.DataController.CreateAllItems(True);
        for iColumna := 0 to AVista.ColumnCount - 1 do
        begin
          oColumna := AVista.Columns[iColumna];
          if oColumna.DataBinding.Field <> nil then
          begin
            oColumna.Caption :=
              oColumna.DataBinding.Field.DisplayLabel;
            if oColumna.DataBinding.Field.DataType in
              [ftBlob, ftGraphic, ftOraBlob] then
            begin
              oColumna.Visible := False;
            end;
            // BestFit seguro: usa título y DisplayWidth sin recorrer filas.
            if oColumna.Visible then
            begin
              iCaracteres := oColumna.DataBinding.Field.DisplayWidth;
              if iCaracteres < 8 then
              begin
                iCaracteres := 8;
              end;
              if iCaracteres > 48 then
              begin
                iCaracteres := 48;
              end;
              iAncho := Max(
                oLienzo.TextWidth(oColumna.Caption),
                oLienzo.TextWidth(StringOfChar('0', iCaracteres)));
              oColumna.Width := iAncho + MargenColumna;
              if oColumna.Width > AnchoMaximoColumna then
              begin
                oColumna.Width := AnchoMaximoColumna;
              end;
            end;
          end;
        end;
      finally
        FreeAndNil(oLienzo);
        AVista.EndUpdate;
      end;
    end;
  end;
end;

procedure AjustarGridsContazam(AComponente: TComponent);
var
  iComponente: Integer;
begin
  if AComponente is TcxGridDBTableView then
  begin
    AjustarColumnasContazam(TcxGridDBTableView(AComponente));
  end;
  for iComponente := 0 to AComponente.ComponentCount - 1 do
  begin
    AjustarGridsContazam(AComponente.Components[iComponente]);
  end;
end;

function CrearGridContazam(
  AOwner: TComponent;
  AParent: TWinControl;
  ADataSource: TDataSource;
  AEditable: Boolean;
  out AVista: TcxGridDBTableView;
  out ANivel: TcxGridLevel): TcxGrid;
begin
  if AOwner = nil then
  begin
    raise EArgumentNilException.Create('AOwner');
  end;
  if AParent = nil then
  begin
    raise EArgumentNilException.Create('AParent');
  end;
  if ADataSource = nil then
  begin
    raise EArgumentNilException.Create('ADataSource');
  end;
  Result := TcxGrid.Create(AOwner);
  Result.Parent := AParent;
  Result.Align := alClient;
  AVista := Result.CreateView(TcxGridDBTableView)
    as TcxGridDBTableView;
  ANivel := Result.Levels.Add;
  ANivel.GridView := AVista;
  AVista.DataController.DataSource := ADataSource;
  AVista.DataController.Options :=
    AVista.DataController.Options + [dcoCaseInsensitive];
  AVista.FilterRow.Visible := True;
  AVista.FilterBox.Visible := fvAlways;
  AVista.FindPanel.DisplayMode := fpdmAlways;
  AVista.FindPanel.Behavior := fcbFilter;
  AVista.FindPanel.Layout := fplCompact;
  AVista.FindPanel.InfoText := 'Buscar en todas las columnas...';
  AVista.FindPanel.ShowCloseButton := False;
  AVista.FindPanel.UseDelayedFind := True;
  AVista.FindPanel.ApplyInputDelay := 350;
  AVista.FindPanel.HighlightSearchResults := True;
  AVista.OptionsBehavior.GoToNextCellOnEnter := True;
  AVista.OptionsBehavior.IncSearch := True;
  AVista.OptionsCustomize.ColumnFiltering := True;
  AVista.OptionsCustomize.ColumnHiding := True;
  AVista.OptionsCustomize.ColumnMoving := True;
  AVista.OptionsCustomize.ColumnSorting := True;
  AVista.OptionsData.Deleting := AEditable;
  AVista.OptionsData.Editing := AEditable;
  AVista.OptionsData.Inserting := AEditable;
  AVista.OptionsSelection.CellSelect := AEditable;
  AVista.OptionsView.ColumnAutoWidth := False;
  AVista.OptionsView.GroupByBox := False;
  AVista.OptionsView.HeaderAutoHeight := True;
  AVista.OptionsView.Indicator := True;
  AVista.OptionsView.NoDataToDisplayInfoText :=
    '<No hay datos que mostrar>';
end;

end.
